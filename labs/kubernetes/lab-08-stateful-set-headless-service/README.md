# Lab 08: NGINX StatefulSet with Headless Service

The [manifest](manifest.yaml) creates a `StatefulSet` with three replicas of an `nginx` pod occupying container port 80.
It also defines a `Service` running in so-called headless mode. This means it does not receive a
ClusterIP (`clusterIP: None`). Let's now take a look at what exactly this means.

**`manifest.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
  labels:
    app: nginx
spec:
  clusterIP: None
  selector:
    app: nginx # Binds the service to the pods created by the StatefulSet
  ports:
    - port: 80
      name: http

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx
spec:
  serviceName: "nginx-headless"
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx # Creates the labels the StatefulSet and the service need to select the pods
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: nginx
      containers:
        - name: nginx
          image: nginx:1.29.4
          ports:
            - containerPort: 80
              name: http
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

## Applying the manifest

First we create the required resources and check that they were created correctly.

```shell
kubectl apply -f manifest.yaml
```

Then we check whether the service and pods were created and started successfully.

```shell
kubectl get service nginx-headless
```

```shell
kubectl get pod --selector=app=nginx
```

## Investigating DNS with busybox

We use `kubectl debug` to start a helper container. We inspect the first pod of the StatefulSet,
`nginx-0`, and use [busybox](https://github.com/mirror/busybox), an image for debugging network problems.

```shell
kubectl debug nginx-0 -it --image=busybox
```

The DNS name of the service we created is `nginx-headless.default.svc.cluster.local`, and we will see
that it points to three IP addresses: one per pod. The service itself has _no_ ClusterIP! Only the pods have
an IP, as they always do (well, almost always...).

```shell
nslookup nginx-headless.default.svc.cluster.local
```

```shell
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.65
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.66
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.64
```

In addition, the headless service creates one DNS name per pod with a running index:

```text
<STATEFULSETNAME>-<INDEX>.<SERVICENAME>.<NAMESPACE>.svc.cluster.local
```

so for example

```text
nginx-0.nginx-headless.default.svc.cluster.local
```

And we can verify this with nslookup as well

```shell
nslookup nginx-0.nginx-headless.default.svc.cluster.local
```

```Server: 10.96.0.10
Address:        10.96.0.10:53


Name:   nginx-0.nginx-headless.default.svc.cluster.local
Address: 10.244.0.64 # here is the pod's address!
```

## Cleaning up

```shell
kubectl delete statefulset.apps/nginx
kubectl delete service/nginx-headless
```

## Bonus

-[Documentation on StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
