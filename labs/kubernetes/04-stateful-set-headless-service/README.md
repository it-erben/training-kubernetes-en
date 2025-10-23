# NGINX StatefulSet with Headless Service (Reworded)

The [Manifest](https://www.google.com/search?q=manifest.yaml) creates a **`StatefulSet`** with **three replicas** of an **`nginx`** Pod, which occupies container port 80. Additionally, a **`Service`** is defined that runs in **Headless mode**. This means it does not receive a ClusterIP (`clusterIP: None`). We will now examine exactly what this implies.

See the [StatefulSets Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) for more details on StatefulSets.

## Apply the Manifest

First, let's create the necessary resources and verify they were generated correctly.

```shell
kubectl apply -f manifest.yaml
```

Next, let's check if the Service and Pods were successfully created or started.

```shell
kubectl get service nginx-headless
```

```shell
kubectl get pod --selector=app=nginx
```

## Investigate DNS with BusyBox

We will use **`kubectl debug`** to start a helper container. We will investigate the first Pod of the StatefulSet, **`nginx-0`**, and use the **`busybox`** image (an image for debugging network issues).

```shell
kubectl debug nginx-0 -it --image=busybox
```

The DNS name of the Service we created is `nginx-headless.default.svc.cluster.local`, and we will see that it resolves to **three IP addresses: one per Pod**. The Service itself has **no ClusterIP**\! Only the Pods have an IP, as they always do (well, almost always...).

```shell
nslookup nginx-headless.default.svc.cluster.local
```

```shell
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.65
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.66
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.64
```

Furthermore, the Headless Service creates a **DNS name per Pod** with a running index, following the pattern:

```
<STATEFULSETNAME>-<INDEX>.<SERVICENAME>.<NAMESPACE>.svc.cluster.local
```

For example:

```
nginx-0.nginx-headless.default.svc.cluster.local
```

We can also prove this with `nslookup`:

```shell
nslookup nginx-0.nginx-headless.default.svc.cluster.local
```

```server: 10.96.0.10
Address:        10.96.0.10:53


Name:   nginx-0.nginx-headless.default.svc.cluster.local
Address: 10.244.0.64 # This is the address of the Pod!
```

## Cleanup

```shell
kubectl delete statefulset.apps/nginx
kubectl delete service/nginx-headless
```
