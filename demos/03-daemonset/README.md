# DaemonSets on EKS

On the cluster created in [module 1](../01-eks), apply the manifest [ds.yaml](./ds.yaml). Then show that the
DaemonSet is running a pod on every node:

```shell
kubectl get pods -o wide
```

After that, SSH into one of the nodes and check that the file was created.
