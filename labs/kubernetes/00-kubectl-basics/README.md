# Kubectl basics

To get things started, let's check if `kubectl` is installed and can connect to the cluster.

```shell
kubectl get pods --all-namespaces # should return all pods over all namespaces
```

```shell
kubectl get nodes # will return all active nodes. In case of minikube, it will only be one.
```

```shell
kubectl describe node minikube # will show the details of said node
```

**Please find the answers for the following questions:**

- How many CPU are available to the node called _minikube_?
- Which operating system is installed in which version?
- How much of the available RAM is in use? (Hint: "Allocated resources")
