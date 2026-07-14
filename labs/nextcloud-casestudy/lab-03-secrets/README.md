# Secrets for the database

You may have already noticed that we simply copied the database user and password in the PhpMyAdmin
manifest from the database manifest. That is ugly – and also insecure. We now want to move the
credentials into a Kubernetes Secret.

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

As a first step, we need a Secret for these entries. Create a manifest `secret.yaml` that contains the
keys and values above.

We now need to reference the Secret in the `db.yaml` manifest as well as in `pma.yaml`. For the database
StatefulSet, this looks as follows:

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

For PhpMyAdmin in `pma.yaml`, we have to do it slightly differently, because the environment variables have different names:

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

Finally, set up the tunnel to phpmyadmin again and check whether everything still works:

```shell
minikube service phpmyadmin -n nextcloud
```
