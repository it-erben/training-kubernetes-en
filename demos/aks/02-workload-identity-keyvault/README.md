# Workload Identity with Azure Key Vault

This demo shows how to use **Workload Identity** to securely load secrets from an **Azure Key Vault**
into pods – entirely without passwords or service account keys.

## Prerequisites

- AKS Automatic cluster (already has Workload Identity & Key Vault Secrets Provider enabled)
- Azure CLI with the `aks-preview` extension
- Existing variables from 01-setup:

```bash
export RESOURCE_GROUP="rg-aks-keyvault-demo"
export CLUSTER_NAME="cluster-keyvault-demo"
export LOCATION="germanywestcentral"
```

---

## 1. What is Workload Identity?

**Workload Identity** is the recommended way to give pods in AKS access to Azure resources:

```text
┌─────────────────────────────────────────────────────────────────┐
│                         AKS Cluster                             │
│  ┌──────────────┐     ┌────────────────────────────────────┐   │
│  │     Pod      │     │     Kubernetes ServiceAccount      │   │
│  │              │────►│ (with Workload Identity annotation) │   │
│  └──────────────┘     └────────────────────────────────────┘   │
│                                      │                          │
└──────────────────────────────────────│──────────────────────────┘
                                       │ Federated Identity
                                       ▼
                        ┌──────────────────────────┐
                        │  User-Assigned Managed   │
                        │       Identity           │
                        └──────────────────────────┘
                                       │ RBAC
                                       ▼
                        ┌──────────────────────────┐
                        │     Azure Key Vault      │
                        │   (Secrets, Keys, Certs) │
                        └──────────────────────────┘
```

**Advantages over Pod Identity (deprecated):**

- No CRDs or webhooks required
- Works with Azure AD Federated Credentials
- No node-level permissions
- Compatible with all pod types (including Jobs, CronJobs)

---

## 2. Set environment variables

```bash
# Unique suffix for resources
export SUFFIX=$(openssl rand -hex 4)

# Key Vault
export KEYVAULT_NAME="kv-aks-demo-${SUFFIX}"

# Managed Identity
export IDENTITY_NAME="id-aks-workload-${SUFFIX}"

# Kubernetes
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export NAMESPACE="workload-identity-demo"

# Fetch the AKS OIDC issuer URL
export AKS_OIDC_ISSUER=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query "oidcIssuerProfile.issuerUrl" \
  --output tsv)

echo "OIDC Issuer: $AKS_OIDC_ISSUER"
```

---

## 3. Create the Azure Key Vault

```bash
# Create the Key Vault
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-rbac-authorization

# IMPORTANT: With RBAC authorization you first have to grant yourself permissions!
# Fetch the Key Vault ID
export KEYVAULT_ID=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "id" \
  --output tsv)

# Assign the "Key Vault Secrets Officer" role to the current user
export CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)

az role assignment create \
  --assignee $CURRENT_USER_ID \
  --role "Key Vault Secrets Officer" \
  --scope $KEYVAULT_ID

echo "Waiting for RBAC propagation (30 seconds)..."
sleep 30

# Add a demo secret
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "demo-secret" \
  --value "Hello-from-the-KeyVault-$(date +%Y%m%d)"

# Another secret for the demo
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "db-password" \
  --value "SuperSecret123"

echo "Key Vault created: $KEYVAULT_NAME"
```

> **Note:** With `--enable-rbac-authorization`, the creator of the Key Vault has
> **no automatic permissions** on secrets. The RBAC role has to be assigned
> explicitly. "Key Vault Secrets Officer" allows reading and writing secrets.

---

## 4. Create the User-Assigned Managed Identity

```bash
# Create the Managed Identity
az identity create \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Fetch the client ID and principal ID
export IDENTITY_CLIENT_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "clientId" \
  --output tsv)

export IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "principalId" \
  --output tsv)

echo "Identity Client ID: $IDENTITY_CLIENT_ID"
```

---

## 5. Grant Key Vault permissions

```bash
# Fetch the Key Vault ID
export KEYVAULT_ID=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "id" \
  --output tsv)

# Give the Managed Identity access to secrets
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope $KEYVAULT_ID

echo "RBAC role assigned. Waiting for propagation (30 seconds)..."
sleep 30
```

---

## 6. Create the Federated Identity Credential

This is the key part: the federated credential links the Kubernetes ServiceAccount
to the Azure Managed Identity.

```bash
az identity federated-credential create \
  --name "federated-${NAMESPACE}-${SERVICE_ACCOUNT_NAME}" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
  --audience "api://AzureADTokenExchange"

echo "Federated credential created!"
```

---

## 7. Deploy the Kubernetes resources

### 7.1 Create the namespace and ServiceAccount

```bash
# Create the namespace
kubectl create namespace $NAMESPACE

# ServiceAccount with the Workload Identity annotation
kubectl apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${NAMESPACE}
  annotations:
    azure.workload.identity/client-id: "${IDENTITY_CLIENT_ID}"
  labels:
    azure.workload.identity/use: "true"
EOF
```

### 7.2 Create the SecretProviderClass

The SecretProviderClass defines which secrets are loaded from the Key Vault:

```bash
# Fetch the tenant ID
export TENANT_ID=$(az account show --query tenantId -o tsv)

kubectl apply -f - << EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: ${NAMESPACE}
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "${IDENTITY_CLIENT_ID}"
    keyvaultName: "${KEYVAULT_NAME}"
    tenantId: "${TENANT_ID}"
    objects: |
      array:
        - |
          objectName: demo-secret
          objectType: secret
        - |
          objectName: db-password
          objectType: secret
  # Optional: also sync the secrets as a Kubernetes Secret
  secretObjects:
    - secretName: synced-secrets
      type: Opaque
      data:
        - objectName: demo-secret
          key: DEMO_SECRET
        - objectName: db-password
          key: DB_PASSWORD
EOF
```

### 7.3 Deploy the demo pod

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: keyvault-demo
  namespace: ${NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  containers:
    - name: demo
      image: busybox:1.36
      command:
        - "/bin/sh"
        - "-c"
        - |
          echo "=== Secrets from Key Vault (as files) ==="
          echo "demo-secret: \$(cat /mnt/secrets-store/demo-secret)"
          echo "db-password: \$(cat /mnt/secrets-store/db-password)"
          echo ""
          echo "=== Secrets from Kubernetes Secret (as Env Vars) ==="
          echo "DEMO_SECRET: \$DEMO_SECRET"
          echo "DB_PASSWORD: \$DB_PASSWORD"
          echo ""
          echo "=== Success! Sleeping now... ==="
          sleep 3600
      env:
        - name: DEMO_SECRET
          valueFrom:
            secretKeyRef:
              name: synced-secrets
              key: DEMO_SECRET
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: synced-secrets
              key: DB_PASSWORD
      volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets-store"
          readOnly: true
      readinessProbe:
          exec:
            command: ["echo", "true"]
          initialDelaySeconds: 5  # Wait time before the first check
          periodSeconds: 3       # Interval between checks
      livenessProbe:
          exec:
            command: ["echo", "true"]
          initialDelaySeconds: 5  # Wait time before the first check
          periodSeconds: 3       # Interval between checks
      resources:
        requests:
          cpu: "50m"
          memory: "64Mi"
        limits:
          cpu: "100m"
          memory: "128Mi"
  volumes:
    - name: secrets-store
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-keyvault-secrets"
EOF
```

---

## 8. Verify the result

```bash
# Wait until the pod is running
kubectl wait --for=condition=Ready pod/keyvault-demo -n $NAMESPACE --timeout=120s

# Show the logs
kubectl logs keyvault-demo -n $NAMESPACE

# Check the secrets in the pod
kubectl exec -n $NAMESPACE keyvault-demo -- ls -la /mnt/secrets-store/

# Show the secret content
kubectl exec -n $NAMESPACE keyvault-demo -- cat /mnt/secrets-store/demo-secret

# Check the synced Kubernetes Secret
kubectl get secret synced-secrets -n $NAMESPACE -o yaml
```

**Expected output:**

```text
=== Secrets from Key Vault (as files) ===
demo-secret: Hello-from-the-KeyVault-20250127
db-password: SuperSecret123!

=== Secrets from Kubernetes Secret (as Env Vars) ===
DEMO_SECRET: Hello-from-the-KeyVault-20250127
DB_PASSWORD: SuperSecret123!

=== Success! Sleeping now... ===
```

---

## 9. Change the secret in the Key Vault (live demo)

Show how secrets get updated:

```bash
# Change the secret in the Key Vault
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "demo-secret" \
  --value "New-value-$(date +%H%M%S)"

# Restart the pod (secrets are refreshed on mount)
kubectl delete pod keyvault-demo -n $NAMESPACE

# Recreate the pod (repeat the YAML from above)
# ...

# After ~30 seconds: check the new value
kubectl logs keyvault-demo -n $NAMESPACE
```

> **Note:** The CSI-driver-based solution does **not** automatically refresh secrets
> in a running pod. For automatic updates the pod has to be restarted,
> or you use a rotation poll interval.

---

## 10. Deployment example (more realistic)

For a more realistic use case:

```bash
kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-with-secrets
  namespace: ${NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp-with-secrets
  template:
    metadata:
      labels:
        app: webapp-with-secrets
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: ${SERVICE_ACCOUNT_NAME}
      containers:
        - name: webapp
          image: nginx:1.27
          ports:
            - containerPort: 80
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: synced-secrets
                  key: DB_PASSWORD
          volumeMounts:
            - name: secrets-store
              mountPath: "/mnt/secrets-store"
              readOnly: true
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
      volumes:
        - name: secrets-store
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "azure-keyvault-secrets"
EOF

# Check the status
kubectl get pods -n $NAMESPACE -l app=webapp-with-secrets
```

---

## 11. Troubleshooting

### Pod does not start / SecretProviderClass errors

```bash
# Check the events
kubectl describe pod keyvault-demo -n $NAMESPACE

# CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50

# Secrets Store Provider Azure logs
kubectl logs -n kube-system -l app=csi-secrets-store-provider-azure --tail=50
```

### Common errors

| Error | Cause | Solution |
| --- | --- | --- |
| `no matching federated identity` | Federated credential missing | Check the subject |
| `access denied` | RBAC role missing | Assign "Key Vault Secrets User" |
| `keyvault not found` | Key Vault name wrong | Check `$KEYVAULT_NAME` |
| `secret not found` | Secret does not exist | Check `az keyvault secret list` |

### Check the Federated Credential

```bash
az identity federated-credential list \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --output table
```

---

## 12. Cleanup

```bash
# Delete the Kubernetes resources
kubectl delete namespace $NAMESPACE

# Delete the Azure resources
az keyvault delete --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP
az keyvault purge --name $KEYVAULT_NAME --location $LOCATION  # Remove the soft delete
az identity delete --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP

echo "Cleanup complete!"
```

---

## Summary

| Component                          | Purpose                                          |
| ---------------------------------- | ------------------------------------------------ |
| **User-Assigned Managed Identity** | Azure identity for the workload                  |
| **Federated Identity Credential**  | Links the K8s ServiceAccount to the Azure identity |
| **Key Vault**                      | Stores secrets securely in Azure                 |
| **ServiceAccount**                 | K8s identity with the Workload Identity annotation |
| **SecretProviderClass**            | Defines which secrets are loaded                 |
| **CSI Volume**                     | Mounts secrets as files into the pod             |

**Best Practices:**

1. **One ServiceAccount per workload** - Do not share between different apps
2. **Least privilege** - Only "Key Vault Secrets User", not "Key Vault Administrator"
3. **Separate namespaces** - Different environments in different namespaces
4. **Secret rotation** - Rotate secrets regularly, redeploy pods
5. **Audit logging** - Enable Key Vault diagnostic logs
