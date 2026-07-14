# Nextcloud

The last and most important component still missing is Nextcloud itself.

In [nextcloud.yaml](nextcloud.yaml), I have provided a ready-made Deployment for you. But since you are
a bit more advanced by now, something is still missing! The Deployment does not use a PersistentVolume. After an update,
all data would be gone!

> **Docs:**
>
> - [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
> - [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
> - [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
> - [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

**`nextcloud.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextcloud
  namespace: nextcloud
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nextcloud
  template:
    metadata:
      labels:
        app: nextcloud
    spec:
      containers:
        - name: nextcloud
          image: nextcloud:30
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
          livenessProbe:
            exec:
              command: ["sh", "-c", "true"]
            initialDelaySeconds: 60
            periodSeconds: 20
          env:
            - name: MYSQL_HOST
              value: "nextcloud-db"
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: nextcloud-db-secret
                  key: MYSQL_DATABASE
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
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

So we need to take care of requesting and mounting a PersistentVolume. First, you need a
PersistentVolumeClaim:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nextcloud-pvc
  namespace: nextcloud
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Now add the claim in the right place in the manifest:

```yaml
volumes:
  - name: nextcloud-data
    persistentVolumeClaim:
      claimName: nextcloud-pvc
```

Finally, you still need to mount the resulting volume:

```yaml
volumeMounts:
  - name: nextcloud-data
    mountPath: /var/www/html
```

Where exactly these snippets need to go is for you to figure out. The documentation can help you
with that – or yesterday's exercise on volumes.

Once you are done, a Service is still missing to expose Nextcloud to the outside. Use the
"PhpMyAdmin" service as a template and adjust the names and labels so that they match the Nextcloud Deployment.

When everything is ready, you can apply the file with kubectl and then use minikube to open a tunnel to your
service to test Nextcloud.

Good luck!
