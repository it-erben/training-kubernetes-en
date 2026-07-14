# Demo 3: Required Labels

This demo shows how to use Azure Policy to enforce specific labels on all Kubernetes resources.

## Use case

- **Cost allocation**: `cost-center`, `project` labels for chargeback
- **Ownership**: `owner`, `team` labels for responsibilities
- **Environment**: `env` label for separating environments
- **Compliance**: traceability of who deployed what

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
# Find the policy for required labels
az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster pods should use specified labels')].{Name:displayName, ID:name}" \
  --output table

export LABELS_POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster pods should use specified labels')].name" \
  --output tsv | head -1)

echo "Labels Policy ID: $LABELS_POLICY_ID"

# Show policy details
az policy definition show --name $LABELS_POLICY_ID
```

---

## 3. Assign the policy

```bash
# Assign the policy for required labels
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-required-labels" \
  --display-name "AKS: Pods must have specific labels" \
  --policy $LABELS_POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "labelsList": {"value": ["app", "owner", "env"]},
    "effect": {"value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc", "kube-node-lease", "kube-public"]}
  }'

echo "Policy assigned. Waiting for synchronization (2-3 minutes)..."
sleep 120
```

**Required labels:**

- `app` - name of the application
- `owner` - responsible team/person
- `env` - environment (dev, staging, prod)

---

## 4. Create the test namespace

```bash
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
```

---

## 5. Test a pod WITHOUT labels (should fail)

```bash
# Pod without the required labels
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: no-labels-pod
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
EOF

# Expected error message:
# Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request:
# [azurepolicy-psp-pod-labels-...] you must provide labels: {"app", "env", "owner"}
```

---

## 6. Test a pod with PARTIAL labels (should fail)

```bash
# Pod with only some of the labels
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: partial-labels-pod
  labels:
    app: my-app
    # owner is missing!
    # env is missing!
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
EOF

# Expected error message - missing owner and env labels
```

---

## 7. Test a pod with ALL labels (should work)

```bash
# Pod with all required labels
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: valid-labels-pod
  labels:
    app: demo-app
    owner: team-platform
    env: development
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

# Should succeed
kubectl get pod -n $NAMESPACE valid-labels-pod --show-labels
```

---

## 8. Test a Deployment with labels

For Deployments, the labels must be in the pod template:

```bash
kubectl apply -n $NAMESPACE -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: labeled-deployment
  labels:
    app: labeled-app
    owner: team-platform
    env: development
spec:
  replicas: 2
  selector:
    matchLabels:
      app: labeled-app
  template:
    metadata:
      labels:
        # These labels are checked by the policy!
        app: labeled-app
        owner: team-platform
        env: development
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

kubectl get deployment -n $NAMESPACE labeled-deployment
kubectl get pods -n $NAMESPACE -l app=labeled-app --show-labels
```

---

## 9. Validating label values (custom policy)

The built-in policy only checks whether labels exist. Validating values requires custom policies:

```bash
# Example: custom ConstraintTemplate for label values
# (Deployed via Azure Policy as a custom policy)

cat << 'EOF'
# This policy would be deployed as a custom Gatekeeper constraint:
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8svalidlabelvalues
spec:
  crd:
    spec:
      names:
        kind: K8sValidLabelValues
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: object
                properties:
                  key:
                    type: string
                  allowedValues:
                    type: array
                    items:
                      type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8svalidlabelvalues

        violation[{"msg": msg}] {
          input.review.kind.kind == "Pod"
          label := input.parameters.labels[_]
          value := input.review.object.metadata.labels[label.key]
          not contains(label.allowedValues, value)
          msg := sprintf("Label %v has invalid value %v. Allowed: %v", [label.key, value, label.allowedValues])
        }

        contains(arr, elem) {
          arr[_] == elem
        }
EOF
```

---

## 10. Recommended label conventions

### Standard Kubernetes labels

```yaml
labels:
  # Kubernetes recommended labels (kubernetes.io/...)
  app.kubernetes.io/name: "nginx"
  app.kubernetes.io/instance: "nginx-prod"
  app.kubernetes.io/version: "1.27.0"
  app.kubernetes.io/component: "webserver"
  app.kubernetes.io/part-of: "website"
  app.kubernetes.io/managed-by: "helm"
```

### Company-specific labels

```yaml
labels:
  # Ownership
  owner: "team-platform"
  contact: "platform@example.com"

  # Cost Allocation
  cost-center: "CC-12345"
  project: "website-redesign"

  # Environment
  env: "production"  # dev, staging, production

  # Compliance
  data-classification: "internal"  # public, internal, confidential, restricted
  pii: "false"  # true/false - contains personally identifiable data
```

---

## 11. Labels for different resource types

```bash
# Show all resources in a namespace with their labels
kubectl get all -n $NAMESPACE --show-labels

# Filter resources by label
kubectl get pods -n $NAMESPACE -l "env=development"
kubectl get pods -n $NAMESPACE -l "owner=team-platform"

# Find resources without a specific label (for a compliance check)
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.metadata.labels.owner == null) |
  "\(.metadata.namespace)/\(.metadata.name)"
'
```

---

## 12. Check compliance status

```bash
# Non-compliant pods
az policy state list \
  --resource $AKS_ID \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[?contains(policyDefinitionName, 'label')].{Resource:resourceId}" \
  --output table

# Constraint status in the cluster
kubectl get constraints -o wide
```

---

## 13. Cleanup

```bash
# Delete the test resources
kubectl delete namespace $NAMESPACE --ignore-not-found

# Delete the policy assignment
az policy assignment delete \
  --name "aks-required-labels" \
  --scope $AKS_ID

echo "Cleanup complete!"
```

---

## Best Practices

1. **Consistent naming convention** - Define team-wide standards
2. **Not too many mandatory labels** - 3-5 are usually enough
3. **Automation** - CI/CD pipelines should set labels automatically
4. **Documentation** - Document the label schema
5. **Use namespaces** - Often better than labels for env separation

## Summary

| Aspect        | Value                                               |
| ------------- | --------------------------------------------------- |
| **Policy**    | Kubernetes cluster pods should use specified labels |
| **Effect**    | Deny                                                |
| **Parameter** | `labelsList` (array of required labels)             |
| **Scope**     | Pod labels (in the template for Deployments)        |
