# Nextcloud Stage 2: PhpMyAdmin

Currently, the database is only accessible **inside the cluster** via a Headless Service. While this is **best practice** in production, we will deploy **PhpMyAdmin** to test and verify the database functionality.

Your task is to **create a Kubernetes manifest** that provisions an instance of **phpMyAdmin**. This application will be used to manage the MariaDB database set up for the Nextcloud instance. The manifest must consist of two parts: a **Deployment** that configures and provides the phpMyAdmin application, and a **Service** that enables external access to phpMyAdmin via a specific port.

-----

## Deployment Creation

* Define a **Deployment** named **`phpmyadmin`** in the **`nextcloud`** Namespace.
* Set the number of **replicas** to **`1`**.
* Create a container template for phpMyAdmin using the image **`phpmyadmin:5.2.1`**.
* Set the container port to **`80`**.
* Add the following **Environment Variables**:

<!-- end list -->

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

* Define **Resource Requests and Limits** for the phpMyAdmin container:
    * **Limits**:
        * CPU: **`500m`** (500 millicores)
        * Memory: **`512Mi`** (512 Megabytes)
    * **Requests**:
        * CPU: **`100m`** (100 millicores)
        * Memory: **`100Mi`** (100 Megabytes)

-----

## Service Creation

* Define a **Service** named **`phpmyadmin`** in the **`nextcloud`** Namespace.
* Set the Service port to **`80`**.
* Set **`targetPort`** to **`80`** to correctly forward traffic to the container port.
* Set the Service type to **`NodePort`** to enable access to phpMyAdmin from outside the Kubernetes cluster.

-----

## Execution and Verification

**Apply the completed manifest.**
Use `kubectl` to confirm that the **Deployment and Service** have been successfully created.

Now, tunnel to PhpMyAdmin by executing:

```shell
minikube service phpmyadmin -n nextcloud
```

You should now see the PhpMyAdmin interface in your browser, connected to the database.
