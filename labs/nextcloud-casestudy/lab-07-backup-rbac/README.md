# Nextcloud Stage 7: Backup, restore & least-privilege RBAC

Across labs 01–05 you built a running MariaDB + Nextcloud stack: a StatefulSet, Secrets,
persistent volumes, probes, resource limits, and an Ingress. The stack works — but it has
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
is missing, revisit labs 01–05 before continuing.

---

## Part 1: A place to keep backups

Create a PVC that the backup Job (and later the CronJob) will use to store SQL dumps.
Name it `nextcloud-backup`, access mode `ReadWriteOnce`, 2Gi. Here is the full manifest
— the storage layer is not the learning objective here:

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

## Part 2: Try to back up — and watch it fail

The backup strategy avoids storing database credentials in the backup Job. Instead, the
Job uses `kubectl exec` to reach inside the MariaDB pod and run `mysqldump` there. The
password already lives in the MariaDB container's environment (`MYSQL_ROOT_PASSWORD`).
The key is the **single-quote trick**: `$MYSQL_ROOT_PASSWORD` is single-quoted in the
inner `sh -c` string, so the shell does *not* expand it in the Job's container. The
variable expands later, inside the MariaDB container, where it is defined.

The exec command the backup script uses:

```sh
POD=$(kubectl get pod -l app=nextcloud-db -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -- sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction nextcloud'
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

- uses the `bitnami/kubectl:1.32` image,
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
must be exactly this — no more, no less:

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]
```

`pods` (get, list) lets the Job find the MariaDB pod by label. `pods/exec` (create) is
the subresource that backs `kubectl exec` — it is distinct from `pods` itself.

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

## Part 5: The restore drill

Knowing backups exist is not enough — you need to know the restore works. Deliberately
break the database:

```bash
kubectl exec nextcloud-db-0 -- \
  sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE nextcloud;"'
```

Reload Nextcloud in your browser to confirm it is broken (Internal Server Error or similar).

Now write a one-off `Job` named `nextcloud-restore` that:

- uses the same `nextcloud-backup` ServiceAccount and `bitnami/kubectl:1.32` image,
- mounts the `nextcloud-backup` PVC at `/backup`,
- finds the MariaDB pod by label (same label selector as the backup),
- pipes `/backup/latest.sql` back in with:

  ```sh
  kubectl exec -i "$POD" -- sh -c \
    'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" nextcloud' \
    < /backup/latest.sql
  ```

Apply it, watch the logs, then reload Nextcloud to confirm the database is back.

---

## Part 6: Prove least privilege

The `nextcloud-backup` identity can exec into pods. What else can it do?

```bash
kubectl auth can-i get secrets --as=system:serviceaccount:nextcloud:nextcloud-backup
kubectl auth can-i delete pods --as=system:serviceaccount:nextcloud:nextcloud-backup
kubectl auth can-i create pods/exec --as=system:serviceaccount:nextcloud:nextcloud-backup
```

Expected output: `no`, `no`, `yes`. The Role grants exactly what the backup workflow
needs and nothing beyond that. The identity cannot read Secrets (so it cannot escalate
to get DB credentials through another path), cannot delete pods, cannot create new pods,
and has no cluster-wide permissions whatsoever.

---

## Bonus

- **Tighten with `resourceNames`:** add `resourceNames: [nextcloud-db-0]` to the `pods`
  rule so the Role is scoped to that one pod, not any pod in the namespace.
- **History limits:** add `successfulJobsHistoryLimit: 3` and `failedJobsHistoryLimit: 1`
  to the CronJob to keep the Job list tidy.
- **Why `pods/exec` is a subresource:** in Kubernetes, `pods/exec` is modeled as a
  subresource rather than a verb on `pods`. This means you need `create` on `pods/exec`
  separately from any permission on `pods` itself. It also means you can grant exec access
  without granting the ability to create, delete, or modify pods.
