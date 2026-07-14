# Lab 13: Readiness Probes with httpGet

This exercise shows you how to monitor your application with readiness probes.

## Preparation: Set Up the Deployment

The Deployment in [manifest.yaml](./manifest.yaml) runs NGINX containers. Its readiness probe contains a
deliberate mistake.

**`manifest.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readiness-check-demo-deploy
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: readiness-check-demo
  template:
    metadata:
      labels:
        app: readiness-check-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.29-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              port: 81
              path: /
          livenessProbe:
            httpGet:
              port: 80
              path: /
            initialDelaySeconds: 10
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: readiness-check-demo
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-check-demo-svc
  labels:
    app: readiness-check-demo
spec:
  selector:
    app: readiness-check-demo
  ports:
    - port: 80
      name: http
```

First, apply the manifest:

```shell
kubectl apply -f manifest.yaml
```

Then check whether the Deployment's pods are running:

```shell
kubectl get po --selector=app=readiness-check-demo
#NAME                                           READY   STATUS    RESTARTS   AGE
#readiness-check-demo-deploy-7ff9c8f684-dv9t7   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-fg2qw   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-r4qkr   0/1     Running   0          102s
```

The pods are running, but they never become Ready, so the Service won't send them any traffic. You can
see this for yourself by starting a debug pod:

```shell
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
```

You now have a shell inside a Busybox container. Use nslookup to check whether DNS resolves the
Service name in the first place:

```shell
nslookup readiness-check-demo-svc.default.svc.cluster.local

# Server:  10.96.0.10
# Address: 10.96.0.10:53

# Name: readiness-check-demo-svc.default.svc.cluster.local
# Address: 10.103.46.232
```

Next, try to reach that address with wget:

```shell
wget -O- readiness-check-demo-svc.default.svc.cluster.local
# Connecting to readiness-check-demo-svc.default.svc.cluster.local (10.103.46.232:80)
# wget: can't connect to remote host (10.103.46.232): Connection refused
```

None of the pods are Ready, so the connection is refused.

## Task

Fix the readiness probe in [manifest.yaml](./manifest.yaml), apply the manifest again, and use the
Busybox test pod to check whether you can now reach the Service with wget.
