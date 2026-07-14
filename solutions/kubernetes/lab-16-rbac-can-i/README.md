# Solution: RBAC + `can-i`

```bash
kubectl apply -f rbac.yaml

# Admin account
kubectl auth can-i create pods --as=system:serviceaccount:default:admin
kubectl auth can-i delete cronjobs.batch --as=system:serviceaccount:default:admin

# Developer account
kubectl auth can-i list pods --as=system:serviceaccount:default:developer
kubectl auth can-i create pods --as=system:serviceaccount:default:developer   # expected: "no"
kubectl auth can-i delete replicasets.apps --as=system:serviceaccount:default:developer   # expected: "no"
```

`admin` has full access to Pods, ReplicaSets, and CronJobs; `developer` only has read permissions.
