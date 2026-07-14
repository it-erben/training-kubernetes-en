# Lab 07: Deployments with Recreate Rollout

The [manifest](manifest.yaml) contains a deployment very similar to the one from the previous exercise. However,
it is now configured so that the deployment is not rolled out in `RollingUpdate` mode but in
`Recreate` mode. Let's take a look at what that means.

**`manifest.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-recreate-demo
spec:
  replicas: 10
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: deployment-recreate-demo
  template:
    metadata:
      labels:
        app: deployment-recreate-demo
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: deployment-recreate-demo
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
kubectl rollout status deployment/deployment-recreate-demo
```

The rollout should succeed shortly. Afterwards, you can list all pods with the label specified in the
deployment's pod template spec:

```shell
kubectl get pod --selector=app=deployment-recreate-demo
```

Now trigger an update with a new image version, e.g. `nginx:1.29-alpine`.

```bash
kubectl set image deployment/deployment-recreate-demo nginx=nginx:1.29-alpine
```

Monitor the rollout.

```bash
kubectl rollout status deployment/deployment-recreate-demo
```

You will immediately notice that the rollout is much faster than with a rolling update. In `Recreate`
mode, the deployment does not proceed pod by pod but deletes all pods at once and recreates them.

## Cleaning up

```shell
kubectl delete deployment.apps/deployment-recreate-demo
```

## Bonus

- [Documentation on Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
