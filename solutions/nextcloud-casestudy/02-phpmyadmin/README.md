# Solution: phpMyAdmin

```bash
kubectl apply -f pma.yaml
kubectl get deploy,svc -n nextcloud
minikube service phpmyadmin -n nextcloud
```

The deployment's environment variables point to the MariaDB service and the resources are set as required; the
service is a NodePort.
