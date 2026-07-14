# Solution: ConfigMap as a File

```bash
kubectl apply -f nginx-configmap.yaml
kubectl get pod nginx-custom
minikube service nginx-service
```

Expected result: the custom HTML page from the ConfigMap is served; it is reachable from outside via the NodePort.
