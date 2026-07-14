# Lab 18: Autoscaling with the HPA

This exercise introduces a new concept and a new resource: autoscaling with the
`HorizontalPodAutoscaler`, or HPA for short. For the HPA to do its job, we first need to enable
the metrics-server in Minikube:

```shell
minikube addons enable metrics-server
```

The HPA relies on the metrics from the metrics-server to decide when to scale.

Once that's done, apply the [manifest](./manifest.yaml) to create an NGINX ReplicaSet plus a Service:

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

That alone doesn't give us autoscaling yet. We still need the HPA resource. Create a new file and
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

The HPA binds directly to the ReplicaSet via `scaleTargetRef` – for once, no labels involved.
`targetCPUUtilizationPercentage` sets the target average CPU utilization to 30%.

It can take a while for the HPA to kick in, depending on how long the metrics-server needs to
collect CPU metrics.

To check whether the HPA is ready, run:

```shell
kubectl get hpa
```

TARGETS must show two percentages, not "unknown":

```shell
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   0%/30%    1         10        1          2m24s
```

If it doesn't yet, the metrics-server isn't ready. That can genuinely take several minutes.

## Load Test

Now let's see whether the autoscaling actually works. Open two PowerShell sessions for this:

- In the first session, run `kubectl get hpa -w`. This lets you watch live how many pods are
  running.
- In the second session, run a load test:

```shell
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.000001; do wget -q -O- http://nginx-service; done"
```

Watch the HPA stats in the first window: CPU utilization climbs over time, and eventually the
replica count follows.

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
