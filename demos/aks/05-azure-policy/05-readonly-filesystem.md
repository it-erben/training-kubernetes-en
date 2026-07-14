# Demo 5: Read-Only Root Filesystem

This demo shows how to use Azure Policy to enforce that containers have a read-only root filesystem.

## Use case

- **Immutable infrastructure** - containers should not be modified at runtime
- **Malware prevention** - prevents attackers from writing files
- **Compliance** - many security standards require immutable containers
- **Forensics** - changes are easier to trace

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

```bash
# Find the read-only filesystem policy
az policy definition list \
  --query "[?contains(displayName, 'read only root file system')].{Name:displayName, ID:name}" \
  --output table

export READONLY_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers should run with a read only root file system')].name" \
  --output tsv | head -1)

echo "ReadOnly Policy ID: $READONLY_POLICY_ID"
```

---

## 3. Assign the policy

```bash
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-readonly-filesystem" \
  --display-name "AKS: Read-Only Root Filesystem" \
  --policy $READONLY_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]}
  }'

echo "Policy assigned. Waiting for synchronization (2-3 minutes)..."
sleep 120
```

---

## 4. Create the test namespace

```bash
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
```

---

## 5. Test a container WITHOUT a read-only FS (should fail)

```bash
# Container without readOnlyRootFilesystem
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: writable-fs-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    # No readOnlyRootFilesystem!
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
# [azurepolicy-psp-readonlyrootfilesystem-...] only read-only root filesystem container is allowed
```

---

## 6. Test a container with explicit `false` (should fail)

```bash
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: explicit-writable-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    securityContext:
      readOnlyRootFilesystem: false  # Explicitly false - not allowed!
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
EOF
```

---

## 7. Test a container WITH a read-only FS (basic)

```bash
# Simple test - but this would fail with nginx because nginx wants to write
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: readonly-basic-pod
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sh", "-c", "echo 'Running with read-only filesystem' && sleep 3600"]
    securityContext:
      readOnlyRootFilesystem: true
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

kubectl get pod -n $NAMESPACE readonly-basic-pod
```

---

## 8. Nginx with a read-only FS (with emptyDir volumes)

Nginx needs writable directories. The solution: emptyDir volumes.

```bash
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: readonly-nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    securityContext:
      readOnlyRootFilesystem: true
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
    volumeMounts:
    # Nginx needs these directories for writing
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
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
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
EOF

kubectl get pod -n $NAMESPACE readonly-nginx-pod
kubectl exec -n $NAMESPACE readonly-nginx-pod -- curl -s localhost
```

---

## 9. Test: Writing to the root FS fails

```bash
# Try to write to the root filesystem
kubectl exec -n $NAMESPACE readonly-nginx-pod -- touch /test-file

# Expected error message:
# touch: /test-file: Read-only file system

# But we can write to the emptyDir
kubectl exec -n $NAMESPACE readonly-nginx-pod -- touch /tmp/test-file
kubectl exec -n $NAMESPACE readonly-nginx-pod -- ls -la /tmp/test-file
```

---

## 10. Production example: App with a database client

```bash
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readonly-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: readonly-app
  template:
    metadata:
      labels:
        app: readonly-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: app
        image: nginx:1.27
        securityContext:
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        ports:
        - containerPort: 8080
        volumeMounts:
        # Temporary files
        - name: tmp
          mountPath: /tmp
        # Nginx-specific
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
        # App logs (if the app writes logs)
        - name: logs
          mountPath: /var/log/app
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
        emptyDir:
          sizeLimit: 100Mi
      - name: cache
        emptyDir:
          sizeLimit: 100Mi
      - name: run
        emptyDir:
          sizeLimit: 10Mi
      - name: logs
        emptyDir:
          sizeLimit: 500Mi
EOF

kubectl get deployment -n $NAMESPACE readonly-app
kubectl get pods -n $NAMESPACE -l app=readonly-app
```

---

## 11. Common applications and their volume requirements

| Application | Required writable paths |
| --- | --- |
| **Nginx** | `/tmp`, `/var/cache/nginx`, `/var/run` |
| **Apache** | `/tmp`, `/var/run/apache2`, `/var/log/apache2` |
| **Node.js** | `/tmp`, possibly `/app/node_modules/.cache` |
| **Python** | `/tmp`, `/.cache`, possibly `/__pycache__` |
| **Java** | `/tmp`, possibly `/app/logs` |
| **PostgreSQL** | `/var/run/postgresql`, `/tmp` (+ data volume!) |
| **Redis** | `/data`, `/tmp` |

---

## 12. emptyDir with size limits and memory backend

```bash
# emptyDir with a size limit
volumes:
- name: cache
  emptyDir:
    sizeLimit: 500Mi  # Limits storage consumption

# emptyDir in memory (faster, but counts against the memory limit!)
volumes:
- name: fast-cache
  emptyDir:
    medium: Memory
    sizeLimit: 100Mi
```

---

## 13. Check compliance status

```bash
# Non-compliant pods (without readOnlyRootFilesystem)
az policy state list \
  --resource $AKS_ID \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[?contains(policyDefinitionName, 'readOnly') || contains(policyDefinitionName, 'ReadOnly')].{Resource:resourceId}" \
  --output table

# Gatekeeper constraint status
kubectl get constraints -o wide
```

---

## 14. Cleanup

```bash
# Delete the test resources
kubectl delete namespace $NAMESPACE --ignore-not-found

# Delete the policy
az policy assignment delete \
  --name "aks-readonly-filesystem" \
  --scope $AKS_ID

echo "Cleanup complete!"
```

---

## Cheatsheet: Read-Only Pattern

```yaml
# Minimal read-only setup
spec:
  containers:
  - name: app
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}

# Complete secure setup
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache
  volumes:
  - name: tmp
    emptyDir:
      sizeLimit: 100Mi
  - name: cache
    emptyDir:
      sizeLimit: 500Mi
```

## Summary

| Aspect              | Value                                                                       |
| ------------------- | -------------------------------------------------------------------------- |
| **Policy**          | Kubernetes cluster containers should run with a read only root file system |
| **Effect**          | Deny                                                                       |
| **Solution for apps** | emptyDir volumes for writable paths                                       |
| **Best practice**   | Set size limits on emptyDir                                                |
