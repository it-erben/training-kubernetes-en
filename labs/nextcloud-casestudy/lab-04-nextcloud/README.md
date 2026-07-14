# Nextcloud

The last missing piece – and the most important one – is Nextcloud itself.

In [nextcloud.yaml](nextcloud.yaml), I've provided a ready-made Deployment for you. But you're a
bit more advanced by now, so there's a catch: the Deployment doesn't use a PersistentVolume.
After an update, all your data would be gone!

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

So we need to request and mount a PersistentVolume ourselves. First, you need a
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

Finally, mount the resulting volume:

```yaml
volumeMounts:
  - name: nextcloud-data
    mountPath: /var/www/html
```

Where exactly these snippets go is for you to figure out. The documentation can help – or
yesterday's exercise on volumes.

Once that's done, you still need a Service to expose Nextcloud to the outside world. Use the
phpMyAdmin Service as a template and adjust the names and labels to match the Nextcloud
Deployment.

When everything is in place, apply the file with kubectl, open a minikube tunnel to your
service, and give Nextcloud a try.

Good luck!
