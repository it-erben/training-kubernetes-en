# Nextcloud Stage 2: phpMyAdmin

Right now, the database is only reachable inside the cluster through a headless service. In
production, that's actually _best practice_. But we'd like to check that the database works,
so we'll deploy phpMyAdmin.

Your task is to write a Kubernetes manifest that runs an instance of phpMyAdmin, which we'll
use to manage the MariaDB database behind our Nextcloud. The manifest has two parts: a
Deployment that configures and runs phpMyAdmin, and a Service that makes it reachable on a
specific port.

## Create the Deployment

> **Docs:**
>
> - [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
> - [Resource Requests & Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

- Define a Deployment with the name `phpmyadmin` in the namespace `nextcloud`.
- Set the number of replicas to `1`, since we only need one instance of phpMyAdmin.
- Create a container template for phpMyAdmin that uses the image `phpmyadmin:5.2.1`.
- Set the container port to `80`, since phpMyAdmin should be reachable on this port.
- Add environment variables:

```yaml
env:
  - name: PMA_HOST
    value: nextcloud-db
  - name: PMA_PORT
    value: "3306"
  - name: PMA_USER
    value: "nextcloud"
  - name: PMA_PASSWORD
    value: "nextcloudpassword"
```

- Define resource requests and limits for the phpMyAdmin container:
  - **Limits**:
    - CPU: `500m` (500 millicores)
    - Memory: `512Mi` (512 megabytes)
  - **Requests**:
    - CPU: `500m` (500 millicores)
    - Memory: `512Mi` (512 megabytes)

## Create the Service

> **Docs:**
>
> - [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
> - [Service type NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

- Define a Service with the name `phpmyadmin` in the namespace `nextcloud`.
- Set the port to `80` so the phpMyAdmin service is available there.
- Set `targetPort` to `80` so the service forwards traffic to the right container port.
- Set the service type to `NodePort` so phpMyAdmin can be reached from outside the Kubernetes
  cluster.

Apply the manifest and check with kubectl that the Deployment and Service were created. Then
tunnel to phpMyAdmin by running

```shell
minikube service phpmyadmin -n nextcloud
```

Your browser should now show phpMyAdmin, connected to the database.
