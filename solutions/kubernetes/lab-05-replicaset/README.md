# Solution: ReplicaSet

```bash
kubectl apply -f manifest.yaml
kubectl get pods --selector=app=replicaset-demo
kubectl delete pod <POD_NAME>
kubectl get pods --selector=app=replicaset-demo   # third replica gets replaced
kubectl delete replicaset.apps/replicaset-demo
```

Expected result: after you delete a pod, the ReplicaSet automatically creates a replacement to get back to 3 replicas.
