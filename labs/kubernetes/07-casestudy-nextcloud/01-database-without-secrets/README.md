# Nextcloud Stage 1: Database

We will first set up the **database** required for Nextcloud to operate.

**Step 0** is to create a Namespace named **`nextcloud`**. Use `kubectl` for this.

```shell
kubectl create namespace nextcloud
```

To avoid having to specify the Namespace in every command, set it as the current default:

```shell
kubectl config set-context --current --namespace=nextcloud
```

Your task is now to **create a single Kubernetes manifest** that provisions a MariaDB database. The manifest must consist of two parts: a **StatefulSet** that configures and deploys the MariaDB database, and a **Service** that enables access to the database.

-----

## StatefulSet Creation

* Define the **StatefulSet** named **`nextcloud-db`** in the `nextcloud` Namespace.

* Set the number of replicas to **`1`**, as only a single database instance is needed.

* Define a container template for MariaDB using the **`mariadb:latest`** image.

* Include the following **Environment Variables** to configure the database:

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

* Define a **Volume Mount** that ensures the database files are persistently stored in the directory **`/var/lib/mysql`**.

* Create a **VolumeClaimTemplate** that requests a Persistent Volume with a size of **`10Gi`** and ensures it can only be written to by a single node at a time (AccessMode: **`ReadWriteOnce`**).

  ```yaml
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
  ```

-----

## Service Creation

* Define a **Service** named **`nextcloud-db`** in the `nextcloud` Namespace.
* Set the **`clusterIP`** to **`None`** (Headless Service) so that each Pod in the StatefulSet receives its own DNS name.
* Configure a port through which the database Service is reachable (Port **`3306`**).

-----

## Finalize and Apply Manifest

Ensure the resulting YAML document is syntactically correct and meets all the requirements above.

**Apply the complete manifest** and subsequently verify that the StatefulSet is running as expected.

## Verification

Start a temporary debug Pod and use `nslookup` to confirm that the Service is reachable and resolves to an IP address for the database Pod.

```yaml
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
#/ nslookup nextcloud-db.nextcloud.svc.cluster.local
```

Good luck\!
