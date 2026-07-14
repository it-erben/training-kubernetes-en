# Solution: Persistent Volumes

```bash
kubectl apply -f manifest.yaml
kubectl get pv,pvc
kubectl get pods

# Copy index.html
kubectl cp index.html my-pod:/usr/share/nginx/html/index.html -c my-container
minikube service my-service

# Verify persistence
kubectl delete pod my-pod
kubectl apply -f manifest.yaml
minikube service my-service

# PV remains, file is still there
kubectl delete pod my-pod
kubectl get pv
```

Expected result: the page remains available after the pod is recreated because the PVC keeps using the PV.
