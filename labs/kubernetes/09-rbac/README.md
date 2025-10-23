# RBAC with Pods

In this exercise, you will learn how to grant a Pod a right it normally lacks using a ServiceAccount: querying other Pods via the Kubernetes API.

-----

## 1\) Create the First Pod

Look at the [Manifest for the first Pod](./pod1.yaml). The Pod defines a container whose image includes `kubectl`. Now, apply the manifest:

```shell
kubectl apply -f pod1.yaml
```

A new Pod named "kubectl-pod" should now be running in the default namespace:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# kubectl-pod   1/1     Running     0          52s
```

Now let's try to see if this Pod is allowed to query other Pods using `kubectl`. First, establish a connection to the container and open a shell session:

```shell
kubectl exec -it kubectl-pod -- bash
```

Now, within the shell session, try to list the Pods in the default namespace with `kubectl`:

```shell
kubectl get pods
# Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
```

To understand this result, we must remember one thing:
We just executed this command **not** on our training machine, but **inside** the Pod.
By default, `kubectl` inside the Pod has **no rights**—unlike on the training machine, where Minikube has configured us as an administrator.
Since `kubectl` inside the Pod has no rights, it cannot list any Pods.

Now, disconnect by typing `exit` and delete the Pod:

```shell
kubectl delete pod kubectl-pod
```

-----

## 2\) Create Service Account, Role, and RoleBinding

For the Pod to gain access, it needs a **ServiceAccount**. This account must be granted the right to list Pods using a **Role**.

To do this, look at [the following Manifest](./sa.yaml).
First, a **ServiceAccount** is created.

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

It allows the listing and getting of Pods in the default namespace, as no other namespace is specified.

The **RoleBinding** connects the Role to the ServiceAccount.

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

If you have understood all the parts, now apply the manifest:

```shell
kubectl apply -f sa.yaml
```

-----

## 3\) Start Pod with Service Account

In [pod2.yaml](./pod2.yaml), you will find a manifest for the same Pod as in Step 1—only this time it uses the ServiceAccount we created in Step 2:

```yaml
spec:
  serviceAccountName: my-kubectl-sa
  containers:
    - name: kubectl-container
      image: bitnami/kubectl:latest
      command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
  restartPolicy: Always
```

Now, apply the manifest and then connect to the Pod again:

```shell
kubectl apply -f pod2.yaml
kubectl exec -it kubectl-pod -- bash
```

In the shell session, execute `kubectl` again to list all Pods. It should now work:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# busybox       0/1     Completed   0          21h
# busybox2      0/1     Error       0          21h
# kubectl-pod   1/1     Running     0          52s
```

-----

## Cleanup

Finally, delete the test Pod:

```shell
kubectl delete pod kubectl-pod
```
