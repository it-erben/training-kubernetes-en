# Lab 05: ReplicaSet

This example illustrates the role ReplicaSets play in Kubernetes. The resource we will look at is
defined in [manifest.yaml](manifest.yaml). Again, please remember to change into the correct
directory with PowerShell.

**`manifest.yaml`:**

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: replicaset-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: replicaset-demo
  template:
    metadata:
      labels:
        app: replicaset-demo
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: deployment-recreate-demo
      containers:
        - name: nginx
          image: nginx:1.29.4
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
```

Follow these steps to start the demo:

Create the ReplicaSet using the manifest:

```sh
kubectl apply -f manifest.yaml
```

The manifest contains a `ReplicaSet` of three NGINX pods. Make sure all pods were created correctly:

```sh
kubectl get pods --selector=app=replicaset-demo
```

This command works as-is because all pods carry the label `app=replicaset-demo`. If you are not
sure why that is, take another look at the manifest. You will find the label in the template there.

Now delete a pod:

```sh
kubectl delete pod <POD_NAME>
```

Check the pod list again.

```sh
kubectl get pods --selector=app=replicaset-demo
```

The ReplicaSet should have created a third pod again by now. If not, you may need to wait a few
seconds.

## Cleaning up

```shell
kubectl delete replicaset.apps/replicaset-demo
```

## Bonus

- [Documentation on ReplicaSets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
