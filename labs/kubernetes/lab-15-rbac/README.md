# Lab 15: RBAC with Pods

In this exercise you'll use a ServiceAccount to give a pod a permission it normally doesn't have:
querying other pods via the Kubernetes API.

## 1) Create the Pod

Take a look at the [manifest for the first pod](./pod1.yaml). It defines a container whose image ships
with kubectl. Apply the manifest:

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

Now let's find out whether this pod is allowed to query the other pods via kubectl. First, connect to
the container and open a shell session:

```shell
kubectl exec -it kubectl-pod -- bash
```

Inside the shell session, try listing the pods in the default namespace with kubectl:

```shell
kubectl get pods
# Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
```

To make sense of this result, keep one thing in mind: we just ran this command **inside** the pod,
**not** on our training machine. By default, kubectl inside the pod has no permissions at all – unlike
on the training machine, where Minikube set us up as admin. And with no permissions, it can't list
any pods either.

Now disconnect with `exit` and delete the pod:

```shell
kubectl delete pod kubectl-pod
```

## 2) Create the Service Account, Role, and RoleBinding

To get access, the pod needs a ServiceAccount, and that account needs a role that grants it permission
to list pods.

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

The manifest starts by creating a **ServiceAccount**.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-kubectl-sa
```

The more interesting part is the **Role**.

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

It allows listing pods in the default namespace – no other namespace is specified. The **RoleBinding**
then ties the role to the ServiceAccount.

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

Once all the parts make sense to you, apply the manifest:

```shell
kubectl apply -f sa.yaml
```

## 3) Start the Pod with the Service Account

[pod2.yaml](./pod2.yaml) contains the same pod as in step 1 – except that this time it uses the
ServiceAccount we created in step 2:

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

Here is the relevant excerpt:

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

In the shell session, run kubectl again to list all pods. This time it should work:

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
