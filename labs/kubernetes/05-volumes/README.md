# Persistent Volumes

This exercise is designed to help you gain a fundamental understanding of **Volumes** in Kubernetes (k8s). In this exercise, you will create an application running in a Pod that uses **persistent storage** in the form of a Volume.

**Create the k8s Resources**

As in previous examples, you can create all the necessary resources for this exercise using the `manifest.yaml`:

```shell
kubectl apply -f manifest.yaml
```

This command creates an **NGINX Pod**, a **`NodePort` Service** that makes the Pod available on the host via port 30080, and a **`PersistentVolumeClaim` (PVC)** which the Pod will use to request a **`PersistentVolume` (PV)**.

Use the following commands to check the status of your Kubernetes resources:

```sh
kubectl get pv,pvc
kubectl get pods
```

Typical example outputs:

```sh
# kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
persistentvolume/pvc-60108e64-6d15-11ec-af1d-0242ac110002   1Gi        RWO           Delete          Bound    default/my-claim  standard                2m

NAME                     STATUS   VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS   AGE
persistentvolumeclaim/my-claim   Bound    pvc-60108e64-6d15-11ec-af1d-0242ac110002   1Gi        RWO            standard       2m

# kubectl get pods
NAME     READY   STATUS    RESTARTS   AGE
my-pod    1/1     Running   0          1m
```

If you receive a similar output and the Pod is in the **`Running`** status, you can proceed. **This may take a moment\!**

**Create an `index.html` file on your local machine**

You can also use the `index.html` file provided in this directory.

```html
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <title>Meine persönliche Webseite</title>
  </head>
  <body>
    <h1>Hallo, das ist meine persönliche Webseite!</h1>
    <p>
      Willkommen auf meiner Webseite, die in einem Kubernetes-Pod mit einem
      Persistent Volume läuft.
    </p>
  </body>
</html>
```

**Copy the `index.html` file into the NGINX container**:

```sh
kubectl cp index.html my-pod:/usr/share/nginx/html/index.html -c my-container
```

In this command, replace `index.html` with the path to the file on your local machine. `my-pod` is the name of the Pod where the file should be copied, and `my-container` is the name of the container within the Pod (here, it's the NGINX container). The destination path `/usr/share/nginx/html/index.html` is the location defined in the `pod.yaml` within the container.

**Verify that the `index.html` file was transferred successfully**

Since we are using **minikube**, we cannot simply access the Service via `http://localhost:30080`, even though we defined this port as a `NodePort` in the Service. Therefore, we execute:

```shell
minikube service my-service
```

The web page you created above should now appear in your browser.

## Delete and Recreate the Pod

Now, **delete the Pod `my-pod`** and **re-apply the manifest** to recreate the Pod. Then, start the Service tunnel again and check if the web page still appears.

```shell
kubectl delete pod my-pod
kubectl apply -f manifest.yaml
minikube service my-service
```

To understand why this works, you can inspect the **PersistentVolumes**. Delete the Pod once more and check if the PV still exists:

```shell
kubectl delete pod my-pod
kubectl get pv
```

## Cleanup

To completely remove the created resources, we will take the easy route this time:

```shell
minikube delete
minikube start
```

This will completely **delete and reset the entire cluster**.
