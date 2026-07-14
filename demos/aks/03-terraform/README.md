# AKS Standard Cluster with Terraform

This demo shows how to create and manage an **AKS Standard cluster** with **Terraform**.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- Azure CLI (logged in)
- Azure subscription with sufficient permissions

```bash
# Install Terraform (macOS)
brew install terraform

# Or via tfenv (recommended for version management)
brew install tfenv
tfenv install 1.9.0
tfenv use 1.9.0

# Check the version
terraform version
```

---

## 1. Project structure

```text
03-terraform/
├── README.md           # This guide
├── main.tf             # Main configuration (provider, resources)
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── terraform.tfvars    # Variable values (do not commit!)
└── .gitignore          # Terraform-specific ignores
```

---

## 2. Quick start

```bash
# Change into the Terraform directory
cd demos/aks/03-terraform

# 1. Adjust the variables
cp terraform.tfvars.example terraform.tfvars
# Then edit terraform.tfvars

# 2. Initialize Terraform
terraform init

# 3. Show the plan (what will be created?)
terraform plan

# 4. Create the cluster
terraform apply

# 5. Get the kubeconfig
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)

# 6. Test the connection
kubectl get nodes
```

---

## 3. What gets created?

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Resource Group                               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   AKS Cluster                            │  │
│  │                                                          │  │
│  │  ┌─────────────────┐  ┌─────────────────┐               │  │
│  │  │  System Pool    │  │   User Pool     │               │  │
│  │  │  (2 Nodes)      │  │   (Autoscaling) │               │  │
│  │  │  Standard_D2s_v3│  │   1-5 Nodes     │               │  │
│  │  └─────────────────┘  └─────────────────┘               │  │
│  │                                                          │  │
│  │  Features:                                               │  │
│  │  - Azure CNI Overlay + Cilium                           │  │
│  │  - Cluster Autoscaler                                   │  │
│  │  - Azure RBAC                                           │  │
│  │  - Container Insights                                   │  │
│  │  - Key Vault Secrets Provider                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌────────────────────┐  ┌────────────────────┐                │
│  │  Log Analytics     │  │  Container         │                │
│  │  Workspace         │  │  Registry (ACR)    │                │
│  └────────────────────┘  └────────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Adjusting the configuration

### 4.1 Variables in terraform.tfvars

```hcl
# Base configuration
resource_group_name = "rg-aks-terraform"
location            = "germanywestcentral"
cluster_name        = "aks-terraform-cluster"

# Kubernetes version (optional, otherwise current stable)
kubernetes_version  = "1.30"

# Node pool configuration
system_node_count   = 2
system_node_vm_size = "Standard_D2s_v3"

user_node_min_count = 1
user_node_max_count = 5
user_node_vm_size   = "Standard_D4s_v3"

# Features
enable_azure_policy     = true
enable_key_vault_provider = true

# Tags
tags = {
  Environment = "Training"
  Project     = "AKS-Training"
  ManagedBy   = "Terraform"
}
```

### 4.2 Selecting a Kubernetes version

```bash
# Show available versions
az aks get-versions --location germanywestcentral --output table

# Current default version
az aks get-versions --location germanywestcentral \
  --query "values[?isDefault].version" -o tsv
```

---

## 5. Terraform commands

### Basic workflow

```bash
# Initialize (download providers)
terraform init

# Check and fix formatting
terraform fmt

# Validate the configuration
terraform validate

# Show changes (dry run)
terraform plan

# Apply changes
terraform apply

# Apply only a specific resource
terraform apply -target=azurerm_kubernetes_cluster.aks

# Approve automatically (for CI/CD)
terraform apply -auto-approve
```

### Managing state

```bash
# Show the state
terraform state list

# Show a resource in the state
terraform state show azurerm_kubernetes_cluster.aks

# Import into the state from remote (for an existing cluster)
terraform import azurerm_kubernetes_cluster.aks \
  /subscriptions/xxx/resourceGroups/rg-aks/providers/Microsoft.ContainerService/managedClusters/aks-cluster
```

### Cleanup

```bash
# Delete all resources
terraform destroy

# Delete only a specific resource
terraform destroy -target=azurerm_kubernetes_cluster_node_pool.user
```

---

## 6. Making changes to the cluster

### 6.1 Scaling a node pool

```hcl
# Change in variables.tf or terraform.tfvars:
user_node_max_count = 10  # Was 5 before
```

```bash
terraform plan   # Shows: 1 to change
terraform apply
```

### 6.2 Adding a new node pool

Add this to `main.tf`:

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D4s_v3"

  # Spot Instances
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = -1  # Market price

  # Autoscaling
  auto_scaling_enabled = true
  min_count            = 0
  max_count            = 10

  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  tags = var.tags
}
```

### 6.3 Upgrading Kubernetes

```hcl
# In terraform.tfvars:
kubernetes_version = "1.31"
```

```bash
terraform plan   # Shows the upgrade
terraform apply  # Performs a rolling upgrade
```

---

## 7. Remote state (recommended for teams)

If you're working in a team, store the Terraform state in Azure Storage:

### 7.1 Creating a storage account

```bash
# Variables
STORAGE_RG="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"

# Resource Group
az group create --name $STORAGE_RG --location germanywestcentral

# Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $STORAGE_RG \
  --sku Standard_LRS \
  --encryption-services blob

# Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

echo "Storage Account: $STORAGE_ACCOUNT"
```

### 7.2 Configuring the backend

Create `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstateXXXX"  # Adjust!
    container_name       = "tfstate"
    key                  = "aks-cluster.tfstate"
  }
}
```

```bash
# Initialize the backend (migrates the local state)
terraform init -migrate-state
```

---

## 8. CI/CD with GitHub Actions

Example `.github/workflows/terraform.yml`:

```yaml
name: 'Terraform AKS'

on:
  push:
    branches: [main]
    paths: ['demos/aks/03-terraform/**']
  pull_request:
    branches: [main]
    paths: ['demos/aks/03-terraform/**']

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  TF_WORKING_DIR: demos/aks/03-terraform

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.TF_WORKING_DIR }}

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
```

---

## 9. Troubleshooting

### Common errors

| Error                                          | Cause                               | Solution                      |
| ---------------------------------------------- | ----------------------------------- | ----------------------------- |
| `Error: Provider produced inconsistent result` | State is stale                      | `terraform refresh`           |
| `Resource already exists`                      | Resource exists outside of TF       | `terraform import ...`        |
| `Quota exceeded`                               | vCPU limit reached                  | Increase quota in the portal  |
| `Version not supported`                        | K8s version outdated                | Check `az aks get-versions`   |

### Fixing state problems

```bash
# Refresh the state
terraform refresh

# Remove a resource from the state (without deleting it)
terraform state rm azurerm_kubernetes_cluster_node_pool.user

# Remove a state lock manually (after an aborted run)
terraform force-unlock LOCK_ID
```

---

## 10. Cleanup

```bash
# Delete all Terraform resources
terraform destroy

# Confirm with "yes"

# Clean up local files
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
```

---

## Summary

| Aspect                | Value                               |
| --------------------- | ----------------------------------- |
| **Cluster type**      | AKS Standard                        |
| **Networking**        | Azure CNI Overlay + Cilium          |
| **Authentication**    | Azure RBAC                          |
| **Scaling**           | Cluster Autoscaler (1-5 user nodes) |
| **Monitoring**        | Container Insights                  |
| **Secrets**           | Key Vault Secrets Provider          |

**Benefits of Terraform for AKS:**

1. **Infrastructure as Code** - versioned, reviewable, reproducible
2. **Drift detection** - `terraform plan` catches unintended changes
3. **Modularization** - reusable modules for multiple clusters
4. **Multi-cloud** - same language for Azure, AWS, GCP
5. **State management** - one shared state for the whole team
