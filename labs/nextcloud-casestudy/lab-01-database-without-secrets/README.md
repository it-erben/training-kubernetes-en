# Nextcloud Stage 1: Database

First, we set up the database that Nextcloud needs to run. Step 0 is to create a namespace
called "nextcloud". Use `kubectl` for this.

So that we don't have to pass the namespace we are working in with every command from now on, we can tell kubectl
the new default namespace:

```shell
kubectl config set-context --current --namespace=nextcloud
```

Your task now is to create a Kubernetes manifest that provides a MariaDB database. The manifest
should consist of two parts: a StatefulSet that configures and provides the MariaDB database, and a
Service that enables access to the database.

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

  - Define a volume mount that ensures the database data is stored in the directory `/var/lib/mysql`.
  - Create a VolumeClaimTemplate that requests a persistent volume with a size of `10Gi` and ensures
    that it can only be written by one node at a time (AccessMode: `ReadWriteOnce`).

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
- Define a port through which the database service can be reached (port `3306`).

## Finish the manifest

Make sure the manifest is syntactically correct and meets the requirements listed above.

The result should be a YAML document describing the configuration of a StatefulSet and its accompanying
Service. Apply the manifest and then check whether the StatefulSet is running as expected.

## Verify the result

Start a debug pod and check whether the service is reachable and returns an IP for the pod.

```yaml
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
#/ nslookup nextcloud-db.nextcloud.svc.cluster.local
```

Good luck!
