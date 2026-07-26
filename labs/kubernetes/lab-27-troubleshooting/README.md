# Lab 27: Debugging a Broken Cluster with k9s

Lab 26 handed you the navigation (`:pods`, `d`, `y`, `l`, `s`, `e`) and one broken Deployment whose
image tag did not exist. Real clusters often have more complicated issues. Here a colleague
deployed a webshop yesterday and left for two weeks. Eight of its workloads are broken, each for a
different reason, and none of them volunteers what it needs until you ask the right resource. You
repair all eight without leaving k9s, and by the end the `STATUS` column alone tells you which key to
press next.

> **Shells:** k9s is a terminal UI, so every keystroke below is identical on Windows, macOS, and Linux.
> Only two `kubectl` commands and one environment variable run in your own shell; where PowerShell
> differs from Bash, both variants are shown. Commands you type inside a container after pressing `s`
> run on Linux and have no Windows variant.

---

## Part 0: Setup

k9s is already installed. Check it, and start from a running minikube cluster:

```bash
k9s version
```

k9s can edit, scale and delete things that already exist, but it cannot create a resource from a file.
So the broken webshop has to be applied from your shell first. Save [setup.yaml](setup.yaml) and run
this from the directory you saved it in:

```bash
kubectl create namespace shop
kubectl apply -n shop -f setup.yaml
```

Both commands are the same in Bash and PowerShell, and they are the **last `kubectl` commands in this
lab**. Every change from here on is made inside k9s.

> Do not open `setup.yaml`. Its comments name every fault by hand, and the whole exercise is finding
> them in the cluster instead.

---

## Part 1: Triage

Look at the pods table. You will see ten pods, and the `STATUS` column already shows five different words, or six
if you catch a crashlooping pod mid-restart.

`STATUS` is not a diagnosis, it only hints towards an issue. It tells you *how far the pod got* before something
stopped it, and that in turn tells you which of the cluster's three record-keepers wrote down the
reason: the **scheduler** (never placed it), the **kubelet** (placed it, could not run it), or the
**application itself** (ran, then complained in its own logs).

| Status | What it means | Where to look next |
| --- | --- | --- |
| `Pending` | Never got a node | `d` → Events → `FailedScheduling` |
| `ContainerCreating` (stuck) | Scheduled, but the kubelet cannot start it | `d` → Events → volumes, ConfigMaps |
| `ImagePullBackOff`, `CreateContainerConfigError` | Never started, so no logs exist | `d` → Events |
| `CrashLoopBackOff`, restarts climbing | Started, then died | `l`, then `p` for the previous one; `d` → `Last State` |
| `Running` but `0/1` | Alive, but the readiness probe says no | `y` → probe config; `d` → Events |
| `Running 1/1`, still wrong | Kubernetes is happy, the app is not | `l`, then the Service's endpoints |

The next exercises all follow the same pattern:
Check the status of each workload (`d` for events, `l` for logs), open the resource's own YAML to see the offending
field, fix it with `e`, then watch the table until the workload recovers.

---

## Part 2: `cache` – "the cache never came up"

Start with the report that sounds simplest. In the pods view, press `/`, type `cache`, and press
`Enter`. One pod remains:

```text
cache-f798975d6-d9fzc   0/1   CreateContainerConfigError   0
```

The obvious first move is to read the logs, so make it. Press `l`. k9s shows:

```text
Waiting for logs...
```

but nothing ever arrives. There is no log stream to attach to.

> **Stop and think:** The pod produces no output at all, and there is no stream to read. What has to
> have happened for a container to reach that state?

Press `Esc` to leave the log view, then `d` to describe the pod, and `G` to jump to the bottom where
the Events live:

```text
Warning  Failed  7s (x10 over 96s)  kubelet  spec.containers{cache}: Error: couldn't find key passwd in Secret shop/cache-auth
```

The kubelet is assembling the container's environment from a Secret and cannot find the key it was
told to read. That happens *before* any process starts, which is why there is nothing to log.

Scroll up a little in the same describe output and you can see the request that failed:

```text
Environment:
  CACHE_PASSWORD:  <set to the key 'passwd' in secret 'cache-auth'>  Optional: false
```

So the Deployment wants a key called `passwd`. Does the Secret have one? Press `Esc`, type `:secret`
and `Enter`, highlight `cache-auth`, and press `d`. The `Data` section lists the key names (not the
values):

```text
Data
====
password:  6 bytes
```

`password`, not `passwd`. The Deployment asks for a key that was never there.

**Fix it.** The env block lives in the pod template, so edit the Deployment rather than the pod: a pod
you edit is thrown away on the next rollout. Type `:deploy` `Enter`, filter with `/cache` `Enter`,
highlight `cache`, and press `e`. Find:

```yaml
              key: passwd
```

change it to `key: password`, save, and close the editor.

Watch the deployments table: `READY` flips from `0/1` to `1/1` within a few seconds. Switch back to
`:pods` and the new `cache-...` pod is `1/1 Running`.

---

## Part 3: `sessions` – "it keeps restarting"

Go to `:pods` and filter with `/sessions`. This pod did get further than `cache` did:

```text
sessions-86cccd74dd-mbdhz   0/1   CrashLoopBackOff   5
```

`RESTARTS` is climbing, and the status alternates between `Error` and `CrashLoopBackOff` as the kubelet
waits longer and longer between attempts. Something started and then died, repeatedly, so this time
there *is* an application to ask. Press `l`:

```text
FATAL: REDIS_HOST not set
stream closed: EOF for shop/sessions-86cccd74dd-mbdhz (sessions)
```

> **Stop and think:** This container has run several times. When you press `l`, whose output are you
> reading: the run that just died, or the one before it?

`l` streams the container that is running *now*. For a crashlooping pod that is the most recent
attempt, or the one that just ended, as here. In this case, plain `l` already shows the issue. Press `Esc`
to go back to the pods table and press `p` for **Logs Previous** anyway, to see what it does: the title
bar changes to `Previous Logs(...)`, and you get either the same line from the run before the latest
one, or:

```text
unable to retrieve container logs for docker://61d85899431f1ba9050bfcc0df9bd0301b6eda3f65dc1dc36fd1b85f
```

The kubelet only keeps a handful of dead containers per pod before reaping them, so on a pod that has
restarted many times the earlier run may be gone. Either way, `l` is how you read a crashlooping pod. `p`
belongs to the opposite situation: the current container is running fine and you need to know why its
predecessor died.

**Fix it.** The container refuses to run without `REDIS_HOST` and never checks what is in it, so give
it the name of the workload it is meant to reach: `cache`, the one you repaired in Part 2. Go to
`:deploy`, filter `/sessions`, press `e`, and add an `env` block to the container. In the live YAML the
container's keys are sorted alphabetically, so put it directly above the `image: busybox:1.37` line, at
the same indentation:

```yaml
        env:
        - name: REDIS_HOST
          value: cache
```

Save and close. Back in `:pods`, a new `sessions-...` pod appears, `RESTARTS` sits at `0`, and `l` now
reads:

```text
sessions connected to cache
```

---

## Part 4: `reports` – "nothing happens at all"

The colleague is right that nothing happens. Filter `:pods` for `reports`:

```text
reports-dd8498ffb-xnhg9   0/1   Pending   0
```

`Pending`, no restarts, no container. Look further right along the row: the `IP` and `NODE` columns
both read `n/a`. This pod was never given a machine to run on, so the kubelet has never heard of it and
there is nothing to log. Only the scheduler has an opinion here.

> **Stop and think:** The scheduler rejected this pod. Which is it complaining about: what the pod
> *asks for*, or what it *uses*?

Press `d` and read the Events:

```text
Warning  FailedScheduling  7m18s  default-scheduler  0/1 nodes are available: 1 Insufficient memory.
```

The scheduler appends its own reasoning after that sentence: a preemption clause about whether evicting
another pod would make room, and on newer Kubernetes a note about resource claims. None of it changes
the diagnosis. `Insufficient memory` is the part that matters.

A pod that uses nothing yet cannot be short of memory. The scheduler works purely from `requests`, the
reservation the pod demands up front, and no node had that much free. Scroll up in the same output to
see the number:

```text
Requests:
  cpu:        10m
  memory:     64Gi
```

64 **Gi**, on a single-node minikube. Someone typed the wrong unit.

**Fix it** in `:deploy` with `e`: change both the request and the limit from `64Gi` to `64Mi`. Leaving
a 64Gi limit next to a 64Mi request would schedule fine but is nonsense to read six months from now.
The pod lands on the node and goes `1/1 Running`.

---

## Part 5: `crunch` – "it dies every few minutes"

Filter `:pods` for `crunch` and watch it for half a minute. The status flips between `OOMKilled`,
`CrashLoopBackOff` and `Running`, and `RESTARTS` climbs steadily. Unlike `sessions`, this container
works for a moment before it disappears.

Press `l`:

```text
building report cache
Killed
stream closed: EOF for shop/crunch-58cd488899-kwzhx (crunch)
```

It never reports the cache as built. `Killed` is the shell noticing that something outside the job
ended it, leaving no stack trace and no message of its own. The application is silent, so the
complaint must be someone else's. Press `Esc`, then `d`:

```text
State:          Waiting
  Reason:       CrashLoopBackOff
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

`Last State` is where a crashlooping container's cause of death is recorded. The current state only
tells you the kubelet is waiting before the next attempt. `OOMKilled` with exit code `137` means the
kernel killed the process for exceeding its memory allowance.

> **Stop and think:** The code is fine; the job asks for more memory than it was allowed. Two numbers
> govern that. Which one killed it, the request or the limit?

Scroll up in the same output to the resources block and read both numbers before you answer:

```text
Limits:
  cpu:     100m
  memory:  64Mi
Requests:
  cpu:        10m
  memory:     32Mi
```

**Fix it.** The `request` is only a scheduling reservation; the `limit` is the ceiling the kernel
enforces, and that is what was breached. In `:deploy`, press `e` on `crunch` and raise it:

```yaml
          limits:
            cpu: 100m
            memory: 256Mi
          requests:
            cpu: 10m
            memory: 128Mi
```

Raise the request alongside it, or the scheduler will keep placing this pod on nodes too small to hold
it. Back in `:pods`, the new pod reaches `1/1 Running` and `RESTARTS` stays at `0`. Watch it for a full
minute to be sure the count has gone quiet.

---

## Part 6: `orders` – "checkout is down"

Filter `:pods` for `orders`. Nothing here is red:

```text
orders-cc9b7d96c-dt6jb   0/1   Running   0
orders-cc9b7d96c-v2bx2   0/1   Running   0
```

`Running`, zero restarts, and `0/1`. The container is alive; something else decided it is not fit to
serve. Confirm the consequence first: type `:ep` `Enter` for the endpoints view.

```text
catalog   <none>
orders    <none>
```

An endpoint is an address a Service forwards traffic to. `orders` has none, so every request to the
Service fails even though two nginx processes are running.

> **Stop and think:** The containers are running and nginx is serving. So who decided these pods are
> not ready, and what did it ask them?

Go back to `:pods`, press `d` on an `orders` pod, and read both the probe definition and the Events:

```text
Readiness:    http-get http://:80/healthz delay=3s timeout=1s period=5s #success=1 #failure=3
```

```text
Warning  Unhealthy  4m10s (x63 over 9m12s)  kubelet  spec.containers{nginx}: Readiness probe failed: HTTP probe failed with statuscode: 404
```

The kubelet is asking for `/healthz` every five seconds and nginx is answering `404` every time,
because the path does not exist in the image. A pod that fails its readiness probe stays `Running` but
is pulled out of its Service, which is the symptom the colleague reported.

**Fix it.** Either the image needs a `/healthz` handler or the probe needs to ask for something that
exists. You cannot rebuild the image from k9s, so change the probe: `:deploy`, `e` on `orders`, and set
the readiness `path` to `/`.

Return to `:ep` and watch the row fill in:

```text
orders   10.244.0.59:80,10.244.0.60:80
```

---

## Part 7: `catalog` – "the product list is empty"

The issue sounds similar to `orders`, so check the same place first. In `:ep`, `catalog` still reads
`<none>`. But this time the pods are not the problem: `:deploy` shows `catalog 2/2`, and `:pods`
shows both pods `1/1 Running`. Ready pods, and still no endpoints.

The two scenarios differ by a layer. `orders` had an empty Service because its pods were not ready;
`catalog`'s pods are ready and the Service still cannot see them. Same symptom, one layer apart.

> **Stop and think:** The pods are `1/1 Running` and the Service exists. So what decides which pods a
> Service sends traffic to?

Remember: A Service does not know about Deployments. It collects pods by **label selector**, a filter it runs
continuously over every pod in the namespace. A filter that matches nothing leaves the Service empty
rather than broken, and Kubernetes has nothing to warn you about. That is why `d` on the Service shows
no useful events here.

Compare the two sides yourself. Type `:svc` `Enter`, highlight `catalog`, press `y`, and read
`spec.selector`. Then go to `:pods`, press `d` on a `catalog` pod, and read its `Labels`.

**Fix it.** Whichever side is wrong, the Service is the side you can safely change: relabelling running
pods would detach them from their ReplicaSet. In `:svc`, press `e` on `catalog` and correct the
selector to match the pods' label. Back in `:ep`:

```text
catalog   10.244.0.49:80,10.244.0.53:80
```

---

## Part 8: `auditor` – "the report is empty, but the pod looks green"

Filter `:pods` for `auditor`:

```text
auditor-94bbc9c45-s4sp2   1/1   Running   0
```

Ready, zero restarts. Press `d` and read the Events: `Scheduled`, `Pulled`, `Created`, `Started`, every
one of them `Normal`. Kubernetes has nothing to report because, from its point of view, nothing went
wrong.

> **Stop and think:** Every column is green and there are no events. Where does an application's own
> complaint end up, if Kubernetes has nothing to complain about?

Press `Esc`, then `l`:

```text
--- pod inventory ---
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:shop:auditor" cannot list resource "pods" in API group "" in the namespace "shop"
```

Every 30 seconds the job asks the API server for a pod list and is refused. The refusal is a successful
HTTP round trip, so nothing about the pod is unhealthy. The container keeps running and the report it
writes comes out empty.

Read the message closely: it names the identity that was refused, `system:serviceaccount:shop:auditor`,
and the exact verb and resource, `list` on `pods`. Confirm it from the inside: press `Esc`, then `s` to
open a shell in the container, and ask on its behalf:

```sh
kubectl auth can-i list pods
```

```text
no
```

Type `exit` to return to k9s.

**Fix it.** A ServiceAccount can do only what a Role grants it. Type `:role` `Enter`, highlight
`auditor`, and press `e`. The rule reads:

```yaml
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
  - list
```

It grants `get` and `list` on ConfigMaps: the right verbs on the wrong resource. Add `pods` to the
`resources` list:

```yaml
  resources:
  - configmaps
  - pods
```

Save and close, then press `l` on the `auditor` pod and wait for the next loop.

The result should be: **no pod restarts, and none is needed.** Watch the `RESTARTS` column. It
stays at `0`, and the pod name never changes. The next `kubectl get pods` inside the container
succeeds:

```text
--- pod inventory ---
NAME                        READY   STATUS    RESTARTS   AGE
archive-69bc686487-ljxqs    0/1     Pending   0          15m
auditor-94bbc9c45-s4sp2     1/1     Running   0          15m
cache-847c7c5889-n8t2c      1/1     Running   0          12m
...
```

The API server evaluates permissions on every request, so widening a Role takes effect on the very next
call. That is why an RBAC problem never shows up as a restart.

---

## Part 9 (bonus): `archive` – "it is stuck deploying"

One workload left. Filter `:pods` for `archive`:

```text
archive-69bc686487-ljxqs   0/1   Pending   0
```

`Pending` again, the same word you saw in Part 4, and the temptation is to go straight back to the
resource requests.

> **Stop and think:** This is the second `Pending` pod in this lab. Read the message before you reach
> for the resource requests. What is it waiting for this time?

Press `d`:

```text
Warning  FailedScheduling  28s (x3 over 11m)  default-scheduler  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims.
```

Your cluster appends something of its own after that sentence: a dangling `not found` on newer
Kubernetes, a note about preemption on older ones. Ignore it. The part that matters is `unbound
immediate PersistentVolumeClaims`.

Same status, entirely different cause. `reports` was rejected over a number in its own spec; `archive`
is rejected because a resource it depends on is not usable yet. The scheduler will not place a pod that
mounts a volume until that volume exists, so it never gets as far as looking at memory.

The message names the culprit type but not which claim. Scroll up in the same describe output to the
`Volumes` section:

```text
Volumes:
  data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  archive-data-v2
```

Now look at the claims themselves: type `:pvc` `Enter`.

```text
archive-data      Bound     pvc-edf6a63b-...   1Gi   RWO   standard
archive-data-v2   Pending                                  fast-ssd
```

Two claims, and only one of them is a fault. Press `d` on `archive-data-v2`:

```text
Warning  ProvisioningFailed  18m (x62 over 33m)  persistentvolume-controller  storageclass.storage.k8s.io "fast-ssd" not found
```

A StorageClass is the cluster's recipe for making a volume: who provisions it, on what kind of disk.
This claim asks for one called `fast-ssd`. Type `:sc` `Enter` to see what the cluster offers:

```text
standard (default)   k8s.io/minikube-hostpath   Delete   Immediate
```

One class, named `standard`. Nothing will ever satisfy `archive-data-v2`, and nothing ever times out
either. The controller retries forever, which is why the deployment looks "stuck" rather than failed.

> Depending on your cluster's default StorageClass, `archive-data` may also show `Pending` rather than
> `Bound`. Press `d` on it: if the event reads `waiting for first consumer to be created before
> binding`, the claim is healthy and holding off until a pod uses it. Two `Pending` claims do not mean
> two broken claims; the events tell them apart.

**Fix it.** You cannot change a bound claim's StorageClass, and creating a replacement claim is not
something k9s can do. The healthy `archive-data` claim is already there, which is the clue that the
`-v2` claim was a migration attempt someone abandoned. In `:deploy`, press `e` on `archive` and point
the volume back:

```yaml
        persistentVolumeClaim:
          claimName: archive-data
```

The pod schedules immediately and goes `1/1 Running`. `archive-data-v2` stays `Pending` in the `:pvc`
list. Nothing uses it now, so it does no harm.

**Task:** Go to `:deploy` one last time. All eight Deployments should read `READY` at their full
replica count, and `:ep` should show addresses for both `orders` and `catalog`.

---

## Part 10: Cleanup

Everything in this lab lives in one namespace, and a namespace owns the objects inside it. Deleting it
deletes the Deployments, Services, Secret, ServiceAccount, Role, RoleBinding and PersistentVolumeClaims
in one step, so there is nothing else to clean up.

Type `:ns` `Enter`, filter with `/shop` `Enter`, highlight `shop`, and press `Ctrl-D`. A confirmation
dialog appears:

```text
Delete namespaces -/shop?
Propagation: Background
Force:
              Cancel     OK
```

`Cancel` is selected by default, so pressing `Enter` closes the dialog without deleting anything. Press
`Tab` to move to `OK`, then `Enter`. The namespace goes `Terminating` and disappears.

Quit k9s with `:q`.

---

## Summary: key k9s bindings used in this lab

| Key | Action |
| ------ | ----- |
| `:` then `<resource>` | Jump to `:pods`, `:deploy`, `:svc`, `:secret`, `:role`, `:ep`, `:pvc`, `:sc`, `:ns` |
| `/` | Filter the current table |
| `Esc` | Go back / clear filter |
| `d` | Describe, with Events at the bottom |
| `y` | Show full YAML |
| `G` | Jump to the bottom of a describe or log view |
| `l` | Stream logs of the current container |
| `p` | Logs of the *previous* container |
| `s` | Shell into a pod |
| `e` | Edit in `$K9S_EDITOR` |
| `Ctrl-D` | Delete the highlighted resource |
| `Tab` | Move between fields and buttons in a dialog |
| `:q` `Enter` | Quit k9s |

---

## Further resources

- [k9s documentation](https://k9scli.io/)
- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Determine the Reason for Pod Failure](https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/)
