# Solution: HPA (manual)

```bash
minikube addons enable metrics-server
kubectl apply -f replicaset.yaml
kubectl apply -f hpa.yaml
kubectl get hpa -w
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
```

The ReplicaSet `nginx-replicaset` starts with 3 pods and resource limits. The HPA keeps utilization at ~30% and
scales between 1 and 10.
