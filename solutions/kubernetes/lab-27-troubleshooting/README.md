# Solution for Lab 27: Debugging a Broken Cluster with k9s

This walkthrough gives the exact keystrokes, the evidence, and the fix for each of the lab's eight
scenarios, in the lab's own part numbering.

## Setup

```bash
k9s version
export K9S_EDITOR=nano       # PowerShell: $env:K9S_EDITOR = "notepad"
kubectl create namespace shop
kubectl apply -n shop -f setup.yaml   # from labs/kubernetes/lab-27-troubleshooting/
k9s -n shop
```

Confirm the editor before touching anything else: `:pods` `Enter`, highlight any pod, `e`. If nothing
opens, quit with `:q`, fix `$K9S_EDITOR` in the shell, and relaunch.

## Part 1: The triage loop

No fix here — the pods table is the dispatcher. `STATUS` names which record-keeper has the answer:
`Pending` sends you to the scheduler's events, a stuck `ContainerCreating` or `ImagePullBackOff` to the
kubelet's events, `CrashLoopBackOff` to the container's own logs, and a healthy-looking `Running` that is
still wrong to the Service's endpoints. Parts 2–9 are that loop run eight times.

## Part 2: `cache`

- **Keystrokes:** `:pods` `Enter`, `/cache` `Enter`, `l` (empty — `Waiting for logs...`), `Esc`, `d`, `G`.
- **Evidence:** `Warning  Failed  7s (x10 over 96s)  kubelet  spec.containers{cache}: Error: couldn't
  find key passwd in Secret shop/cache-auth`. Confirmed on the Secret side: `:secret` `Enter`, highlight
  `cache-auth`, `d` — `Data` lists `password:  6 bytes`, no `passwd`.
- **Root cause:** the Deployment's `secretKeyRef` names a key the Secret does not have, so the kubelet
  can never assemble the container's environment and no process ever starts.
- **Fix:** `:deploy` `Enter`, `/cache` `Enter`, `e` on `cache` — `spec.template.spec.containers[0].env[0]
  .valueFrom.secretKeyRef.key` from `passwd` to `password`.
- **Answer:** no logs at all, not empty ones, means the container never ran — the kubelet failed to
  build it before any process could produce output.

## Part 3: `sessions`

- **Keystrokes:** `:pods` `Enter`, `/sessions` `Enter`, `l`.
- **Evidence:** `FATAL: REDIS_HOST not set` / `stream closed: EOF for shop/sessions-...`.
- **Root cause:** the container reads `$REDIS_HOST` on startup and exits 1 if it is unset; nothing in
  the Deployment ever sets it.
- **Fix:** `:deploy` `Enter`, `/sessions` `Enter`, `e` on `sessions` — add
  `spec.template.spec.containers[0].env`: `- name: REDIS_HOST` / `value: cache`, placed directly above
  `image: busybox:1.37` at the container's indentation.
- **Answer:** `l` already streams the current attempt, which for a crashlooper is the run that just
  died — the same answer `p` (Logs Previous) would give here, and `p` may instead report the container
  gone if the kubelet has already reaped it. `l` is the right key for a crashlooper; `p` earns its place
  when the *current* container is fine and the question is about its predecessor.

## Part 4: `reports`

- **Keystrokes:** `:pods` `Enter`, `/reports` `Enter` (`IP`/`NODE` both `n/a`), `d`.
- **Evidence:** `Warning  FailedScheduling  7m18s  default-scheduler  0/1 nodes are available: 1
  Insufficient memory.`, with `Requests: memory: 64Gi` above it.
- **Root cause:** the Deployment requests 64**Gi** of memory instead of the intended 64**Mi**; the
  scheduler works from `requests`, not actual usage, and no node has 64Gi free.
- **Fix:** `:deploy` `Enter`, `e` on `reports` — both `resources.requests.memory` and
  `resources.limits.memory` from `64Gi` to `64Mi`.
- **Answer:** the scheduler complains about what the pod *asks for* (`requests`), never what it uses; a
  pod that has not started yet has no usage to be short of.

## Part 5: `crunch`

- **Keystrokes:** `:pods` `Enter`, `/crunch` `Enter` (status cycling `OOMKilled` / `CrashLoopBackOff` /
  `Running`), `l`, `Esc`, `d`.
- **Evidence:** logs end `building report cache` / `Killed` / `stream closed: EOF for shop/crunch-...`;
  describe shows `Last State: Terminated`, `Reason: OOMKilled`, `Exit Code: 137`, with `Limits: memory:
  64Mi` and `Requests: memory: 32Mi` above it.
- **Root cause:** the container allocates a 100Mi buffer against a 64Mi memory **limit**, so the kernel
  kills it every time; the buffer is process memory, not a volume, so each restart repeats the same
  clean kill rather than drifting into a different failure.
- **Fix:** `:deploy` `Enter`, `e` on `crunch` — `resources.limits.memory` from `64Mi` to `256Mi` and
  `resources.requests.memory` from `32Mi` to `128Mi` (raise the request alongside the limit, or the
  scheduler keeps placing the pod on nodes too small to hold it).
- **Answer:** the **limit** killed it. The request is only a scheduling reservation; the limit is the
  ceiling the kernel enforces, and 100Mi exceeds it.

## Part 6: `orders`

- **Keystrokes:** `:pods` `Enter`, `/orders` `Enter` (`Running`, `0/1`), `:ep` `Enter` (`orders  <none>`),
  `:pods` `Enter`, `d`.
- **Evidence:** `Readiness: http-get http://:80/healthz ...` and `Warning  Unhealthy  4m10s (x63 over
  9m12s)  kubelet  spec.containers{nginx}: Readiness probe failed: HTTP probe failed with statuscode:
  404`.
- **Root cause:** the readiness probe asks for `/healthz`, which nginx does not serve, so it answers 404
  on every check; a pod that fails readiness stays `Running` but is pulled out of its Service.
- **Fix:** `:deploy` `Enter`, `e` on `orders` — `readinessProbe.httpGet.path` from `/healthz` to `/`.
- **Answer:** the kubelet decided, by running the readiness probe on a five-second period and asking for
  `/healthz` — a path the image was never built to answer.

## Part 7: `catalog`

- **Keystrokes:** `:ep` `Enter` (`catalog  <none>`, but `:deploy` shows `catalog 2/2` and `:pods` shows
  both `1/1 Running`), `:svc` `Enter`, highlight `catalog`, `y` (`spec.selector`), then `:pods`, `d` on a
  `catalog` pod (`Labels`).
- **Evidence:** the Service's `spec.selector` reads `app: catalogue`; the pods carry `app: catalog`. No
  event names this — a selector that matches nothing is not an error Kubernetes warns about.
- **Root cause:** the Service selector and the pod labels disagree by one letter, so the Service
  collects zero pods even though both are otherwise healthy.
- **Fix:** `:svc` `Enter`, `e` on `catalog` — `spec.selector.app` from `catalogue` to `catalog` (the
  Service is the side to change; relabelling running pods would detach them from their ReplicaSet).
- **Answer:** a Service does not know about Deployments — it collects pods by label selector, continuously,
  and matches by comparing that selector against every pod's labels.

## Part 8: `auditor`

- **Keystrokes:** `:pods` `Enter`, `/auditor` `Enter` (`1/1 Running`, `0` restarts), `d` (all `Normal`
  events), `Esc`, `l`.
- **Evidence:** `Error from server (Forbidden): pods is forbidden: User
  "system:serviceaccount:shop:auditor" cannot list resource "pods" in API group "" in the namespace
  "shop"`. Confirmed from inside the pod: `s`, then `kubectl auth can-i list pods` answers `no`.
- **Root cause:** the Role grants `get`/`list` on `configmaps`, not `pods`, so every 30-second loop is
  refused by the API server — a successful HTTP round trip that Kubernetes has no reason to warn about.
- **Fix:** `:role` `Enter`, `e` on `auditor` — add `pods` to the rule's `resources` list, from
  `["configmaps"]` to `["configmaps", "pods"]`, same `get`/`list` verbs.
- **Answer:** an application's own complaint, when Kubernetes itself sees nothing wrong, ends up in the
  container's logs — `l`, not `d`.

The payoff: watch `RESTARTS` while waiting for the next 30-second loop. It stays `0` and the pod name
never changes — RBAC is evaluated per request, not baked into the pod at startup, so widening the Role
takes effect on the very next API call with no rollout.

## Part 9 (bonus): `archive`

- **Keystrokes:** `:pods` `Enter`, `/archive` `Enter` (`Pending`), `d`.
- **Evidence:** `Warning  FailedScheduling  28s (x3 over 11m)  default-scheduler  0/1 nodes are
  available: pod has unbound immediate PersistentVolumeClaims.` (the cluster appends its own tail after
  that sentence — ignore it, the load-bearing fragment is `unbound immediate PersistentVolumeClaims`).
  The `Volumes` section of the same describe names `ClaimName: archive-data-v2`. `:pvc` `Enter` shows
  `archive-data` `Bound` and `archive-data-v2` `Pending`; `d` on `archive-data-v2` gives `Warning
  ProvisioningFailed  ...  storageclass.storage.k8s.io "fast-ssd" not found`. `:sc` `Enter` lists only
  `standard (default)`.
- **Root cause:** the Deployment mounts `archive-data-v2`, a claim pinned to a `fast-ssd` StorageClass
  the cluster does not have; the claim never binds and the provisioning controller retries forever, so
  the pod never gets past scheduling. The healthy `archive-data` claim, already `Bound`, is the clue that
  `-v2` was an abandoned migration attempt.
- **Fix:** `:deploy` `Enter`, `e` on `archive` — `spec.template.spec.volumes[0].persistentVolumeClaim
  .claimName` from `archive-data-v2` to `archive-data`.
- **Answer:** it is waiting for a PersistentVolumeClaim to bind, not for memory — the second `Pending` in
  this lab, and a different scheduler complaint from `reports`' `Insufficient memory` in Part 4.

`archive-data`'s own status depends on the cluster's default StorageClass. Immediate binding (minikube's
`k8s.io/minikube-hostpath`) shows it `Bound` from the start; `WaitForFirstConsumer` binding (kind's
`rancher.io/local-path`) leaves it `Pending` alongside `archive-data-v2` until a pod actually uses it. Two
`Pending` claims do not mean two faults — `d` on the claim tells them apart: `waiting for first consumer
to be created before binding` is healthy, `ProvisioningFailed` is not.

## Part 10: Cleanup

`:ns` `Enter`, `/shop` `Enter`, highlight `shop`, `Ctrl-D`, `Tab` to move off `Cancel` onto `OK`, `Enter`.
The namespace goes `Terminating` and takes every object in it with it. `:q` to quit.

## Instructor notes

Unlike lab 26, this lab's manifests are covered by automated tests. `tests/lab-27-broken` applies
`setup.yaml` and asserts that each of the eight scenarios stays broken for its own specific reason, not
just "not ready" — a scenario that failed for the wrong cause (a pulled image tag disappearing, say)
would still fail that assertion. `tests/sol-27-fixed` applies `fixed.yaml` and asserts the whole stack
comes up: all eight Deployments available, both `orders` and `catalog` with endpoints, and the `auditor`
ServiceAccount actually allowed to list pods.

To reset between students, delete the namespace and start the lab's Part 0 again:

```bash
kubectl delete namespace shop
kubectl create namespace shop
kubectl apply -n shop -f setup.yaml
```

To demonstrate the finished state quickly instead of walking every part again, apply `fixed.yaml` over a
half-repaired namespace — it is idempotent and brings every workload the rest of the way up in one
`kubectl apply`.

A student stuck at `e` almost always has `$K9S_EDITOR` unset or pointing at something that cannot run
in their terminal (a GUI editor with no `-w`/wait flag, for instance). This lab has no `kubectl set
image` fallback by design, unlike lab 26 — fixing the variable is the only way forward.

Three runtime quirks surfaced during development, all specific to the cluster under the student's feet
rather than to the lab's manifests:

`crunch` (Part 5) needs the container's entrypoint to be `sh -e -c`, not plain `sh -c`, to die reliably
on every cluster. minikube's cgroups have `memory.oom.group = 0`, so the kernel kills only the offending
`dd` process and the shell survives to run `sleep 3600` — the pod sits at `1/1 Running` with `RESTARTS
0` and the scenario never manifests. kind sets `memory.oom.group = 1`, so the whole cgroup dies and `-e`
is inert there. `setup.yaml` carries a comment on this exact line; read it before telling a student their
cluster is broken.

`archive`'s good claim, `archive-data` (Part 9), is `Bound` immediately on minikube but `Pending` on
kind, because the two clusters' default StorageClasses use different volume-binding modes. On kind a
student sees two `Pending` PVCs and has to read the events to find the one that is actually broken. The
`archive` pod's own `FailedScheduling` message also ends differently across Kubernetes versions — the
lab's quoted text stops at the stable fragment, `unbound immediate PersistentVolumeClaims`, for exactly
this reason.

`reports` (Part 4) depends on the node having less than roughly 64 GiB allocatable memory; above that
threshold the 64Gi request schedules and the scenario is void. The kind node used during development
measured about 7.8 GiB allocatable, comfortably under the threshold.
