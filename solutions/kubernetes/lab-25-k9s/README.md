# Solution for Lab 25: Navigating & Troubleshooting with k9s

This walkthrough gives the exact keystrokes and answers for each part. k9s keys are identical on all
operating systems; the few shell commands show Bash and PowerShell where they differ.

## Setup

```bash
k9s version
kubectl apply -f setup.yaml   # from labs/kubernetes/lab-25-k9s/
k9s
```

`setup.yaml` creates `web` (healthy, 2 replicas) + `web` Service and `broken` (ImagePullBackOff) in
`default`.

## Part 1: Getting around

- `:pods`, `:deploy`, `:svc`, `:ns` (or `:po`) to switch views; `?` for help; `Esc` to close.
- `0` toggles all namespaces; pick `default` again afterwards.
- `/web` `Enter` filters the pod list; `Esc` clears it.

**Answer:** There are **2** `web` pods, both `Running` (2/2 ready) once images are pulled.

## Part 2: Inspecting a resource

- `d` describes (Events at the bottom); `y` shows full YAML; `Esc` returns.
- From `:deploy` → `web` → `Enter` you pass **Deployment → ReplicaSet → Pod → container**: **3** hops to
  reach the `nginx` container.

## Part 3: Logs and shell

- `l` streams logs; `Esc` leaves.
- `s` opens a shell in the container.

**Answer:** nginx serves **`index.html`** from `/usr/share/nginx/html`.

## Part 4: Port-forward and scale

- On `:svc` → `web`, `Shift-F`, local `8080` → container `80`. `:pf` lists active forwards.
- From a second terminal:

  ```bash
  curl http://localhost:8080
  ```

  ```powershell
  curl.exe http://localhost:8080
  ```

  Re-open a `web` pod's logs (`l`) to see the `GET /` access-log lines from the requests.
- On `:deploy` → `web`, `s` (Scale) → `4`. In `:pods`, two new pods appear and go `Running`.

**Answer:** The instant you confirm the scale-up, two new `web-...` pods appear as `Pending` /
`ContainerCreating` and then flip to `Running`.

## Part 5: Troubleshooting the broken workload

- `:pods` shows `broken-...` in `ImagePullBackOff` / `ErrImagePull` (red).
- `d` → Events: *"Failed to pull image \"nginx:1.29.4-doesnotexist\" ... not found"*.
- `l` shows **no** logs. The container never started, which points you at the image/events, not the app.
- **Root cause:** the image tag `nginx:1.29.4-doesnotexist` does not exist.
- **Fix (k9s):** `:deploy` → `broken` → `e`, change the tag to `nginx:1.29.4`, save. Requires an editor:

  ```powershell
  $env:K9S_EDITOR = "notepad"   # set before launching k9s
  ```

  ```bash
  export EDITOR=nano            # set before launching k9s
  ```

- **Fix (fallback, any shell):**

  ```bash
  kubectl set image deployment/broken nginx=nginx:1.29.4
  ```

- Either way, a new rollout starts; the fresh `broken-...` pod pulls `nginx:1.29.4` and goes `Running`.

**Answer:** After the fix there is **1** `broken` pod, status `Running` (1/1).

## Part 6: Cleanup

- `:deploy` → `broken` → `Ctrl-D`, confirm. This deletes it from within k9s.
- Quit (`:q`) and:

  ```bash
  kubectl delete -f setup.yaml
  ```

  `broken` may report "not found" (already deleted in k9s), which is harmless.

## Instructor notes

- The lab is **interactive (TUI)**, so it has no automated `tests/` (chainsaw) entry. Unlike most labs,
  its steps can't be driven headlessly. Only `setup.yaml` is lint-checked in CI.
- If a student's `e` edit fails to open, it's almost always a missing `K9S_EDITOR`/`EDITOR`; the
  `kubectl set image` fallback always works.
- Reset for the next student: `kubectl delete -f setup.yaml` then re-apply.
