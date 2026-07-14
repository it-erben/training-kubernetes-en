# Lab 18: Autoscaling with the HPA

In this example we introduce a new concept and a new resource: autoscaling with the
`HorizontalPodAutoscaler`, also known as HPA. For the HPA to do its job, we first need to enable
the metrics-server in Minikube:

```shell
minikube addons enable metrics-server
```

The HPA needs the metrics provided by the metrics-server to decide when it has to scale.

Afterwards, you can apply the [manifest](./manifest.yaml) to create an NGINX ReplicaSet including a Service:

**`manifest.yaml`:**

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.4
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "100m"
              memory: "256Mi"
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
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

```shell
kubectl apply -f manifest.yaml
```

But that alone is not enough for autoscaling. We still need the HPA resource. Create a new file and
add this resource:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: ReplicaSet
    name: nginx-replicaset
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 30
```

Then apply your manifest with the HPA using `kubectl apply`.

You can see that the HPA is bound directly to the ReplicaSet via `scaleTargetRef`. For once, no labels
are used here. `targetCPUUtilizationPercentage` defines that the average CPU utilization should be
at 30%.

It may take a while until the HPA does its job correctly – depending on how long the metrics server
needs to collect CPU metrics.

To check whether the HPA is ready, run the following command:

```shell
kubectl get hpa
```

It is important that TARGETS does not show "unknown" but two percentages:

```shell
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   0%/30%    1         10        1          2m24s
```

If that is not yet the case, the metrics-server is not ready yet. This can actually take several
minutes.

## Load Test

Now let's put it to the test and check whether the autoscaling really works. It is best to open
two PowerShell sessions for this:

- In the first session, run the command `kubectl get hpa -w`. This lets you continuously see how many
  pods are running.
- In the second window, we run a load test:

```shell
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.000001; do wget -q -O- http://nginx-service; done"
```

Now watch the HPA statistics in the first window. Over time, the CPU utilization will rise, and eventually
the replica count will rise as well.

```shell
~ ❯❯❯ kubectl get hpa -w
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   1%/30%    1         10        1          12m
nginx-hpa   ReplicaSet/nginx-replicaset   17%/30%   1         10        1          13m
nginx-hpa   ReplicaSet/nginx-replicaset   41%/30%   1         10        1          14m
nginx-hpa   ReplicaSet/nginx-replicaset   40%/30%   1         10        1          15m
nginx-hpa   ReplicaSet/nginx-replicaset   42%/30%   1         10        1          16m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/30%   1         10        1          17m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/30%   1         10        2          18m
```
