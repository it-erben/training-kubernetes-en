# Solution: Pod Security Standards

```bash
kubectl apply -f ns.yaml

# Warning (goes through, but produces a PSA warning)
kubectl apply -f warn-pod.yaml
# Expected warning: violation of "restricted" (runAsNonRoot, seccomp, capabilities)

# Blocked (privileged) → Forbidden
kubectl apply -f error-pod.yaml

kubectl delete all --all -n my-secure-namespace
kubectl delete ns my-secure-namespace
```

The namespace enforces `baseline`; pods with `privileged=true` are rejected, while less severe violations only
produce warnings.
