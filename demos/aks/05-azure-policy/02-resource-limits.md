# Demo 2: Enforcing Resource Limits

This demo shows how to use Azure Policy to make sure every container defines CPU and memory limits.

## Use case

- Prevent "noisy neighbors" (one pod consuming all resources)
- Better cluster stability and predictability
- Prerequisite for effective autoscaling (HPA, VPA)
- Cost control

---

## 1. Set variables

```bash
export RESOURCE_GROUP="rg-aks-training"
export CLUSTER_NAME="aks-automatic-cluster"
export NAMESPACE="policy-demo"

export AKS_ID=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query id \
  --output tsv)
```

---

## 2. Find the policy definition

There are several relevant policies:

```bash
# Container CPU and memory limits
az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers CPU and memory')].{Name:displayName, ID:name}" \
  --output table

# Save the policy IDs
export LIMITS_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers CPU and memory resource limits')].name" \
  --output tsv | head -1)

echo "Limits Policy ID: $LIMITS_POLICY_ID"
```

---

## 3. Assign the policy

```bash
# Assign the policy for CPU/memory limits
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-resource-limits" \
  --display-name "AKS: Containers must have CPU/memory limits" \
  --policy $LIMITS_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "cpuLimit": {"value": "2"},
    "memoryLimit": {"value": "4Gi"},
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc", "kube-node-lease"]}
  }'

echo "Policy assigned. Waiting for synchronization (2-3 minutes)..."
sleep 120
```

**What the parameters mean:**

- `cpuLimit`: Maximum CPU per container (here: 2 cores)
- `memoryLimit`: Maximum memory per container (here: 4Gi)
- Pods without limits are blocked
- Pods with limits above the maximum are blocked too

---

## 4. Create the test namespace

```bash
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
```

---

## 5. Test a pod WITHOUT limits (should fail)

```bash
# Pod without resource limits
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: no-limits-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    # No resources defined!
EOF

# Expected error message:
# Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request:
# [azurepolicy-container-limits-...] container <nginx> has no resource limits
```

---

## 6. Test a pod with correct limits (should work)

```bash
# Pod with resource limits
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: with-limits-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 10
EOF

# Should succeed
kubectl get pod -n $NAMESPACE with-limits-pod
```

---

## 7. Test a pod with limits that are TOO HIGH (should fail)

```bash
# Pod with limits above the maximum
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: excessive-limits-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "10"        # Above the maximum of 2!
        memory: "16Gi"   # Above the maximum of 4Gi!
EOF

# Expected error message:
# Error from server (Forbidden): ... cpu limit 10 is higher than the maximum allowed of 2
```

---

## 8. Test a Deployment with multiple containers

```bash
# Multi-container pod - all containers need limits
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-container-app
  namespace: policy-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-container-app
  template:
    metadata:
      labels:
        app: multi-container-app
    spec:
      containers:
      - name: app
        image: nginx:1.27
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
      - name: sidecar
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo sidecar running; sleep 60; done"]
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
        readinessProbe:
          exec:
            command: ["echo", "ready"]
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          exec:
            command: ["echo", "alive"]
          initialDelaySeconds: 5
          periodSeconds: 10
EOF

kubectl get deployment -n $NAMESPACE multi-container-app
kubectl get pods -n $NAMESPACE -l app=multi-container-app
```

---

## 9. Additional policy: Requests must be defined

For even stricter control, you can also enforce requests:

```bash
# Find the policy for CPU/memory requests
export REQUESTS_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers should only use allowed') && contains(displayName, 'resource')].name" \
  --output tsv | head -1)

# Alternative: create a custom initiative (see below)
```

---

## 10. LimitRange as a Kubernetes alternative

On top of Azure Policy, you can use a LimitRange to set default values:

```bash
# Create a LimitRange (sets defaults when no limits are specified)
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF

# Pods without limits are now automatically assigned defaults
# BUT: The Azure Policy still blocks them, because the defaults
# are only applied AFTER the admission check!
```

> **Important:** LimitRange defaults are applied after the admission webhook,
> so an Azure Policy set to `deny` can still block pods without explicit limits.
> Combine both, but treat the LimitRange as a safety net only.

---

## 11. ResourceQuota for namespace-wide control

```bash
# A ResourceQuota limits the total resources in the namespace
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"
EOF

kubectl describe resourcequota compute-quota -n $NAMESPACE
```

---

## 12. Check compliance status

```bash
# Non-compliant resources
az policy state list \
  --resource $AKS_ID \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[?contains(policyDefinitionName, 'container')].{Resource:resourceId}" \
  --output table

# Gatekeeper constraint status
kubectl get constraints -o wide
```

---

## 13. Cleanup

```bash
# Delete the test resources
kubectl delete namespace $NAMESPACE --ignore-not-found

# Delete the policy assignment
az policy assignment delete \
  --name "aks-resource-limits" \
  --scope $AKS_ID

echo "Cleanup complete!"
```

---

## Recommended limits

| Workload type | CPU Request | CPU Limit | Memory Request | Memory Limit |
| --- | --- | --- | --- | --- |
| Microservice | 100m | 500m | 128Mi | 512Mi |
| Web app | 250m | 1 | 256Mi | 1Gi |
| Batch job | 500m | 2 | 512Mi | 2Gi |
| Database | 1 | 4 | 2Gi | 8Gi |

---

## Best Practices

1. **Requests = guaranteed resources** - Set them realistically
2. **Limits = maximum** - Don't set them too high, or cluster stability suffers
3. **Watch the ratio** - The limit should be at most 2-3x the request
4. **Monitor** - Watch actual usage and adjust
5. **Use VPA** - The Vertical Pod Autoscaler gives you automatic recommendations

## Summary

| Aspect | Value |
| --- | --- |
| **Policy** | Kubernetes cluster containers CPU and memory resource limits |
| **Effect** | Deny |
| **Parameters** | `cpuLimit`, `memoryLimit` |
| **Complement** | LimitRange for defaults, ResourceQuota for namespace limits |
