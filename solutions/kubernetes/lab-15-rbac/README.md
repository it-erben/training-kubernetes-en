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

The ServiceAccount `my-kubectl-sa` is granted the `get/list` permissions on pods in the default namespace via Role/RoleBinding.
