# Deployments and Rolling Updates

The [Manifest](https://www.google.com/search?q=manifest.yaml) contains a **Deployment** with a simple NGINX container for which three replica Pods are created.
The following properties can be observed in this manifest:

* **`apiVersion: apps/v1`**: Specifies that we are using the Kubernetes Deployment API.
* **Deployment** with the metadata name **`deployment-demo`**.
* **`replicas: 3`**: Specifies that **3 replicas** of the application should be created.
* **`strategy.type: RollingUpdate`**: Determines the update strategy as **RollingUpdate**.
* **`rollingUpdate.maxSurge: 1`**: Specifies how many replicas are allowed to be created **in addition** to the desired number of replicas during the update.
* **`rollingUpdate.maxUnavailable: 0`**: Determines how many replicas are allowed to be **unavailable** during the update.
* **`selector.matchLabels.app: rollingupdate`**: For identifying the application with the label **`rollingupdate`**.
* The containers use the image **`nginx:alpine3.17`** and listen on port **`80`**.

See the [Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) for more information.

## Running the Example

Create the Deployment.

```bash
kubectl apply -f manifest.yaml
```

Check the status of the Deployment:

```bash
kubectl rollout status deployment/deployment-demo
```

The rollout should soon be successful. Afterwards, you can list all Pods using the label specified in the Deployment's Pod Template-Spec:

```shell
kubectl get pod --selector=app=deployment-demo
```

Now, perform a **Rolling Update** to a new image version, e.g., **`nginx:alpine3.18`**:

```bash
kubectl set image deployment/deployment-demo nginx=nginx:alpine3.18
```

Monitor the Rolling Update:

```bash
kubectl rollout status deployment/deployment-demo
```

If you need to **undo** the Rolling Update:

```bash
kubectl rollout undo deployment/deployment-demo
```

To display the Deployment's **history**:

```bash
kubectl rollout history deployment/deployment-demo
```

## Cleanup

```shell
kubectl delete deployment.apps/deployment-demo
```

