# Lab 07: Deployments with Recreate Rollout

The [manifest](manifest.yaml) contains a deployment very similar to the one from the previous exercise.
This time, though, it's configured to roll out in `Recreate` mode instead of `RollingUpdate`.
Let's see what that means in practice.

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

The rollout should finish quickly. Once it's done, you can list all pods carrying the label from the
deployment's pod template:

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

You'll notice right away that the rollout is much faster than a rolling update. In `Recreate`
mode, the deployment doesn't go pod by pod – it deletes all pods at once and creates new ones.

## Cleaning up

```shell
kubectl delete deployment.apps/deployment-recreate-demo
```

## Bonus

- [Documentation on Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
