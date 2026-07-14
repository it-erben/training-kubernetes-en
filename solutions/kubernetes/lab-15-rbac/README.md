# Solution: RBAC with Pods

```bash
kubectl apply -f pod1.yaml
kubectl exec -it kubectl-pod -- bash -c "kubectl get pods"   # expected: Forbidden
kubectl delete pod kubectl-pod

kubectl apply -f sa.yaml
kubectl apply -f pod2.yaml
kubectl exec -it kubectl-pod -- bash -c "kubectl get pods"   # now succeeds

kubectl delete pod kubectl-pod
kubectl delete rolebinding/read-pods role/pod-reader serviceaccount/my-kubectl-sa
```

Through the Role and RoleBinding, the ServiceAccount `my-kubectl-sa` gets `get/list` on pods in the default namespace.
