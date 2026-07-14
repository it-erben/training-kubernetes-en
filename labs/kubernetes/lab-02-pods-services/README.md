# Lab 02: NGINX Pods and Services of Type ClusterIP

The [manifest](manifest.yaml) creates two pods and one service. No type is specified, so it falls back to the
default: `ClusterIP`. This service type gives the service a fixed IP address that's reachable from inside the cluster.
There's also a DNS name pointing to the service, which we'll get to below.

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

First we create the resources and check that they came up correctly. Make sure your PowerShell
session is in the right directory for this – the one containing the manifest.yaml.

```shell
kubectl apply -f manifest.yaml
```

You can then find the new pods with `kubectl get pod`. The `--selector` argument narrows the list
down to the pods from this lab.

```shell
kubectl get pod --selector=app=nginx-pod-demo
```

## Investigating DNS with busybox

Now let's verify that the service actually exists and can be reached from inside the cluster.

For this we start a helper container with `kubectl debug`. This handy command tells Kubernetes to spin up
a container whose only job is to poke around inside another one. We'll inspect the first pod, `nginx-pod-1`,
using [busybox](https://github.com/mirror/busybox), an image well suited to debugging network problems.

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

The command above drops you into a shell in a fresh `busybox` container so you can inspect the pod
`nginx-pod-1`. Next we use `nslookup` to find out which IP address sits behind the DNS name of
the service we created. As a reminder, services follow the naming scheme

`<ServiceName>.<Namespace>.svc.cluster.local`

and since everything lands in the `default` namespace unless you say otherwise, that's where our service
lives too. That gives us the DNS name

`nginx-pod-demo-svc.default.svc.cluster.local`

```shell
nslookup nginx-pod-demo-svc.default.svc.cluster.local
```

If we did everything right, nslookup returns an IP address:

```shell
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   nginx-pod-demo-svc.default.svc.cluster.local
Address: 10.109.154.35
```

The IP is the _last_ entry. The two IPs at the top belong to the DNS server. We can now use the
service IP to make a request with `wget`:

`wget -q -O- <IP>`

Plug in the IP you found above. The command should succeed.

## Cleaning up

```shell
kubectl delete service/nginx-pod-demo-svc
kubectl delete pod/nginx-pod-1
kubectl delete pod/nginx-pod-2
```

## Bonus

Done early? Here's some further reading:

- [Documentation on pods and pod lifecycles in Kubernetes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Documentation on Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/)
