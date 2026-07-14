# Lab 06: Deployments and Rolling Updates

The [manifest](manifest.yaml) contains a deployment with a simple NGINX container, running as three
replica pods. A few things to note in this manifest:

- `apiVersion: apps/v1`: we're using the Kubernetes Deployment API.
- Deployment with the metadata name `deployment-demo`.
- `replicas: 3`: 3 replicas of the application get created.
- `strategy.type: RollingUpdate`: sets the update strategy to RollingUpdate.
- `rollingUpdate.maxSurge: 1`: how many extra replicas may be created on top of the desired count
  during the update.
- `rollingUpdate.maxUnavailable: 0`: how many replicas may be unavailable during the
  update.
- `selector.matchLabels.app: rollingupdate`: identifies the app by the label `rollingupdate`.
- The containers use the image `nginx:1.28-alpine` and listen on port `80`.

**`manifest.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-demo
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # How many pods can be created above the desired replicas number?
      maxUnavailable: 0 # How many pods can be unavailable during the update?
  selector:
    matchLabels:
      app: deployment-demo
  template:
    metadata:
      labels:
        app: deployment-demo
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: deployment-demo
      containers:
        - name: nginx
          image: nginx:1.28-alpine
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
```

## Running the example

Create the deployment.

```bash
kubectl apply -f manifest.yaml
```

Check the status of the deployment:

```bash
kubectl rollout status deployment/deployment-demo
```

The rollout should finish quickly. Once it's done, you can list all pods carrying the label from the
deployment's pod template:

```shell
kubectl get pod --selector=app=deployment-demo
```

Now perform a rolling update to a new image version, e.g. `nginx:1.29-alpine`:

```bash
kubectl set image deployment/deployment-demo nginx=nginx:1.29-alpine
```

Monitor the rolling update:

```bash
kubectl rollout status deployment/deployment-demo
```

If you need to roll back the rolling update:

```bash
kubectl rollout undo deployment/deployment-demo
```

To display the deployment's history:

```bash
kubectl rollout history deployment/deployment-demo
```

## Cleaning up

```shell
kubectl delete deployment.apps/deployment-demo
```

## Bonus

- [Documentation on Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
