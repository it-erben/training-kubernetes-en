# Lab 17: Pod Security Standards

In this exercise we'll try out the rules covered in the course for ourselves.

## 1) Create the Namespace

The namespace in [ns.yaml](ns.yaml) is configured to warn about and block pods based on Pod Security
Standards. Pods can claim at most the privileges that the `baseline` rule allows – in particular, they
must not request privileged access. Pods that request privileges beyond the `restricted` rule trigger a
warning, which the cluster administrator can see.

**`ns.yaml`:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: "baseline"
    pod-security.kubernetes.io/enforce-version: "latest"
    pod-security.kubernetes.io/warn: "restricted"
    pod-security.kubernetes.io/warn-version: "latest"
```

```shell
kubectl apply -f ns.yaml
```

## 2) Create a Pod That Triggers a Warning

The pod in [warn-pod.yaml](./warn-pod.yaml) doesn't request anything that would violate the `baseline` policy.
One of its containers runs as the `root` user (uid 0), though, which puts it beyond the `restricted` policy
and produces a warning. When we apply this pod, the api-server responds with a warning but lets the pod
through:

**`warn-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: warning-pod
  namespace: my-secure-namespace
spec:
  containers:
    - name: nginx
      image: nginx:1.29.4
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
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
```

```shell
kubectl apply -f warn-pod.yaml
# Warning: would violate PodSecurity "restricted:latest": unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "nginx" must not set runAsUser=0), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# pod/warning-pod created
```

## 3) Create a Pod That Gets Blocked

The pod in [error-pod.yaml](./error-pod.yaml) contains a setting that violates the `baseline` policy: it
requests privileged mode, which would give it sweeping access to the host. The namespace we created above
is configured to reject pods like this. Let's put that to the test:

**`error-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: blocked-pod
  namespace: my-secure-namespace
spec:
  containers:
    - name: privileged-container
      image: alpine:3.20.2
      readinessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 1
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 5
        periodSeconds: 20
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
```

```shell
kubectl apply -f error-pod.yaml
# Error from server (Forbidden): error when creating "error-pod.yaml": pods "blocked-pod" is forbidden: violates PodSecurity "baseline:latest": privileged (container "privileged-container" must not set securityContext.privileged=true)
```

The api-server rejects this manifest because it violates the namespace's Pod Security Standards.

## Cleanup

```shell
kubectl delete all --all -n my-secure-namespace
kubectl delete ns my-secure-namespace
```
