# Nextcloud Stage 1: Database

First, we set up the database that Nextcloud needs to run. Step 0 is to create a namespace
called "nextcloud". Use `kubectl` for this.

To avoid passing the namespace with every command from now on, tell kubectl to use the new
namespace as the default:

```shell
kubectl config set-context --current --namespace=nextcloud
```

Your task is to write a Kubernetes manifest that sets up a MariaDB database. The manifest
has two parts: a StatefulSet that configures and runs MariaDB, and a Service that makes the
database reachable.

## Create the StatefulSet

> **Docs:**
>
> - [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
> - [VolumeClaimTemplate / PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

- Define the StatefulSet with the name `nextcloud-db` in the namespace `nextcloud`.
- Set the number of replicas to `1`, since we only need one instance of the database.
- Create a container template for MariaDB that uses the latest MariaDB image (`mariadb:latest`).
- Add environment variables to configure the database:

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

  - Define a volume mount so the database data is stored in `/var/lib/mysql`.
  - Create a VolumeClaimTemplate that requests a `10Gi` persistent volume that only one node
    can write to at a time (AccessMode: `ReadWriteOnce`).

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

## Create the Service

> **Docs:**
>
> - [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
> - [Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

- Define a Service with the name `nextcloud-db` in the namespace `nextcloud`.
- Set the `clusterIP` to `None` so that each pod in the StatefulSet gets its own DNS name.
- Define the port the database service is reachable on (port `3306`).

## Finish the manifest

Make sure the manifest is syntactically correct and meets the requirements listed above.

You should end up with a single YAML document containing the StatefulSet and its accompanying
Service. Apply the manifest and check that the StatefulSet is running as expected.

## Verify the result

Start a debug pod and check that the service is reachable and resolves to the pod's IP.

```yaml
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
#/ nslookup nextcloud-db.nextcloud.svc.cluster.local
```

Good luck!
