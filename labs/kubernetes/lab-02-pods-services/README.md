# Lab 02: NGINX Pods and Services of Type ClusterIP

The [manifest](manifest.yaml) creates two pods and one service. Since no type is specified, it falls back to the default:
`ClusterIP`. This service type creates a static IP address inside the cluster under which the service is reachable.
In addition, there is a DNS name pointing to the service. We will see this further below.

**`manifest.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-1
  labels:
    app: nginx-pod-demo # This label is used to bind the pod to the service
spec:
  containers:
    - name: nginx
      image: nginx:1.29.4
      ports:
        - containerPort: 80
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
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-2
  labels:
    app: nginx-pod-demo # This label is used to bind the pod to the service
spec:
  containers:
    - name: nginx
      image: nginx:1.29.4
      ports:
        - containerPort: 80
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
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-pod-demo-svc
  labels:
    app: nginx-pod-demo
spec:
  selector:
    app: nginx-pod-demo # The selector determines which pods will belong to the service
  ports:
    - port: 80
      name: http
---
```

## Applying the manifest

First we create the required resources and check that they were created correctly. Please note that your
PowerShell session must be in the correct directory to do this – namely the one containing the manifest.yaml.

```shell
kubectl apply -f manifest.yaml
```

You can then find the pods you just created with `kubectl get pod`. The `--selector` argument filters out the
pods we just created.

```shell
kubectl get pod --selector=app=nginx-pod-demo
```

## Investigating DNS with busybox

We now want to verify that a service was really created that can be addressed inside the cluster.

To do this, we use `kubectl debug` to start a helper container. With this handy command, Kubernetes starts
a container solely for the purpose of inspecting another container. We inspect the first pod `nginx-pod-1`
and use [busybox](https://github.com/mirror/busybox), an image for debugging network problems.

```shell
kubectl debug nginx-pod-1 -it --image=busybox
```

> If you are using Azure Kubernetes Service, you need to use the following commands instead:
>
> ```bash
> kubectl run busybox \
> --image=busybox:1.36 \
> --restart=Never \
> --overrides='{
> "apiVersion":"v1",
> "spec":{
> "securityContext":{"seccompProfile":{"type":"RuntimeDefault"}},
> "containers":[{
> "name":"busybox",
> "image":"busybox:1.36",
> "command":["sh","-c","sleep 1d"],
> "resources":{
> "requests":{"cpu":"50m","memory":"64Mi"},
> "limits":{"cpu":"100m","memory":"128Mi"}
> },
> "readinessProbe":{"exec":{"command":["sh","-c","true"]},"initialDelaySeconds":1,"periodSeconds":5},
> "livenessProbe":{"exec":{"command":["sh","-c","true"]},"initialDelaySeconds":5,"periodSeconds":10}
> }]
> }
> }'
> kubectl exec -it busybox -- sh
> ```
>
> For PowerShell:
>
> ```PowerShell
> kubectl --% run busybox --image=busybox:1.36 --restart=Never --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"securityContext\":{\"seccompProfile\":{\"type\":\"RuntimeDefault\"}},\"containers\":[{\"name\":\"busybox\",\"image\":\"busybox:1.36\",\"command\":[\"sh\",\"-c\",\"sleep 1d\"],\"resources\":{\"requests\":{\"cpu\":\"50m\",\"memory\":\"64Mi\"},\"limits\":{\"cpu\":\"100m\",\"memory\":\"128Mi\"}},\"readinessProbe\":{\"exec\":{\"command\":[\"sh\",\"-c\",\"true\"]},\"initialDelaySeconds\":1,\"periodSeconds\":5},\"livenessProbe\":{\"exec\":{\"command\":[\"sh\",\"-c\",\"true\"]},\"initialDelaySeconds\":5,\"periodSeconds\":10}}]}}"
> ```

The command above starts a session with a new container of the `busybox` image for the purpose of inspecting the pod
`nginx-pod-1`. Next, we use the Linux command `nslookup` to see which IP address is behind the DNS name of
the service we created. As a reminder: services follow the naming scheme

`<ServiceName>.<Namespace>.svc.cluster.local`

and since all resources end up in the `default` namespace unless specified otherwise, our service lives there
too. This results in the DNS name

`nginx-pod-demo-svc.default.svc.cluster.local`

```shell
nslookup nginx-pod-demo-svc.default.svc.cluster.local
```

nslookup returns an IP address if we did everything right:

```shell
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   nginx-pod-demo-svc.default.svc.cluster.local
Address: 10.109.154.35
```

The IP is the _last_ entry. The first two IPs at the top are the IPs of the DNS server. We can now use the
service IP to make a request with the `wget` tool:

`wget -q -O- <IP>`

Enter the IP you determined above. The command should succeed.

## Cleaning up

```shell
kubectl delete service/nginx-pod-demo-svc
kubectl delete pod/nginx-pod-1
kubectl delete pod/nginx-pod-2
```

## Bonus

If you are already done, here are some additional resources:

- [Documentation on pods and pod lifecycles in Kubernetes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Documentation on Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/)
