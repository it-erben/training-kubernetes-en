# AKS Automatic with ARM Templates

This demo shows how to create an **AKS Automatic cluster** with **Azure Resource Manager (ARM) templates**.

## Prerequisites

- Azure CLI (logged in)
- Azure subscription with sufficient permissions

```bash
# Check the Azure CLI version
az version

# Log in (if not already done)
az login

# Set the subscription
az account set --subscription "name-or-id"
```

---

## 1. What are ARM templates?

**ARM templates** are the native Azure approach to Infrastructure as Code:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    ARM Template (JSON)                          │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ parameters  │  │  variables  │  │  resources  │             │
│  │             │  │             │  │             │             │
│  │ - Inputs    │  │ - Computed  │  │ - Azure     │             │
│  │ - Defaults  │  │   values    │  │   resources │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│                         ▼                                       │
│                  Azure Resource Manager                         │
│                         ▼                                       │
│            ┌───────────────────────┐                           │
│            │   Azure resources     │                           │
│            │   (AKS, ACR, etc.)    │                           │
│            └───────────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

**Advantages:**

- Native Azure solution (no additional tool)
- Full Azure feature support
- Idempotent (can be applied repeatedly)
- What-if mode for previews
- Integration with Azure DevOps and GitHub Actions

**Disadvantages:**

- Verbose JSON syntax
- No loops/conditionals like in Terraform
- Azure only (not multi-cloud)

---

## 2. Project structure

```text
04-arm-template/
├── README.md                        # This guide
├── azuredeploy.json                 # ARM template
├── azuredeploy.parameters.json      # Parameter values
└── azuredeploy.parameters.example.json  # Example parameters
```

---

## 3. Quick start

```bash
# Change into the directory
cd demos/aks/04-arm-template

# Set variables
export RESOURCE_GROUP="rg-aks-arm-template"
export LOCATION="germanywestcentral"

# 1. Create the resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# 2. Adjust the parameter file
cp azuredeploy.parameters.example.json azuredeploy.parameters.json
# Then edit azuredeploy.parameters.json

# 3. Validate the deployment (dry run)
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# 4. Show what-if (what will be created/changed?)
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# 5. Run the deployment
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --name "aks-automatic-deployment"

# 6. Fetch the outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --query "properties.outputs"

# 7. Get the kubeconfig
CLUSTER_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --query "properties.outputs.clusterName.value" -o tsv)

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# 8. Assign the RBAC role (for Azure RBAC)
USER_ID=$(az ad signed-in-user show --query id -o tsv)
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv)

az role assignment create \
  --assignee $USER_ID \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $AKS_ID

# 9. Test the connection
kubectl get nodes
```

---

## 4. What gets created?

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Resource Group                               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              AKS Automatic Cluster                       │  │
│  │                                                          │  │
│  │  Configured automatically:                               │  │
│  │  ✅ Azure CNI Overlay + Cilium                          │  │
│  │  ✅ Node Auto-Provisioning (NAP/Karpenter)              │  │
│  │  ✅ HPA, VPA, KEDA                                      │  │
│  │  ✅ Key Vault Secrets Provider                          │  │
│  │  ✅ Managed NGINX Ingress                               │  │
│  │  ✅ Azure Policy & Deployment Safeguards                │  │
│  │  ✅ Automatic upgrades                                  │  │
│  │  ✅ Workload Identity                                   │  │
│  │  ✅ Azure RBAC                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌────────────────────┐                                        │
│  │  Log Analytics     │                                        │
│  │  Workspace         │                                        │
│  └────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Adjusting parameters

### 5.1 Editing the parameter file

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "clusterName": {
      "value": "aks-automatic-cluster"
    },
    "location": {
      "value": "germanywestcentral"
    },
    "nodeVmSize": {
      "value": "Standard_D4s_v3"
    },
    "tags": {
      "value": {
        "Environment": "Training",
        "Project": "AKS-Training"
      }
    }
  }
}
```

### 5.2 Passing parameters inline

```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters clusterName="my-cluster" location="germanywestcentral"
```

### 5.3 Available parameters

| Parameter           | Description                    | Default                 |
| ------------------- | ------------------------------ | ----------------------- |
| `clusterName`       | Name of the AKS cluster        | `aks-automatic-cluster` |
| `location`          | Azure region                   | `germanywestcentral`    |
| `nodeVmSize`        | VM size for nodes              | `Standard_D8s_v3`       |
| `kubernetesVersion` | K8s version (empty = latest)   | `""`                    |
| `tags`              | Tags for resources             | `{}`                    |

---

## 6. Deployment commands

### Validate

```bash
# Validate the template syntax
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

### What-if (preview)

```bash
# Shows what will be created/changed/deleted
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

### Create/update

```bash
# Run the deployment (idempotent)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --name "aks-deployment-$(date +%Y%m%d-%H%M%S)"
```

### Fetch outputs

```bash
# All outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --query "properties.outputs"

# Single output
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --query "properties.outputs.clusterName.value" -o tsv
```

### Checking deployment status

```bash
# Show running deployments
az deployment group list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Details of a deployment
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment"

# Deployment operations (for debugging)
az deployment operation group list \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --output table
```

---

## 7. Making changes

ARM templates are **idempotent** - you can run them multiple times:

### 7.1 Changing parameters

```bash
# Edit the parameter file, then deploy again
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --name "aks-update-$(date +%Y%m%d-%H%M%S)"
```

### 7.2 Upgrading the Kubernetes version

```json
{
  "parameters": {
    "kubernetesVersion": {
      "value": "1.31"
    }
  }
}
```

```bash
# What-if shows the upgrade
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

---

## 8. Comparison: ARM vs. Bicep vs. Terraform

| Aspect             | ARM              | Bicep            | Terraform       |
| ------------------ | ---------------- | ---------------- | --------------- |
| **Syntax**         | JSON (verbose)   | DSL (compact)    | HCL             |
| **Learning curve** | Steep            | Gentle           | Moderate        |
| **Multi-cloud**    | No               | No               | Yes             |
| **State**          | Managed by Azure | Managed by Azure | Local/remote    |
| **Tooling**        | Azure CLI        | Azure CLI        | Terraform CLI   |
| **IDE support**    | Good             | Very good        | Very good       |

### Bicep equivalent (for reference)

```bicep
// main.bicep - more compact than ARM JSON
resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  properties: {
    agentPoolProfiles: [{
      name: 'systempool'
      mode: 'System'
      vmSize: nodeVmSize
      count: 3
    }]
  }
}
```

```bash
# Convert Bicep to ARM
az bicep build --file main.bicep
```

---

## 9. CI/CD with GitHub Actions

Example `.github/workflows/arm-deploy.yml`:

```yaml
name: 'Deploy AKS with ARM'

on:
  push:
    branches: [main]
    paths: ['demos/aks/04-arm-template/**']

env:
  RESOURCE_GROUP: rg-aks-arm-template
  LOCATION: germanywestcentral

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Create Resource Group
        run: |
          az group create \
            --name ${{ env.RESOURCE_GROUP }} \
            --location ${{ env.LOCATION }}

      - name: Validate Template
        run: |
          az deployment group validate \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --template-file demos/aks/04-arm-template/azuredeploy.json \
            --parameters @demos/aks/04-arm-template/azuredeploy.parameters.json

      - name: What-If
        run: |
          az deployment group what-if \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --template-file demos/aks/04-arm-template/azuredeploy.json \
            --parameters @demos/aks/04-arm-template/azuredeploy.parameters.json

      - name: Deploy
        run: |
          az deployment group create \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --template-file demos/aks/04-arm-template/azuredeploy.json \
            --parameters @demos/aks/04-arm-template/azuredeploy.parameters.json \
            --name "aks-deploy-${{ github.run_number }}"
```

---

## 10. Troubleshooting

### Common errors

| Error                       | Cause                        | Solution                        |
| --------------------------- | ---------------------------- | ------------------------------- |
| `InvalidTemplateDeployment` | Syntax error in the template | `az deployment group validate`  |
| `QuotaExceeded`             | vCPU limit reached           | Increase quota in the portal    |
| `LinkedAuthorizationFailed` | Missing permission           | Check the role                  |
| `ResourceNotFound`          | Resource does not exist      | Check the resource group        |

### Debugging deployment errors

```bash
# Show detailed errors
az deployment operation group list \
  --resource-group $RESOURCE_GROUP \
  --name "aks-automatic-deployment" \
  --query "[?properties.provisioningState=='Failed']"

# Check the activity log
az monitor activity-log list \
  --resource-group $RESOURCE_GROUP \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --output table
```

---

## 11. Cleanup

```bash
# Delete the entire resource group (including all resources)
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait

# Check the status
az group show --name $RESOURCE_GROUP --query "properties.provisioningState"
```

---

## Summary

| Aspect                 | Value                        |
| ---------------------- | ---------------------------- |
| **Cluster type**       | AKS Automatic                |
| **IaC tool**           | ARM template (JSON)          |
| **Deployment method**  | `az deployment group create` |
| **Idempotent**         | Yes                          |
| **Preview**            | `what-if`                    |

**AKS Automatic features (enabled automatically):**

- Node Auto-Provisioning (Karpenter)
- Azure CNI Overlay + Cilium
- Workload Identity + OIDC
- Key Vault Secrets Provider
- Azure Policy + Deployment Safeguards
- Automatic upgrades
- Managed Prometheus & Grafana (optional)
