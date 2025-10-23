# Autoscaling with the HPA (Horizontal Pod Autoscaler)

This example introduces the concept and resource for **Autoscaling** using the **`HorizontalPodAutoscaler` (HPA)**.

## Setup and Configuration

First, you must enable the **Metrics Server** in Minikube, as the HPA relies on it for CPU metrics:

```shell
minikube addons enable metrics-server
```

Next, define and apply your manifest file containing the **ReplicaSet** and **Service**. The ReplicaSet must include resource requests for the HPA to work:

1.  **ReplicaSet Creation:**

    * Create a **ReplicaSet** (name it, for example, `nginx-replicaset-for-hpa`).
    * Configure it for **3 replicas**.
    * Use the image **`nginx:latest`** and ensure the container port is correctly set (e.g., `80`).
    * **Crucially**, add resource requests/limits to the NGINX container spec:

    <!-- end list -->

    ```yaml
    # ... inside the container spec
    resources:
      requests:
        cpu: "100m"
      limits:
        cpu: "100m"
    # ...
    ```

2.  **Service Creation:**

    * Create a **Service** of type **`ClusterIP`** named **`nginx-service`** that targets the Pods created by the ReplicaSet.

3.  **Apply the Resource Manifest:**

    ```shell
    kubectl apply -f your-rs-and-svc-manifest.yaml
    ```

## HorizontalPodAutoscaler (HPA)

Now, create a separate YAML file for the **HorizontalPodAutoscaler (HPA)** and insert the following definition. **Replace `# Hier den Namen eintragen` with the actual name of your ReplicaSet.**

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: ReplicaSet
    name: nginx-replicaset-for-hpa # <--- Insert your ReplicaSet Name here
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 30
```

Apply the HPA manifest:

```shell
kubectl apply -f your-hpa-manifest.yaml
```

The HPA is now bound to the ReplicaSet via **`scaleTargetRef`** (no labels are used for the HPA itself). The target is set to maintain an average CPU utilization of **30%**.

## Verify HPA Status

It may take several minutes for the Metrics Server to start collecting CPU metrics. Once it's ready, the HPA will begin working.

Check the HPA status using:

```shell
kubectl get hpa
```

The **TARGETS** field must show two percentage values (e.g., `0%/30%`) instead of "unknown" to confirm the Metrics Server is ready:

```shell
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   0%/30%    3         10        3          2m24s
```

## Load Test and Autoscaling Verification

To test whether autoscaling functions, open **two terminal sessions**:

1.  **Session 1 (Monitor HPA):** Continuously monitor the HPA statistics to see the CPU utilization and replica count change:

    ```shell
    kubectl get hpa -w
    ```

2.  **Session 2 (Run Load Test):** Start a continuous load against the Service using a temporary Pod:

    ```shell
    kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
    ```

Observe the HPA statistics in the first session. The CPU utilization should rise, triggering the HPA to increase the replica count (scale out):

```shell
~ ❯❯❯ k get hpa -w
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
# ... CPU utilization rises above 30% ...
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        1          17m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        2          18m # <--- Replicas scaled up
```
