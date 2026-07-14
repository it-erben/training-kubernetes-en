# Solution: Deployment Recreate

```bash
kubectl apply -f manifest.yaml
kubectl rollout status deployment/deployment-recreate-demo
kubectl get pod --selector=app=deployment-recreate-demo

# Update
kubectl set image deployment/deployment-recreate-demo nginx=nginx:alpine3.18
kubectl rollout status deployment/deployment-recreate-demo   # all old pods are removed first

kubectl delete deployment.apps/deployment-recreate-demo
```

Expected result: the update deletes all pods first and then recreates them, which makes the rollout faster but can
cause downtime.
