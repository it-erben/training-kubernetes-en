# Solution: ConfigMap as a File

```bash
kubectl apply -f nginx-configmap.yaml
kubectl get pod nginx-custom
minikube service nginx-service
```

Expected result: nginx serves the custom HTML page from the ConfigMap, and the NodePort makes it reachable from
outside the cluster.
