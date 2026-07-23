# Solution: Backup, restore & least-privilege RBAC

The backup Job execs `mysqldump` inside MariaDB under a ServiceAccount scoped to only `pods` get/list
and `pods/exec` create, so it holds no database credentials.

## Create the backup target and identity

```bash
kubectl apply -f backup-pvc.yaml
kubectl apply -f rbac.yaml
```

The PVC `nextcloud-backup` provides 2 Gi of storage for dumps. `rbac.yaml` creates the ServiceAccount,
Role, and RoleBinding in one apply.

## Watch it fail without the binding

If you trigger a backup Job before applying `rbac.yaml` — or under the namespace's `default`
ServiceAccount — the pod logs show `Error from server (Forbidden): pods is forbidden` and
`cannot create resource "pods/exec"`. This confirms the Role is the only thing granting exec access.

## Schedule and trigger a backup

```bash
kubectl apply -f backup-cronjob.yaml
kubectl create job --from=cronjob/nextcloud-backup manual-1 -n nextcloud
kubectl logs -n nextcloud job/manual-1
```

The CronJob runs nightly at 02:00. The manual trigger creates an immediate Job for testing.
Expect a log line: `Backup written: nextcloud-<timestamp>.sql`. The dump is also copied to
`/backup/latest.sql` for the restore Job.

## Restore drill

```bash
# Break it: drop the database inside MariaDB
kubectl exec -n nextcloud nextcloud-db-0 -- \
  sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE nextcloud;"'
# Restore from the latest dump
kubectl apply -f restore-job.yaml
kubectl logs -n nextcloud job/nextcloud-restore
```

Expect `Restore complete from latest.sql`. Nextcloud recovers once the database is back.

## Confirm the identity is least-privilege

```bash
kubectl auth can-i get secrets \
  --as=system:serviceaccount:nextcloud:nextcloud-backup -n nextcloud
# -> no
kubectl auth can-i create pods/exec \
  --as=system:serviceaccount:nextcloud:nextcloud-backup -n nextcloud
# -> yes
```

The ServiceAccount can exec into pods but cannot read Secrets, ConfigMaps, or any other resource.
