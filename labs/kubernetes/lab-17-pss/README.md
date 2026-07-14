# Lab 17: Pod Security Standards

In this example we want to test the rules you got to know in the course for ourselves.

## 1) Create the Namespace

The namespace in [ns.yaml](ns.yaml) contains configurations for warning about and blocking pods based on Pod Security
Standards. Pods may at most claim privileges that comply with the `baseline` rule. In particular, this means they
must not request privileged access. A warning is issued when pods request privileges that go beyond the `restricted`
rule. The cluster administrator can view these warnings.

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

The pod in [warn-pod.yaml](./warn-pod.yaml) does not request any privileges that would violate the `baseline` policy.
However, one of its containers runs as the `root` user (uid 0), which puts it beyond the `restricted` policy. This
produces a warning. When we apply this pod, the api-server acknowledges the operation with a warning but lets the pod
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
requests privileged mode, which would give it far-reaching access to the host. The namespace we created
above is configured to reject such pods. Let's test this:

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
