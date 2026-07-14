# DaemonSets on EKS

On the cluster created in [module 1](../01-eks), apply the manifest [ds.yaml](./ds.yaml). Then, first show that a pod
of the DaemonSet is running on every node:

```shell
kubectl get pods -o wide
```

After that, you can connect to one of the nodes via ssh and check whether the file was created.
