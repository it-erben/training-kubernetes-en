# Solution: Wiring in Secrets

```bash
kubectl apply -f secret.yaml
kubectl apply -f db-with-secret.yaml
kubectl apply -f pma-with-secret.yaml
minikube service phpmyadmin -n nextcloud
```

The sensitive values live in the Secret `nextcloud-db-secret`; both the database and the phpMyAdmin deployment
reference the secret keys.
