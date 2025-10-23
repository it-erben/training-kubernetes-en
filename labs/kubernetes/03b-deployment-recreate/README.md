# Deployments with Recreate Rollout

The [Manifest](https://www.google.com/search?q=manifest.yaml) contains a **Deployment** very similar to the one in the last assignment. However, it's now configured to roll out in **`Recreate`** mode instead of `RollingUpdate`. Let's examine what this means.

## Running the Example

Create the Deployment.

```bash
kubectl apply -f manifest.yaml
```

Check the status of the Deployment:

```bash
kubectl rollout status deployment/deployment-recreate-demo
```

The rollout should soon be successful. Afterwards, you can list all Pods using the label specified in the Deployment's Pod Template-Spec:

```shell
kubectl get pod --selector=app=deployment-recreate-demo
```

Now, trigger an update with a new image version, e.g., **`nginx:alpine3.18`**.

```bash
kubectl set image deployment/deployment-recreate-demo nginx=nginx:alpine3.18
```

Monitor the rollout.

```bash
kubectl rollout status deployment/deployment-recreate-demo
```

It's immediately noticeable that this rollout is **much faster** than the Rolling Update. This is because the Deployment in **`Recreate`** mode does not proceed Pod by Pod; instead, it **deletes all existing Pods at once** and then **creates the new ones**.

## Cleanup

```shell
kubectl delete deployment.apps/deployment-recreate-demo
```
