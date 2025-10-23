# Autoscaling with the HPA

This example introduces a new concept and resource: **Autoscaling** using the **`HorizontalPodAutoscaler` (HPA)**. For the HPA to work, we must first enable the **Metrics Server** in Minikube:

```shell
minikube addons enable metrics-server
```

The HPA requires the metrics provided by the Metrics Server to decide when to scale.

Next, you can apply the [Manifest](./manifest.yaml) to create an **NGINX ReplicaSet** including a **Service**:

```shell
kubectl apply -f manifest.yaml
```

This alone isn't enough for autoscaling. We now need the HPA resource. Create a new file and insert the following resource:

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

Afterwards, apply your manifest containing the HPA using `kubectl apply`.

You can see that the HPA is directly bound to the ReplicaSet using **`scaleTargetRef`**. Note that labels are *not* used here, which is an exception.
**`targetCPUUtilizationPercentage: 30`** defines that the average CPU utilization should be kept at **30%**.

It may take some time for the HPA to function correctly, depending on how long the Metrics Server needs to collect CPU metrics.

To check if the HPA is ready, run the following command:

```shell
kubectl get hpa
```

It's important that **TARGETS** does **not** show "unknown," but displays two percentage values:

```shell
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   0%/30%    3         10        3          2m24s
```

If this is not yet the case, the Metrics Server is not ready. This can indeed take several minutes.

## Load Test

We will now put the autoscaling to the test and verify that it actually works. The best way to do this is to open **two PowerShell sessions**:

* In the first session, run the command **`kubectl get hpa -w`**. This allows you to continuously observe how many Pods are running.
* In the second window, run a load test:

<!-- end list -->

```shell
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
```

Now, **observe the HPA statistics** in the first window. Over time, the **CPU utilization will rise**, and eventually, the **Replica count will increase**.

```shell
~ ❯❯❯ k get hpa -w
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   1%/50%    1         10        1          12m
nginx-hpa   ReplicaSet/nginx-replicaset   17%/50%   1         10        1          13m
nginx-hpa   ReplicaSet/nginx-replicaset   41%/50%   1         10        1          14m
nginx-hpa   ReplicaSet/nginx-replicaset   40%/50%   1         10        1          15m
nginx-hpa   ReplicaSet/nginx-replicaset   42%/50%   1         10        1          16m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        1          17m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        2          18m
```
