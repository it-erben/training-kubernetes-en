# Demo 4: Pod Security (Blocking Privileged Containers)

This demo shows how to use Azure Policy to prevent insecure pod configurations - especially privileged containers.

## Use case

- Privileged containers can "break out" of container isolation
- Host network gives a pod access to node traffic
- Host PID/IPC exposes other processes on the node
- Running as root inside the container is a security risk

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

## 2. Find relevant policies

```bash
# Pod-security-related policies
az policy definition list \
  --query "[?contains(displayName, 'Kubernetes') && (contains(displayName, 'privileged') || contains(displayName, 'hostNetwork') || contains(displayName, 'root'))].{Name:displayName}" \
  --output table

# Important policies:
# 1. No Privileged Containers
export PRIV_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster should not allow privileged containers')].name" \
  --output tsv | head -1)

# 2. No Host Network/Ports
export HOSTNET_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'host network and port')].name" \
  --output tsv | head -1)

# 3. No Host PID/IPC
export HOSTPID_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'should not share host process')].name" \
  --output tsv | head -1)

echo "Privileged Policy: $PRIV_POLICY_ID"
echo "HostNetwork Policy: $HOSTNET_POLICY_ID"
echo "HostPID Policy: $HOSTPID_POLICY_ID"
```

---

## 3. Assign the policies

### 3.1 Block privileged containers

```bash
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-no-privileged" \
  --display-name "AKS: No privileged containers" \
  --policy $PRIV_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]}
  }'
```

### 3.2 Block host network

```bash
az policy assignment create \
  --name "aks-no-host-network" \
  --display-name "AKS: No host network" \
  --policy $HOSTNET_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "allowHostNetwork": {"value": false},
    "minPort": {"value": 0},
    "maxPort": {"value": 0},
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc", "ingress-nginx"]}
  }'
```

### 3.3 Block host PID/IPC

```bash
az policy assignment create \
  --name "aks-no-host-pid" \
  --display-name "AKS: No host PID/IPC sharing" \
  --policy $HOSTPID_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]}
  }'

echo "Policies assigned. Waiting for synchronization (2-3 minutes)..."
sleep 120
```

---

## 4. Create the test namespace

```bash
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
```

---

## 5. Test a privileged container (should fail)

```bash
# Privileged container
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: privileged
    image: nginx:1.27
    securityContext:
      privileged: true  # NOT ALLOWED!
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
# [azurepolicy-psp-privileged-container-...] Privileged container is not allowed
```

---

## 6. Test host network (should fail)

```bash
# Pod with host network
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
spec:
  hostNetwork: true  # NOT ALLOWED!
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
EOF

# Expected error message:
# [azurepolicy-psp-host-network-ports-...] HostNetwork is not allowed
```

---

## 7. Test host PID (should fail)

```bash
# Pod with host PID
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: host-pid-pod
spec:
  hostPID: true  # NOT ALLOWED!
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
EOF

# Expected error message:
# [azurepolicy-psp-host-sharing-...] Sharing the host PID namespace is not allowed
```

---

## 8. Test root user

```bash
# Pod running as root
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: root-user-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    securityContext:
      runAsUser: 0  # Root!
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
EOF

# Note: There is a separate policy for this restriction
# "Kubernetes cluster pods should not use host process ID or host IPC namespace"
```

---

## 9. Test a secure pod (should work)

```bash
# Secure pod with all best practices
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  labels:
    app: secure-app
    owner: security-team
    env: demo
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:1.27
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
    readinessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    livenessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
EOF

# Note: nginx needs writable directories for cache and PID
# Hence the emptyDir volumes
kubectl get pod -n $NAMESPACE secure-pod
```

---

## 10. All security policies at once (initiative)

For enterprise environments, use a policy initiative:

```bash
# Find the AKS baseline initiative (contains many security policies)
az policy set-definition list \
  --query "[?contains(displayName, 'Kubernetes cluster pod security')].{Name:displayName, ID:name}" \
  --output table

# Assign the baseline initiative
export BASELINE_INITIATIVE_ID=$(az policy set-definition list \
  --query "[?contains(displayName, 'Kubernetes cluster pod security baseline')].name" \
  --output tsv | head -1)

# Assign the initiative (replaces individual policies)
az policy assignment create \
  --name "aks-pod-security-baseline" \
  --display-name "AKS: Pod Security Baseline" \
  --policy-set-definition $BASELINE_INITIATIVE_ID \
  --scope $AKS_ID \
  --params '{
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]}
  }'
```

---

## 11. Comparison: Azure Policy vs Pod Security Standards (PSS)

| Feature      | Azure Policy           | Kubernetes PSS                             |
| ------------ | ---------------------- | ------------------------------------------ |
| Scope        | Azure-wide             | Cluster-wide                               |
| Granularity  | Very fine-grained      | 3 levels (privileged, baseline, restricted)|
| Audit log    | Azure Activity Log     | Kubernetes audit log                       |
| Exceptions   | Per namespace/resource | Per namespace                              |
| Management   | Azure Portal/CLI       | kubectl                                    |

**Recommendation:** Combine both!

- PSS for a Kubernetes-native baseline
- Azure Policy for enterprise compliance and audit

---

## 12. Check compliance status

```bash
# All security policy violations
az policy state list \
  --resource $AKS_ID \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[?contains(policyDefinitionName, 'privileged') || contains(policyDefinitionName, 'host')].{Policy:policyDefinitionName, State:complianceState}" \
  --output table

# Gatekeeper constraints
kubectl get constraints -o wide
```

---

## 13. Cleanup

```bash
# Delete the test resources
kubectl delete namespace $NAMESPACE --ignore-not-found

# Delete the policies
az policy assignment delete --name "aks-no-privileged" --scope $AKS_ID
az policy assignment delete --name "aks-no-host-network" --scope $AKS_ID
az policy assignment delete --name "aks-no-host-pid" --scope $AKS_ID
# az policy assignment delete --name "aks-pod-security-baseline" --scope $AKS_ID

echo "Cleanup complete!"
```

---

## Security Context Cheatsheet

```yaml
# Minimal security configuration
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false

# Recommended security configuration
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL

# Maximum security configuration (restricted)
securityContext:
  runAsNonRoot: true
  runAsUser: 65534  # nobody
  runAsGroup: 65534
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL
```

## Summary

| Policy            | Prevents                         |
| ----------------- | -------------------------------- |
| No Privileged     | `privileged: true`               |
| No Host Network   | `hostNetwork: true`, host ports  |
| No Host PID/IPC   | `hostPID: true`, `hostIPC: true` |
| No Root User      | `runAsUser: 0`                   |
| Read-Only FS      | Writable root filesystem         |
| Drop Capabilities | Dangerous Linux capabilities     |
