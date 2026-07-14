# Solution: AKS Cluster Setup

## Part 1: Create the resource group

```bash
az group create \
  --name rg-aks-training-ab \
  --location germanywestcentral
```

---

## Part 2: Create the AKS Automatic cluster

```bash
az aks create \
  --resource-group rg-aks-training-ab \
  --name aks-training-ab \
  --sku automatic \
  --enable-azure-monitor-metrics
```

> **Note:** Creation takes about 5-10 minutes. The `automatic` SKU
> automatically enables node autoprovisioning, workload autoscaling, and
> preconfigured best practices.

---

## Part 3: Configure kubectl

```bash
# Set variables
export RG="rg-aks-training-ab"
export CLUSTER_NAME="aks-training-ab"

# Get credentials
az aks get-credentials \
  --resource-group $RG \
  --name $CLUSTER

# Determine the user object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Determine the AKS resource ID
AKS_ID=$(az aks show \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --query id \
  -o tsv)

# Assign the RBAC admin role
az role assignment create \
  --assignee $USER_OBJECT_ID \
  --role "Azure Kubernetes Service RBAC Admin" \
  --scope $AKS_ID

# Wait 60 seconds
sleep 60

# Test the connection
kubectl get nodes
```

---

## Expected output of `kubectl get nodes`

```text
NAME                                STATUS   ROLES    AGE   VERSION
aks-nodepool1-xxxxxxxx-vmss000000   Ready    <none>   5m    v1.29.x
```

With AKS Automatic you initially see one node; more are provisioned
automatically as needed.
