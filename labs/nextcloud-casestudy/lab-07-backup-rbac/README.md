# Nextcloud Stage 7: Backup, restore & least-privilege RBAC

Across labs 01-05 you built a running MariaDB + Nextcloud stack: a StatefulSet, Secrets,
persistent volumes, probes, resource limits, and an Ingress. The stack works, but it has
no backup. Lose the database and you lose everything.

In this lab you add a scheduled backup that dumps the database nightly, and you wire it
up with the smallest possible identity: a ServiceAccount that can find the MariaDB pod and
exec into it, and nothing else. This is the Kubernetes RBAC principle of least privilege
in practice.

> **Docs:**
>
> - [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
> - [RBAC authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
> - [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
>
> **Shells:** `kubectl` commands are identical on Windows, macOS, and Linux.
> No commands in this lab differ across shells, so no dual variants are shown.

---

## Part 0: Setup check

This lab needs no minikube add-ons. Switch to the `nextcloud` namespace and confirm the
stack from the previous labs is running:

```bash
kubectl config set-context --current --namespace=nextcloud
kubectl get pods
```

You should see MariaDB (`nextcloud-db-0`) and Nextcloud pods in `Running` state. If anything
is missing, revisit labs 01-05 before continuing.

---

## Part 1: A place to keep backups

Create a PVC that the backup Job (and later the CronJob) will use to store SQL dumps.
Name it `nextcloud-backup`, access mode `ReadWriteOnce`, 2Gi. Here is the full manifest,
since the storage layer is not the learning objective here:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nextcloud-backup
  namespace: nextcloud
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
```

Apply it and confirm it binds:

```bash
kubectl apply -f backup-pvc.yaml
kubectl get pvc nextcloud-backup
```

---

## Part 2: Try to back up, and watch it fail

The database password should never be copied into the backup Job. So the Job never sees
it. Instead the Job uses `kubectl exec` to step inside the MariaDB pod and run
`mariadb-dump` from there, where the password already exists as `MYSQL_ROOT_PASSWORD`.

The trick is *where* the password gets filled in. `$MYSQL_ROOT_PASSWORD` is wrapped in
single quotes, and single quotes tell a shell "leave this text exactly as it is." So the
Job's shell hands the literal string `$MYSQL_ROOT_PASSWORD` over to MariaDB untouched.
Only the shell inside the MariaDB pod, where the password is actually defined, swaps in
the real value. The secret travels as a name, never as its value.

`--databases nextcloud` tells the dump to include the `CREATE DATABASE` line, which the
restore step later needs to rebuild the database from scratch.

The exec command the backup script uses:

```sh
POD=$(kubectl get pod -l app=nextcloud-db -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -- sh -c \
  'exec mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --databases nextcloud'
```

For `kubectl exec` to work from inside a pod, that pod needs a ServiceAccount with the
right permissions. Create a ServiceAccount named `nextcloud-backup`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nextcloud-backup
  namespace: nextcloud
```

Now write a one-off `Job` that:

- uses the `alpine/k8s:1.32.0` image (ships `kubectl` and a shell),
- references the `nextcloud-backup` ServiceAccount,
- mounts the `nextcloud-backup` PVC at `/backup`,
- runs the exec command above and writes the dump to `/backup/latest.sql`.

Apply the Job and tail its logs:

```bash
kubectl logs -f job/<your-job-name>
```

The Job will fail. You should see something like:

```text
Error from server (Forbidden): pods is forbidden: User
"system:serviceaccount:nextcloud:nextcloud-backup" cannot list resource "pods" ...
```

Before moving on: what are the **two** permissions this Job actually needs?

---

## Part 3: Grant exactly what it needs

Write a `Role` named `nextcloud-backup` in the `nextcloud` namespace. The rules section
must be exactly this, no more, no less:

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    resourceNames: ["nextcloud-db-0"]
    verbs: ["create"]
```

`pods` (get, list) lets the Job find the MariaDB pod by label. `pods/exec` (create) is
the subresource that backs `kubectl exec`; it is distinct from `pods` itself. The
`resourceNames` restriction limits exec access to the MariaDB StatefulSet pod.

Then write a `RoleBinding` that binds the Role to the `nextcloud-backup` ServiceAccount.

Apply both, delete the failed Job, and re-apply it. This time the logs should confirm a
successful dump.

Inspect the file on the PVC by mounting it in a throwaway pod:

```bash
kubectl run peek --rm -it --image=busybox --restart=Never \
  --overrides='{"spec":{"volumes":[{"name":"b","persistentVolumeClaim":{"claimName":"nextcloud-backup"}}],"containers":[{"name":"peek","image":"busybox","command":["sh"],"stdin":true,"tty":true,"volumeMounts":[{"name":"b","mountPath":"/backup"}]}]}}' \
  -- sh
# inside: ls -lh /backup
```

---

## Part 4: Put it on a schedule

Turn the one-off Job into a `CronJob` named `nextcloud-backup` that fires at `0 2 * * *`
(02:00 every night). A CronJob is a thin wrapper: it adds a `schedule` field and nests
the Job's `spec` inside a `jobTemplate`. The structure looks like:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nextcloud-backup
  namespace: nextcloud
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      # ...paste the Job spec you already wrote here
      template:
        spec:
          # serviceAccountName, containers, volumes, ...
```

Apply the CronJob. Instead of waiting until 02:00, trigger an immediate run:

```bash
kubectl create job --from=cronjob/nextcloud-backup manual-1
kubectl logs job/manual-1
```

Confirm a fresh dump landed on the PVC.

---

## Part 5: Restore

Knowing backups exist is not enough; you need to know the restore works. Deliberately
break the database:

```bash
kubectl exec nextcloud-db-0 -- \
  sh -c 'exec mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE nextcloud;"'
```

Reload Nextcloud in your browser to confirm it is broken (Internal Server Error or similar).

Now write a one-off `Job` named `nextcloud-restore` that:

- uses the same `nextcloud-backup` ServiceAccount and `alpine/k8s:1.32.0` image,
- mounts the `nextcloud-backup` PVC at `/backup`,
- finds the MariaDB pod by label (same label selector as the backup),
- pipes `/backup/latest.sql` back in with:

  ```sh
  kubectl exec -i "$POD" -- sh -c \
    'exec mariadb -uroot -p"$MYSQL_ROOT_PASSWORD"' \
    < /backup/latest.sql
  ```

Apply it, watch the logs, then reload Nextcloud to confirm the database is back.

---

## Part 6: Prove least privilege

The `nextcloud-backup` identity can exec into pods. What else can it do?

```bash
kubectl auth can-i get secrets --as=system:serviceaccount:nextcloud:nextcloud-backup
kubectl auth can-i delete pods --as=system:serviceaccount:nextcloud:nextcloud-backup
kubectl --as=system:serviceaccount:nextcloud:nextcloud-backup \
  exec nextcloud-db-0 -- sh -c true
APP_POD=$(kubectl get pod -l app=nextcloud -o jsonpath='{.items[0].metadata.name}')
kubectl --as=system:serviceaccount:nextcloud:nextcloud-backup \
  exec "$APP_POD" -- sh -c true
```

The first two commands print `no`. The MariaDB exec succeeds; the application-pod exec is
forbidden. The Role grants exactly what the backup workflow needs and nothing beyond that.
