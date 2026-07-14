# Solution: HPA

```bash
minikube addons enable metrics-server
kubectl apply -f manifest.yaml
kubectl apply -f hpa.yaml
kubectl get hpa -w

# Load test
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
```

The HPA `nginx-hpa` scales the ReplicaSet between 1 and 10 replicas based on a 30% CPU target.
