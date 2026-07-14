# Lab 09: Persistent Volumes

The following exercise is meant to help you gain a basic understanding of volumes in Kubernetes (k8s). In
this exercise you will create an application that runs in a pod and uses persistent storage in the form
of a volume.

## Create the k8s resources

**`manifest.yaml`:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
---
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: my-app
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: my-container
      image: nginx:1.29.4
      ports:
        - containerPort: 80
      readinessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 10
        periodSeconds: 20
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: my-volume
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  volumes:
    - name: my-volume
      persistentVolumeClaim:
        claimName: my-claim
```

As in the previous examples, you can create all the resources needed for this exercise via the manifest.yaml:

```shell
kubectl apply -f manifest.yaml
```

This creates a pod with NGINX, a service of type `NodePort` that makes this pod available on port 30080 on the host,
and a `PersistentVolumeClaim` with which the pod will request a `PersistentVolume`.

Use the following commands to check the status of your Kubernetes resources:

```sh
kubectl get pv,pvc
kubectl get pods
```

Typical example output:

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

If you get similar output and the pod has the status `running`, you can continue. This can take a while!

## Create an `index.html` file on your local machine

You can also use the index.html file located in this directory.

**`index.html`:**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>My personal website</title>
  </head>
  <body>
    <h1>Hello, this is my personal website!</h1>
    <p>
      Welcome to my website, running in a Kubernetes pod with a
      Persistent Volume.
    </p>
  </body>
</html>
```

## Copy the `index.html` file into the nginx container

```sh
kubectl cp index.html my-pod:/usr/share/nginx/html/index.html -c my-container
```

In this command, replace `index.html` with the path to the file on your local machine. `my-pod` is the name of the
pod the file should be copied into, and `my-container` is the name of the container inside the pod (here it is
the nginx container). The target folder `/usr/share/nginx/html/index.html` is the location inside the container
defined in the `pod.yaml`.

### Verify that the `index.html` file was transferred successfully

#### For Minikube

When using minikube, we unfortunately cannot simply access the service via <http://localhost:30080>, even though
we defined this port in the service as a `NodePort`. So we run:

```shell
minikube service my-service
```

The browser should now show the web page we created above.

#### For Azure Kubernetes Service (AKS)

Start a load balancer service on your cluster to reach the pod:

**`aks-lb.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  labels:
    app: my-app
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
    - name: http
      port: 80
      targetPort: 80
```

```bash
kubectl apply -f aks-lb.yaml
```

Then retrieve the external IP of the load balancer service to reach NGINX:

```bash
kubectl get svc my-service -o wide 
```

## Deleting and recreating the pod

Now delete the pod my-pod and apply the manifest again so the pod is recreated. Then start the
service tunnel again and check whether the web page still appears.

```shell
kubectl delete pod my-pod
kubectl apply -f manifest.yaml
minikube service my-service
```

To understand why this is the case, you can take a look at the PersistentVolumes. Delete the pod once more and
display whether the PV still exists:

```shell
kubectl delete pod my-pod
kubectl get pv
```

## Cleaning up

To completely remove the created resources, this time we take the easy route:

```shell
minikube delete
minikube start
```

This deletes the cluster entirely and sets it up again.
