# Solution: Pods + ClusterIP Service

```bash
kubectl apply -f manifest.yaml
kubectl get pod --selector=app=nginx-pod-demo -o wide

# Start a debug container and test DNS
kubectl debug nginx-pod-1 -it --image=busybox
nslookup nginx-pod-demo-svc.default.svc.cluster.local
wget -q -O- http://nginx-pod-demo-svc.default.svc.cluster.local
exit

# Clean up
kubectl delete service/nginx-pod-demo-svc
kubectl delete pod/nginx-pod-1 pod/nginx-pod-2
```

Expected result: `nslookup` returns the service's ClusterIP, and `wget` returns the NGINX welcome page.
