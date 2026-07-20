# Lab 04: AKS with Azure RBAC – namespace permissions

For this lab, create a cluster as in Lab 01 and set the environment variables described there.

> **Shell note:** The commands below are written for **bash** (`\` line continuations, `$(…)`,
> shell variables). Run them in **Azure Cloud Shell** (the `>_` button in the Azure Portal, with
> `az` and `kubectl` preinstalled) or in **WSL**. In native Windows PowerShell they won't run as written.

## Scenario

Your company wants to provision a new Kubernetes cluster for the development
team. There are two teams:

- **Team Observers**: should only be able to read resources in the namespace `project-alpha`
  (monitoring, debugging)
- **Team Devs**: should be able to read and write resources in the namespace `project-alpha`
  (Deployments, ConfigMaps, etc.)

Both teams are already set up as groups in Entra ID.

## Tasks

### Part 1: Create a namespace

Use kubectl to create a namespace called `project-alpha`.

### Part 2: Create Azure role assignments

Next, we bind the `RBAC Reader` role on the namespace `project-alpha` to the
"Observers" group and the `RBAC Writer` role to the "Developers" group.

```bash
OBSERVERS_ID="c3de5c6a-7948-4f72-aeca-c287721b3831"
DEVELOPERS_ID="e275e10b-769f-4a2d-8cf6-739e7854a31e"

# Determine the cluster ID
AKS_ID=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query id -o tsv)

USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# We make ourselves admin
az role assignment create \
  --assignee $USER_OBJECT_ID \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $AKS_ID

# Role assignment for Observers (read-only)
az role assignment create \
  --assignee $OBSERVERS_ID \
  --role "Azure Kubernetes Service RBAC Reader" \
  --scope "${AKS_ID}/namespaces/project-alpha"

# Role assignment for Developers (read + write)
az role assignment create \
  --assignee $DEVELOPERS_ID \
  --role "Azure Kubernetes Service RBAC Writer" \
  --scope "${AKS_ID}/namespaces/project-alpha"
```

### Part 3: Test the permissions

We'll test the assignments together during the training, using fresh users
that we add to the groups.
