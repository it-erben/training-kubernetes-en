# Lab 02: Persistent Storage in AKS

For this lab, create a cluster as in Lab 01 and set the environment variables described there.

## Part 1: Explore the existing StorageClasses

List all available `StorageClasses` in your AKS cluster:

```bash
kubectl get storageclasses
```

Examine the details of the Disk and Files `StorageClasses`:

```bash
kubectl describe storageclass managed-csi
kubectl describe storageclass azurefile-csi
```

The fields worth a closer look on `StorageClasses` are the `VolumeBindingMode` and the
`ReclaimPolicy`. The first determines whether a `PersistentVolume` is created for a
`PersistentVolumeClaim` even while nobody is using it. The second controls when the PV
is deleted.

To illustrate this, create a file `pvc-disk.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azure-disk
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 5Gi
```

Apply the manifest and check the status:

```bash
kubectl apply -f pvc-disk.yaml
kubectl get pvc pvc-azure-disk -w
```

**Question:** Why is the PVC stuck in "Pending"? (Hint: `VolumeBindingMode`)

---

## Part 2: StatefulSet with an Azure Disk volume

In this task, we'll create a `StatefulSet` that exposes an NGINX web server via a
`LoadBalancer`. The web server's files are stored on an Azure Disk.

```yaml
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
  type: LoadBalancer
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-statefulset
spec:
  serviceName: my-service
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
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
  volumeClaimTemplates:
    - metadata:
        name: my-volume
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
```

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
      persistent volume.
    </p>
  </body>
</html>
```

Now copy the `index.html` in this directory into the pod:

```bash
kubectl cp index.html my-statefulset-0:/usr/share/nginx/html/index.html -c my-container
```

Now look up the LoadBalancer's external IP with `kubectl` and open it.
You should see the HTML page above.

But what happens when we delete the pod?

```bash
kubectl delete pod my-statefulset-0
```

Our application will be unreachable for a moment. But what happens once the pod is
recreated? Is the HTML page still the same?

_Spoiler:_ It is. The `StatefulSet` automatically recreates the pod and reattaches the
`PersistentVolumeClaim`.

---

## Part 3: PVC with Azure Files (shared storage)

Create a file `pvc-files.yaml` with `ReadWriteMany` as the access mode:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azure-files
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 5Gi
```

Also create a Deployment with 3 replicas that all use the same volume
(`deploy-files.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: files-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: files-demo
  template:
    metadata:
      labels:
        app: files-demo
    spec:
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
            claimName: pvc-azure-files
---
apiVersion: v1
kind: Service
metadata:
  name: files-demo
  labels:
    app: files-demo
spec:
  type: LoadBalancer
  selector:
    app: files-demo
  ports:
    - name: http
      port: 80
      targetPort: 80

```

Apply the manifests and grab the name of any pod in the `Deployment`:

```yaml
kubectl apply -f pvc-files.yaml
kubectl apply -f deploy-files.yaml
kubectl get pods -l app=files-demo
```

Now copy the HTML file into the volume again:

```bash
kubectl cp index.html REPLACE_WITH_POD_NAME:/usr/share/nginx/html/index.html -c my-container
```

Deploy and test the shared access. No matter how often you delete pods and have them
recreated, access to the Azure Files volume should keep working.

## Bonus

Try to find the newly created file share in the Azure Portal and open your file there.
Once you've found it, edit it and watch live as your NGINX serves a different response.
