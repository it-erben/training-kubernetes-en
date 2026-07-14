# Solution: Database

```bash
kubectl apply -f db.yaml
kubectl config set-context --current --namespace=nextcloud
kubectl get sts,svc
kubectl run -it --rm busybox --image=busybox --restart=Never -- sh -c "nslookup nextcloud-db.nextcloud.svc.cluster.local"
```

The StatefulSet creates the PVC `data`, the service is headless (`clusterIP: None`) and returns the pod IP of the database.
