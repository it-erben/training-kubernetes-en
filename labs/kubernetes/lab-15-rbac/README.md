# Lab 15: RBAC with Pods

In this exercise you will learn how to use a ServiceAccount to grant a pod a permission it normally does not
have: querying other pods via the Kubernetes API.

## 1) Create the Pod

Take a look at the [manifest for the first pod](./pod1.yaml). The pod defines a container whose image contains
kubectl. Now apply the manifest:

**`pod1.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubectl-pod
  namespace: default
spec:
  containers:
    - name: kubectl-container
      image: bitnami/kubectl:latest
      command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
      readinessProbe:
        exec:
          command: ["/bin/sh", "-c", "true"]
        initialDelaySeconds: 1
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["/bin/sh", "-c", "true"]
        initialDelaySeconds: 5
        periodSeconds: 20
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  restartPolicy: Always
```

```shell
kubectl apply -f pod1.yaml
```

There should now be a new pod named "kubectl-pod" running in the default namespace:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# kubectl-pod   1/1     Running     0          52s
```

Let's now check whether this pod is allowed to query the other pods via kubectl. To do that, we first
connect to the container and open a shell session:

```shell
kubectl exec -it kubectl-pod -- bash
```

Now, inside the shell session, we try to list the pods in the default namespace with kubectl:

```shell
kubectl get pods
# Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
```

To understand this result, we need to remind ourselves of one thing: we just ran this command **not**
on our training machine, but **inside** the pod. By default, kubectl inside the pod has
no permissions at all – unlike on the training machine, where Minikube configured us as admin. Since kubectl inside
the pod has no permissions, it cannot list any pods either.

Now disconnect with `exit` and delete the pod:

```shell
kubectl delete pod kubectl-pod
```

## 2) Create the Service Account, Role, and RoleBinding

For the pod to get access, it needs a ServiceAccount. This account must be granted the permission to
list pods by means of a role.

Take a look at [the following manifest](./sa.yaml).

**`sa.yaml`:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-kubectl-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
  - kind: ServiceAccount
    name: my-kubectl-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

First, a **ServiceAccount** is created there.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-kubectl-sa
```

The more interesting part, however, is the **Role**.

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

It allows listing pods in the default namespace, since no other namespace is specified. The **RoleBinding**
connects the role to the ServiceAccount.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
  - kind: ServiceAccount
    name: my-kubectl-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Once you have understood all the parts, apply the manifest:

```shell
kubectl apply -f sa.yaml
```

## 3) Start the Pod with the Service Account

In [pod2.yaml](./pod2.yaml) you will find a manifest for the same pod as in step 1 -- except that this time it
uses the ServiceAccount we created in step 2:

**`pod2.yaml`:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-kubectl-sa
  namespace: default
---
apiVersion: v1
kind: Pod
metadata:
  name: kubectl-pod
  namespace: default
spec:
  serviceAccountName: my-kubectl-sa
  containers:
    - name: kubectl-container
      image: bitnami/kubectl:latest
      command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
      readinessProbe:
        exec:
          command: ["/bin/sh", "-c", "true"]
        initialDelaySeconds: 1
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["/bin/sh", "-c", "true"]
        initialDelaySeconds: 5
        periodSeconds: 20
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  restartPolicy: Always
```

An excerpt from it:

```yaml
spec:
  serviceAccountName: my-kubectl-sa
  containers:
    - name: kubectl-container
      image: bitnami/kubectl:latest
      command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
  restartPolicy: Always
```

Now apply the manifest and connect to the pod again:

```shell
kubectl apply -f pod2.yaml
kubectl exec -it kubectl-pod -- bash
```

In the shell session, run kubectl again to list all pods. It should work now:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# busybox       0/1     Completed   0          21h
# busybox2      0/1     Error       0          21h
# kubectl-pod   1/1     Running     0          52s
```

## Cleanup

Finally, delete the test pod:

```shell
kubectl delete pod kubectl-pod
```
