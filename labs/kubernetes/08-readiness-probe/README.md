# Readiness Probes with httpGet

In this exercise, I'll show you how to use **Readiness Probes** to monitor your application's health.

-----

## Preparation: Deploying the Deployment

In [manifest.yaml](./manifest.yaml), you'll find a **Deployment** with NGINX containers.
It intentionally contains a **bug in the Readiness Probe**.

First, apply the manifest:

```shell
kubectl apply -f manifest.yaml
```

Next, check if the Pods in the Deployment are running:

```shell
k get po --selector=app=readiness-check-demo
#NAME                                           READY   STATUS    RESTARTS   AGE
#readiness-check-demo-deploy-7ff9c8f684-dv9t7   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-fg2qw   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-r4qkr   0/1     Running   0          102s
```

The Pods are running, but they are **not Ready** (`0/1`). Consequently, they are **not being used by the Service**.

You can test this by starting a debug Pod:

```shell
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
```

You are now in the terminal of a container running BusyBox. Use `nslookup` to check if the Service can be resolved via DNS:

```shell
nslookup readiness-check-demo-svc.default.svc.cluster.local

# Server:      10.96.0.10
# Address:  10.96.0.10:53

# Name: readiness-check-demo-svc.default.svc.cluster.local
# Address: 10.103.46.232
```

Then, try to call the last-mentioned IP address using `wget`:

```shell
wget -O- readiness-check-demo-svc.default.svc.cluster.local
# Connecting to readiness-check-demo-svc.default.svc.cluster.local (10.103.46.232:80)
# wget: can't connect to remote host (10.103.46.232): Connection refused
```

Since **none of the Pods are Ready**, a connection cannot be established.

-----

## Assignment

**Fix the Readiness Probe** in [manifest.yaml](./manifest.yaml).
Afterwards, **apply the manifest** and use the BusyBox test Pod to verify that you can successfully **connect to the Service using `wget`**.
