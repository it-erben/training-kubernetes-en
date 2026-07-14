# Lab 19: Autoscaling with the HPA

This exercise introduces a new concept and a new resource: autoscaling with the
`HorizontalPodAutoscaler`, or HPA for short. For the HPA to do its job, we first need to enable
the metrics-server in Minikube:

```shell
minikube addons enable metrics-server
```

Then create the following resources:

- A `ReplicaSet` with 3 replicas. Please use `nginx:latest` as the image. Make sure the port setting
  is correct.
- A matching `Service` of type `ClusterIP` named `nginx-service`.

Then add the following entry to the nginx container in the `ReplicaSet`. The comments above and below
just show where this snippet belongs.

```yaml
# image: nginx:latest
resources:
  requests:
    cpu: "100m"
  limits:
    cpu: "100m"
# ports: ...
```

Then apply your manifest using `kubectl apply`.

For autoscaling, we still need the HPA resource. Create a new file and add this resource:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: ReplicaSet
    name: # Enter the name here
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 30
```

Enter the correct name of your `ReplicaSet`!

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
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
```

Watch the HPA stats in the first window: CPU utilization climbs over time, and eventually the
replica count follows.

```shell
~ ❯❯❯ k get hpa -w
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   1%/30%    1         10        1          12m
nginx-hpa   ReplicaSet/nginx-replicaset   17%/30%   1         10        1          13m
nginx-hpa   ReplicaSet/nginx-replicaset   41%/30%   1         10        1          14m
nginx-hpa   ReplicaSet/nginx-replicaset   40%/30%   1         10        1          15m
nginx-hpa   ReplicaSet/nginx-replicaset   42%/30%   1         10        1          16m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/30%   1         10        1          17m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/30%   1         10        2          18m
```
