# Demo 1: Container Image Restrictions

This demo shows how to use Azure Policy to restrict which container images may be used in the cluster.

## Use case

- Allow only images from your own Azure Container Registry (ACR)
- Prevent developers from using arbitrary images from Docker Hub
- Improve supply chain security

---

## 1. Set variables

```bash
export RESOURCE_GROUP="rg-aks-training"
export CLUSTER_NAME="aks-automatic-cluster"
export NAMESPACE="policy-demo"

# AKS ID for the policy scope
export AKS_ID=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query id \
  --output tsv)

# ACR name (if available)
export ACR_NAME="acrakstraining"  # Adjust!
```

---

## 2. Find the policy definition

```bash
# Find the policy ID for "Allowed Container Images"
export POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers should only use allowed images')].name" \
  --output tsv | head -1)

echo "Policy ID: $POLICY_ID"

# Show policy details
az policy definition show --name $POLICY_ID --query "{Name:displayName, Description:description}"
```

---

## 3. Assign the policy (audit mode)

First test in audit mode to see which workloads would be affected:

```bash
# Prepare the regex pattern (shell variable for better readability)
export IMAGE_REGEX="^(mcr\\.microsoft\\.com|${ACR_NAME}\\.azurecr\\.io|docker\\.io/library/(nginx|busybox|alpine)).*$"

# Assign the policy in audit mode
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-allowed-images-audit" \
  --display-name "AKS: Only allowed container images (Audit)" \
  --policy $POLICY_ID \
  --scope $AKS_ID \
  --params "{
    \"allowedContainerImagesRegex\": {\"value\": \"${IMAGE_REGEX}\"},
    \"effect\": {\"value\": \"Audit\"},
    \"excludedNamespaces\": {\"value\": [\"kube-system\", \"gatekeeper-system\", \"azure-arc\"]}
  }"

echo "Policy assigned. Waiting for synchronization (2-3 minutes)..."
```

**Regex explanation:**

- `mcr\.microsoft\.com` - Microsoft Container Registry (for system images)
- `$ACR_NAME\.azurecr\.io` - Your own ACR
- `docker\.io/library/(nginx|busybox|alpine)` - Selected official Docker images

---

## 4. Create the test namespace

```bash
kubectl create namespace $NAMESPACE
```

---

## 5. Test an allowed image

```bash
# Allowed image (nginx from docker.io/library)
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: allowed-image-test
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
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

# Check
kubectl get pod -n $NAMESPACE allowed-image-test
```

---

## 6. Test a disallowed image (audit mode)

In audit mode, the pod is created but marked as non-compliant:

```bash
# Disallowed image (random image from Docker Hub)
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: disallowed-image-test
spec:
  containers:
  - name: redis
    image: redis:7  # Not on the allowed list!
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
    readinessProbe:
      exec:
        command: ["redis-cli", "ping"]
      initialDelaySeconds: 5
      periodSeconds: 5
    livenessProbe:
      exec:
        command: ["redis-cli", "ping"]
      initialDelaySeconds: 10
      periodSeconds: 10
EOF

# The pod is created (audit mode does not block)
kubectl get pod -n $NAMESPACE disallowed-image-test
```

---

## 7. Check compliance status

```bash
# Wait a moment for the policy evaluation
sleep 30

# Show non-compliant resources
az policy state list \
  --resource $AKS_ID \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[?contains(policyDefinitionName, 'ContainerAllowedImages')].{Resource:resourceId, Policy:policyDefinitionName}" \
  --output table

# Check the Gatekeeper constraint in the cluster
kubectl get constraints -o wide

# Show audit violations
kubectl get constraint -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.violations[*]}  - {.namespace}/{.name}: {.message}{"\n"}{end}{end}'
```

---

## 8. Switch the policy to Deny

Once audit mode shows that everything is fine, switch to Deny:

```bash
# Regex pattern (in case it is no longer set)
export IMAGE_REGEX="^(mcr\\.microsoft\\.com|${ACR_NAME}\\.azurecr\\.io|docker\\.io/library/(nginx|busybox|alpine)).*$"

# Update the policy assignment
az policy assignment update \
  --name "aks-allowed-images-audit" \
  --scope $AKS_ID \
  --params "{
    \"allowedContainerImagesRegex\": {\"value\": \"${IMAGE_REGEX}\"},
    \"effect\": {\"value\": \"deny\"},
    \"excludedNamespaces\": {\"value\": [\"kube-system\", \"gatekeeper-system\", \"azure-arc\"]}
  }"

echo "Policy switched to Deny. Waiting for synchronization..."
sleep 60
```

---

## 9. Test Deny mode

```bash
# Delete the old test pod
kubectl delete pod -n $NAMESPACE disallowed-image-test --ignore-not-found

# Try again to deploy a disallowed image
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: disallowed-image-deny-test
spec:
  containers:
  - name: redis
    image: redis:7
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
EOF

# Expected error message:
# Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request:
# [azurepolicy-container-allowed-images-...] Container image redis:7 is not allowed.
```

---

## 10. More complex regex examples

```bash
# Allow only your own ACR + MCR (strict)
export IMAGE_REGEX="^(mcr\\.microsoft\\.com|myacr\\.azurecr\\.io)/.*$"

# Allow multiple ACRs
export IMAGE_REGEX="^(mcr\\.microsoft\\.com|acr1\\.azurecr\\.io|acr2\\.azurecr\\.io)/.*$"

# Allow specific repositories on Docker Hub
export IMAGE_REGEX="^(mcr\\.microsoft\\.com|docker\\.io/(library|bitnami|grafana))/.*$"

# Then assign with:
az policy assignment create \
  --name "aks-allowed-images" \
  --policy $POLICY_ID \
  --scope $AKS_ID \
  --params "{
    \"allowedContainerImagesRegex\": {\"value\": \"${IMAGE_REGEX}\"},
    \"effect\": {\"value\": \"deny\"},
    \"excludedNamespaces\": {\"value\": [\"kube-system\", \"gatekeeper-system\", \"azure-arc\"]}
  }"

# Disallow latest tags (in addition to the registry restriction)
# Note: Requires a separate policy or a custom policy
```

---

## 11. Cleanup

```bash
# Delete the test pods
kubectl delete pod -n $NAMESPACE allowed-image-test --ignore-not-found
kubectl delete pod -n $NAMESPACE disallowed-image-test --ignore-not-found

# Delete the policy assignment
az policy assignment delete \
  --name "aks-allowed-images-audit" \
  --scope $AKS_ID
```

---

## Best Practices

1. **Always start with Audit** - First check what would be affected
2. **Excluded namespaces** - Exclude system namespaces
3. **Always allow MCR** - Microsoft Container Registry for AKS components
4. **Roll out gradually** - Test clusters first, then production
5. **Documentation** - Document the regex pattern for the team

## Summary

| Aspect                      | Value                                                       |
| --------------------------- | ----------------------------------------------------------- |
| **Policy**                  | Kubernetes cluster containers should only use allowed images|
| **Effect**                  | Audit → Deny                                                |
| **Parameter**               | `allowedContainerImagesRegex` (regex for allowed images)    |
| **Excluded namespaces**     | kube-system, gatekeeper-system, azure-arc                   |
