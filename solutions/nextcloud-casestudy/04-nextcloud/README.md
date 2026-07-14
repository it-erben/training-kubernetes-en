# Solution: Nextcloud with Persistence

```bash
kubectl apply -f nextcloud-with-storage.yaml
kubectl get deploy,pvc,svc -n nextcloud
minikube service nextcloud -n nextcloud
```

The PVC `nextcloud-pvc` binds a volume mounted at `/var/www/html`; the service is exposed as a NodePort.
