# Lab 25: Navigating & Troubleshooting Kubernetes with k9s

[k9s](https://k9scli.io/) is a terminal UI for Kubernetes. It shows your cluster resources in a live
table you navigate with the keyboard, so instead of running a separate `kubectl get`, `describe`, or
`logs` for every question, you move between resources and read their details in one place.

**Goal of this exercise:** By the end you can navigate a cluster in k9s, inspect resources, read logs and
open a shell, port-forward and scale a workload, and diagnose and fix a broken deployment without leaving
the TUI.

> **Shells:** k9s is a terminal UI, so every keystroke in this lab is identical on Windows, macOS, and
> Linux. Only a handful of `kubectl`/`curl` commands run in your shell. Where PowerShell differs from
> Bash, both variants are shown.

---

## Part 0: Setup

k9s is already installed on your machine. Check it and start from a running minikube cluster.

```bash
k9s version
```

Deploy the workloads you'll explore (a healthy app plus one that is deliberately broken). Save the
following manifest as `setup.yaml`:

```yaml
# Lab 25 - k9s playground workloads.
# Two Deployments in the default namespace:
#   * web    - a healthy nginx (2 replicas) plus a ClusterIP Service.
#   * broken - an nginx with a non-existent image tag (ImagePullBackOff)
#              that you diagnose and fix from inside k9s.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.4
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: web
  labels:
    app: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken
  labels:
    app: broken
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken
  template:
    metadata:
      labels:
        app: broken
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.4-doesnotexist
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
```

Then apply it (run this from the directory where you saved the file):

```bash
kubectl apply -f setup.yaml
```

This creates, in the `default` namespace:

- **`web`**: a healthy nginx Deployment with 2 replicas, plus a `web` Service.
- **`broken`**: an nginx Deployment that will **not** start (you'll find out why in Part 5).

Now launch k9s:

```bash
k9s
```

You land on a resource table. The header (top-left) shows your context and namespace; the top-right lists
the keys available in the current view. Two keys to remember from the start:

- **`Esc`**: go back / clear a filter.
- **`:q`** then `Enter`, or **`Ctrl-C`**: quit k9s.

---

## Part 1: Getting around

k9s uses a command prompt, like Vim. Press **`:`**, type a resource, press `Enter`.

1. Jump between resource types:
   - `:pods` `Enter`: all pods
   - `:deployments` `Enter`: deployments
   - `:services` `Enter`: services
   - `:namespaces` `Enter`: namespaces

   > Short names work too: `:po`, `:deploy`, `:svc`, `:ns`. Aliases are the same ones `kubectl` uses.

2. Press **`?`** to open the help screen with every key binding for the current view. Press `Esc` to close it.

3. **Namespaces.** Press **`0`** to show pods from *all* namespaces. To focus a single namespace, run
   **`:ns`** `Enter` and select one — that always works. The header also lists namespaces with a leading
   digit (e.g. `<1>`); pressing that digit is a shortcut for the same thing. Set it back to `default` for
   the rest of the lab.

4. **Filter.** In the pods view, press **`/`**, type `web`, and press `Enter`. The table now shows only
   matching pods. Press `Esc` to clear the filter.

5. **Sort.** In a table, use the shortcut keys shown in the header (e.g. sort by name, CPU, or age).
   Column sorting helps you spot the busiest or oldest pods quickly.

**Task:** Using only k9s, answer: how many `web` pods are running, and what are their statuses?

---

## Part 2: Inspecting a resource

Navigate to `:pods` and highlight one of the `web` pods with the arrow keys.

1. Press **`d`** to `describe` it. You get the same detail as `kubectl describe`, including the
   **Events** at the bottom. Press `Esc` to go back.
2. Press **`y`** to see the full YAML of the resource. Press `Esc` to go back.
3. **Drill down.** Go to `:deploy`, highlight `web`, and press `Enter`. k9s jumps straight to the
   Deployment's **pods** (it skips the ReplicaSet). Press `Enter` on a pod to reach its containers. Use
   `Esc` to climb back up each level.
   > Want to see the ReplicaSet layer? Press **`z`** on the Deployment instead of `Enter`.

**Task:** Starting from the `web` Deployment, drill all the way down to the `nginx` container. How many
`Enter` presses did it take (Deployment → ? → container)?

---

## Part 3: Logs and shell

Go to `:pods` and highlight a `web` pod.

1. **Logs.** Press **`l`** to stream the container logs live (like `kubectl logs -f`). A fresh nginx has
   only start-up lines for now. You'll generate real traffic in Part 4. Press `Esc` to leave the log view.
   > Useful log-view keys (shown in the header): toggle wrap, toggle timestamps, and jump to the top/bottom.

2. **Shell.** With a `web` pod highlighted, press **`s`** to open a shell *inside* the container (like
   `kubectl exec -it ... -- /bin/sh`). Try a few Linux commands:

   ```sh
   ls -l /usr/share/nginx/html
   printenv
   cat /etc/nginx/conf.d/default.conf
   ```

   > These run inside the Linux container, so they behave the same no matter which OS your laptop runs.
   > Type `exit` to return to k9s.

**Task:** What is the name of the HTML file nginx serves by default (look in `/usr/share/nginx/html`)?

---

## Part 4: Port-forward and scale

### 4.1 Port-forward

Let's reach the `web` app from your laptop and watch the access logs light up.

1. Go to `:svc`, highlight the `web` service, and press **`Shift-F`**. A dialog opens with the forward
   details. Set the **local port** to **`8080`** (leave the service/container port as **`80`**), then
   confirm. k9s now forwards `localhost:8080` to the Service.
   > You can review active forwards any time with **`:pf`** `Enter`.

2. From your shell (a **second** terminal, leaving k9s running), request the app:

   ```bash
   curl http://localhost:8080
   ```

   > **Windows (PowerShell):** `curl` is an alias for `Invoke-WebRequest`. For a plain request it works,
   > but to stay consistent with macOS/Linux use `curl.exe`:
   >
   > ```powershell
   > curl.exe http://localhost:8080
   > ```

   You should get the nginx welcome HTML. Run it a few times.

3. Back in k9s, open the **logs** (`l`) of a `web` pod again. Now you can see your `GET /` requests
   appearing live in the access log.

### 4.2 Scale

1. Go to `:deploy` and highlight `web`.
2. Press **`s`** (Scale). In the dialog, set replicas to **`4`** and confirm.
3. Switch to `:pods` and watch two new `web` pods appear and go `Running` in real time.
4. Scale back down to `2` the same way.

**Task:** How does the pod table change the moment you confirm the scale-up?

---

## Part 5: Troubleshooting the broken workload

The `broken` Deployment has never come up. Let's diagnose and fix it entirely from k9s.

1. Go to `:pods`. The `broken-...` pod is **not** `Running`. It shows something like `ImagePullBackOff`
   or `ErrImagePull` (k9s colours it red).

2. **Read the events.** Highlight the `broken` pod and press **`d`** (describe). Scroll to **Events** at
   the bottom. You'll see a message like *"Failed to pull image ... not found"*. The image tag does not
   exist.

3. **Check the logs.** Press **`l`**. There are **no** container logs, because the container never started.
   That absence is itself the clue: when there are no logs but the pod is unhealthy, look at the events and
   the image, not the app.

   > Diagnosis: `setup.yaml` uses the image `nginx:1.29.4-doesnotexist`, which is not a real tag. The fix
   > is to point the Deployment at a real image, `nginx:1.29.4`.

4. **Fix it, the k9s way (`e`).** Go to `:deploy`, highlight `broken`, and press **`e`** to edit. k9s
   opens the resource in your editor. Change the image tag to `nginx:1.29.4`, save, and close the editor.

   > k9s uses the editor from the `K9S_EDITOR` (or `EDITOR`) environment variable. Set it **before** you
   > launch k9s:
   >
   > ```powershell
   > # Windows (PowerShell)
   > $env:K9S_EDITOR = "notepad"
   > ```
   >
   > ```bash
   > # macOS / Linux
   > export K9S_EDITOR=nano
   > ```

5. **Fix it, the reliable fallback.** If editing in k9s is awkward (no editor configured, or you'd rather
   use the command line), run this in your shell. It works identically in Bash and PowerShell:

   ```bash
   kubectl set image deployment/broken nginx=nginx:1.29.4
   ```

6. **Watch it recover.** Either fix triggers a new rollout. In k9s, go to `:pods` and watch: a fresh
   `broken-...` pod is created, pulls the real image, and turns green (`Running`). Confirm with `d` that the
   Events now show a successful pull and start.

**Task:** After the fix, how many `broken` pods are `Running`, and what does the pod status column show?

---

## Part 6: Cleanup

1. **Delete from within k9s.** Go to `:deploy`, highlight `broken`, and press **`Ctrl-D`**. Confirm the
   deletion dialog. The Deployment (and its pod) disappears from the table. This is how you delete any
   resource in k9s.

2. **Remove everything else.** Quit k9s (`:q`) and run:

   ```bash
   kubectl delete -f setup.yaml
   ```

   > `broken` is already gone, so you may see a "not found" note for it. That's expected and harmless.

---

## Summary: key k9s bindings

| Key | Action |
| ------ | ----- |
| `:` then `<resource>` | Jump to a resource type (`:pods`, `:deploy`, `:svc`, `:ns`) |
| `?` | Help / all key bindings for the current view |
| `/` | Filter the current table |
| `0` | Toggle all namespaces |
| `Enter` | Drill into the highlighted resource (Deployment → pods, skipping the ReplicaSet) |
| `z` | Show the ReplicaSets of the highlighted Deployment |
| `Esc` | Go back / clear filter |
| `d` | Describe (with Events) |
| `y` | Show full YAML |
| `l` | Stream logs |
| `s` | Shell into a pod / Scale a deployment (context-dependent) |
| `Shift-F` | Port-forward |
| `e` | Edit in `$K9S_EDITOR` |
| `Ctrl-D` | Delete the highlighted resource |
| `:q` `Enter` / `Ctrl-C` | Quit k9s |

---

## Further resources

- [k9s documentation](https://k9scli.io/)
- [k9s command reference](https://k9scli.io/topics/commands/)
- [k9s key bindings (README)](https://github.com/derailed/k9s#key-bindings)
