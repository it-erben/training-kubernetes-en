# NGINX Pods and Services of Type ClusterIP

The given [**manifest file**](./manifest.yaml) creates two Pods and one Service. Since no type is specified, it defaults to **`ClusterIP`**. This Service Type establishes a static IP address within the cluster under which the Service is reachable. Additionally, there is a DNS name that points to the Service. We'll examine this further below.

-----

## Applying the Manifest

First, we create the required resources and check if they were created correctly.
Please note that you must be in the correct directory with PowerShell for this — specifically, the one where the `manifest.yaml` file is located.

```shell
kubectl apply -f manifest.yaml
```

Subsequently, you can find the recently created Pods with **`kubectl get pod`**. The **`--selector`** argument filters out the Pods that we just created.

```shell
kubectl get pod --selector=app=nginx-pod-demo
```

-----

## Examining DNS with busybox

We now want to verify whether a Service was indeed created that can be addressed within the cluster.

To do this, we use **`kubectl debug`** to start a helper container. With this handy command, Kubernetes starts a container solely for the purpose of inspecting another container.
We inspect the first Pod, **`nginx-pod-1`**, and use **[busybox](https://github.com/mirror/busybox)**, an image for debugging network issues.

```shell
kubectl debug nginx-pod-1 -it --image=busybox
```

The command above starts a session with a new container from the `busybox` image for the purpose of inspecting the Pod `nginx-pod-1`.
Next, we use the Linux command **`nslookup`** to check which IP address is behind the DNS name of the Service we created.
As a reminder, Services have the naming scheme:

`<ServiceName>.<Namespace>.svc.cluster.local`

and since all resources by default land in the **`default`** Namespace unless otherwise specified, our Service is also located there. This results in the DNS name:

`nginx-pod-demo-svc.default.svc.cluster.local`

```shell
nslookup nginx-pod-demo-svc.default.svc.cluster.local
```

`nslookup` will return an IP address if we've done everything correctly:

```shell
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   nginx-pod-demo-svc.default.svc.cluster.local
Address: 10.109.154.35
```

The IP is the *last* entry here. The first two IPs are the addresses of the DNS server.
We can now use the Service IP to initiate a request with the **`wget`** tool:

`wget -q -O- <IP>`

Please enter the IP you determined above. The command should be successful.

-----

## Cleanup

```shell
kubectl delete service/nginx-pod-demo-svc
kubectl delete pod/nginx-pod-1
kubectl delete pod/nginx-pod-2
```

-----

## Bonus

If you're already finished, here are some additional resources:

- [Documentation on Pods and Pod Lifecycles in Kubernetes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Documentation on Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)