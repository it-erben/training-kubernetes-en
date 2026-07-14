# Solution: Deployment Rolling Update

```bash
kubectl apply -f manifest.yaml
kubectl rollout status deployment/deployment-demo
kubectl get pod --selector=app=deployment-demo

# Trigger a rolling update
kubectl set image deployment/deployment-demo nginx=nginx:alpine3.18
kubectl rollout status deployment/deployment-demo

# History / undo
kubectl rollout history deployment/deployment-demo
kubectl rollout undo deployment/deployment-demo

kubectl delete deployment.apps/deployment-demo
```

Expected result: the update proceeds pod by pod thanks to `maxUnavailable: 0`, `maxSurge: 1`; undo restores the
original image.
