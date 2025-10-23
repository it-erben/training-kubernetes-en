# Secrets for the Database

You may have noticed that we simply copied the database user and password from the database manifest to the PhpMyAdmin manifest. This practice is both cumbersome and insecure. We will now **externalize the access credentials into a Kubernetes Secret**.

The sections containing the environment variables we need to replace look like this:

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

-----

## Step 1: Create the Secret

Your first step is to create a **Secret** containing the keys and values above.

* Create a manifest file named **`secret.yaml`**.
* Define a Secret named **`nextcloud-db-secret`** containing the four keys and their respective values. *Note: Remember that Secret data is base64 encoded.*

-----

## Step 2: Update the Database Manifest (`db.yaml`)

You must now reference the Secret in the database StatefulSet manifest (`db.yaml`). Replace the hardcoded `value` fields with `valueFrom` using `secretKeyRef` for the four environment variables.

For the MariaDB StatefulSet, the environment variables should now look like this:

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

The pattern is always the same: the environment variable `name` remains as before, but the value is retrieved from the specified Secret key.

-----

## Step 3: Update the PhpMyAdmin Manifest (`pma.yaml`)

For PhpMyAdmin (`pma.yaml`), the environment variable names are different, so you must map the Secret keys accordingly.

Update the PhpMyAdmin Deployment's environment variables to reference the Secret:

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
  - name: PMA_HOST # This variable is not in the Secret
    value: nextcloud-db
  - name: PMA_PORT # This variable is not in the Secret
    value: "3306"
```

-----

## Step 4: Apply and Verify

Once you have updated all three files, apply them in the correct order:

```shell
kubectl apply -f secret.yaml
kubectl apply -f pma.yaml # This will trigger a rolling update to read the new Secret
kubectl apply -f db.yaml # This will trigger a rolling update to read the new Secret
```

Finally, rebuild the tunnel to PhpMyAdmin and check if everything is still functioning correctly:

```shell
minikube service phpmyadmin -n nextcloud
```
