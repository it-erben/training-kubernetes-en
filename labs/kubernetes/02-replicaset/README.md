# ReplicaSet

This example illustrates the role that **ReplicaSets** play in Kubernetes. The resource we'll examine is defined in the file **`manifest.yaml`**.

Consult the [ReplicaSets Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) for more information on ReplicaSets.

Please remember to switch to the correct directory using PowerShell.

Perform the following steps to start the demo:

Create the ReplicaSet using the manifest:

```sh
kubectl apply -f manifest.yaml
```

The manifest defines a **`ReplicaSet`** with **three NGINX Pods**.
Ensure that all Pods have been created correctly:

```sh
kubectl get pods --selector=app=replicaset-demo
```

This command works as written because all Pods carry the **`app=replicaset-demo`** label. If you're unsure why this is the case, review the manifest again. You will find the label defined within the **Pod template**.

Now, delete one Pod:

```sh
kubectl delete pod <POD_NAME>
```

Check the list of Pods again.

```sh
kubectl get pods --selector=app=replicaset-demo
```

The ReplicaSet should now have created a **third Pod** again. If not, you may need to wait a few seconds.

## Cleanup

```shell
kubectl delete replicaset.apps/replicaset-demo
```
