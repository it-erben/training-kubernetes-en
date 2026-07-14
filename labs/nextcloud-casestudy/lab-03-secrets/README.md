# Secrets for the database

You may have noticed that the phpMyAdmin manifest simply copies the database user and password
from the database manifest. That's ugly – and insecure on top. Let's move the credentials into
a Kubernetes Secret.

> **Docs:**
>
> - [Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
> - [Secrets as environment variables (`secretKeyRef`)](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data)

The environment variable sections we want to replace look like this:

```yaml
env:
  - name: MYSQL_ROOT_PASSWORD
    value: "mysecretpassword"
  - name: MYSQL_DATABASE
    value: "nextcloud"
  - name: MYSQL_USER
    value: "nextcloud"
  - name: MYSQL_PASSWORD
    value: "nextcloudpassword"
```

First, we need a Secret for these entries. Create a manifest `secret.yaml` that contains the
keys and values above.

Next, reference the Secret in `db.yaml` and in `pma.yaml`. For the database StatefulSet, it
looks like this:

```yaml
env:
  - name: MYSQL_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_ROOT_PASSWORD
  - name: MYSQL_USER
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_USER
  - name: MYSQL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_PASSWORD
  - name: MYSQL_DATABASE
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_DATABASE
```

The pattern is always the same. The `name` of the environment variable stays as before, but the value
now comes from the Secret.

For phpMyAdmin in `pma.yaml`, things look slightly different because the environment variables
have different names:

```yaml
env:
  - name: PMA_USER
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_USER
  - name: PMA_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nextcloud-db-secret
        key: MYSQL_PASSWORD
  - name: PMA_HOST
    value: nextcloud-db
  - name: PMA_PORT
    value: "3306"
```

When you are done, apply the files:

```shell
kubectl apply -f secret.yaml
kubectl apply -f pma.yaml
kubectl apply -f db.yaml
```

Finally, open the tunnel to phpMyAdmin again and check that everything still works:

```shell
minikube service phpmyadmin -n nextcloud
```
