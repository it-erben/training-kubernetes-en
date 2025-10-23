# Pod Security Standards

In this example, we will test the rules you learned in the course regarding **Pod Security Standards (PSS)**.

-----

## 1\) Create the Namespace

The Namespace defined in [ns.yaml](ns.yaml) includes configurations for **warning** and **blocking** Pods based on Pod Security Standards.

* Pods are allowed to claim rights up to the **`baseline`** policy level. Specifically, they **must not request privileged access**.
* A **warning** will be generated if Pods request rights that exceed the **`restricted`** policy level. The cluster administrator can view these warnings.

<!-- end list -->

```shell
kubectl apply -f ns.yaml
```

-----

## 2\) Create a Pod that Triggers a Warning

The Pod in [warn-pod.yaml](./warn-pod.yaml) does not request any rights that would violate the **`baseline`** policy.
However, one of its containers runs as the **`root` user** (UID 0), which exceeds the **`restricted`** policy. This generates a warning.
When we apply this Pod, the API server acknowledges the action with a warning but allows the Pod to be created:

```shell
kubectl apply -f warn-pod.yaml
# Warning: would violate PodSecurity "restricted:latest": unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "nginx" must not set runAsUser=0), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# pod/warning-pod created
```

-----

## 3\) Create a Pod that is Blocked

The Pod in [error-pod.yaml](./error-pod.yaml) contains a setting that **violates the `baseline` policy**: It requests the **`privileged` mode**, granting it extensive access to the host.
The Namespace we created above is configured to **reject** such Pods. Let's test this:

```shell
kubectl apply -f error-pod.yaml
# Error from server (Forbidden): error when creating "error-pod.yaml": pods "blocked-pod" is forbidden: violates PodSecurity "baseline:latest": privileged (container "privileged-container" must not set securityContext.privileged=true)
```

The API server **rejects** this manifest because it violates the **Pod Security Standards** enforced on the Namespace.

-----

## Cleanup

```shell
kubectl delete all --all -n my-secure-namespace
kubectl delete ns my-secure-namespace
```
