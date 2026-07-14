# Nextcloud Stage 2: PhpMyAdmin

Currently, the database is only reachable inside the cluster via a headless service. In production, this
is actually _best practice_. But since we want to test whether the database works, we deploy PhpMyAdmin.

Your task is to create a Kubernetes manifest that provides an instance of phpMyAdmin. phpMyAdmin
is used to manage the MariaDB database for a Nextcloud instance. The manifest should consist of two
parts: a Deployment that configures and provides the phpMyAdmin application, and a Service that
enables access to phpMyAdmin on a specific port.

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
- Set the port to `80` to make the phpMyAdmin service available on this port.
- Set `targetPort` to `80` so that the service forwards to the container port correctly.
- Set the service type to `NodePort` to allow access to phpMyAdmin from outside the Kubernetes
  cluster.

Apply the manifest. Now check with kubectl whether the Deployment and Service were created successfully. Then tunnel to
PhpMyAdmin by running

```shell
minikube service phpmyadmin -n nextcloud
```

In your browser, you should now see PhpMyAdmin connected to the database.
