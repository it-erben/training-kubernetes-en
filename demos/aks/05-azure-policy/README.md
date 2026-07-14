# Azure Policy for AKS

This demo shows various **Azure Policy** scenarios for AKS clusters. Azure Policy enables
enterprise-grade governance and enforces compliance rules automatically.

## Prerequisites

- AKS cluster with Azure Policy enabled (enabled by default with AKS Automatic)
- Azure CLI
- Existing variables from 01-setup:

```bash
export RESOURCE_GROUP="rg-aks-training"
export CLUSTER_NAME="aks-automatic-cluster"
export LOCATION="germanywestcentral"
```

---

## Overview: Azure Policy for AKS

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure Policy                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │   Built-in      │  │    Custom       │  │   Initiatives   │          │
│  │   Policies      │  │    Policies     │  │   (Policy Sets) │          │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘          │
│           │                    │                    │                    │
│           └────────────────────┴────────────────────┘                    │
│                                │                                         │
│                    ┌───────────▼───────────┐                            │
│                    │   Policy Assignment   │                            │
│                    │   (assign to scope)   │                            │
│                    └───────────┬───────────┘                            │
│                                │                                         │
└────────────────────────────────│─────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │       AKS Cluster       │
                    │  ┌──────────────────┐   │
                    │  │  Gatekeeper/OPA  │   │
                    │  │  (Azure Policy   │   │
                    │  │   Add-on)        │   │
                    │  └──────────────────┘   │
                    └─────────────────────────┘
```

**How does it work?**

1. Azure Policy uses **Gatekeeper** (OPA - Open Policy Agent) inside the cluster
2. Policies are synchronized as **ConstraintTemplates** and **Constraints**
3. The admission controller checks every API request against the active policies
4. Depending on the effect: **Audit** (log only) or **Deny** (block)

---

## 1. Enable Azure Policy (if not active)

With AKS Automatic, Azure Policy is already enabled. For standard clusters:

```bash
# Check whether Azure Policy is enabled
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query "addonProfiles.azurepolicy.enabled"

# If not enabled:
az aks enable-addons \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --addons azure-policy
```

---

## 2. Show available built-in policies

```bash
# List all Kubernetes-related policies
az policy definition list \
  --query "[?contains(displayName, 'Kubernetes')].{Name:displayName, ID:name}" \
  --output table | head -50

# Only AKS-specific policies
az policy definition list \
  --query "[?contains(id, 'Microsoft.Kubernetes')].{Name:displayName, Mode:mode}" \
  --output table
```

**Important built-in policies for AKS:**

| Policy | Description |
| --- | --- |
| `Kubernetes cluster containers should only use allowed images` | Container Image Restrictions |
| `Kubernetes cluster pods should only use approved host network and port range` | Network Restrictions |
| `Kubernetes cluster containers should run with a read only root file system` | Read-only Filesystem |
| `Kubernetes cluster pod hostPath volumes should only use allowed host paths` | HostPath Restrictions |
| `Kubernetes cluster containers should only use allowed capabilities` | Linux Capabilities |
| `Kubernetes cluster should not allow privileged containers` | No Privileged Containers |
| `Kubernetes clusters should use internal load balancers` | Internal LB Only |

---

## Demo overview

This demo contains the following scenarios:

| #   | Demo                     | File                       | Description                          |
| --- | ------------------------ | -------------------------- | ------------------------------------ |
| 1   | Container Image Restrict | `01-image-restrictions.md` | Only images from allowed registries  |
| 2   | Resource Limits          | `02-resource-limits.md`    | CPU/memory limits required           |
| 3   | Required Labels          | `03-required-labels.md`    | Mandatory labels for all resources   |
| 4   | Pod Security             | `04-pod-security.md`       | Forbid privileged containers         |
| 5   | Read-Only Filesystem     | `05-readonly-filesystem.md`| Immutable containers                 |

---

## Quick start: Assign a policy

### Via Azure CLI

```bash
# Determine the policy definition ID (example: container images)
export POLICY_ID=$(az policy definition list \
  --query "[?contains(displayName, 'Kubernetes cluster containers should only use allowed images')].name" \
  --output tsv | head -1)

echo "Policy ID: $POLICY_ID"

# Determine the cluster ID
export AKS_ID=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query id \
  --output tsv)

# Assign the policy (audit mode)
# IMPORTANT: Azure Policy parameters require the {"value": ...} format!
az policy assignment create \
  --name "aks-allowed-images-audit" \
  --display-name "AKS: Only allowed container images (Audit)" \
  --policy $POLICY_ID \
  --scope $AKS_ID \
  --params '{
    "allowedContainerImagesRegex": {"value": "^(mcr\\.microsoft\\.com|docker\\.io/library/).*$"},
    "effect": {"value": "Audit"}
  }'
```

### Via Azure Portal

1. **Azure Portal** → search for "Policy"
2. **Definitions** → filter by "Kubernetes"
3. Select a policy → **"Assign"**
4. Scope: select the resource group or AKS cluster
5. Configure the parameters
6. **"Review + create"**

---

## Check policy synchronization

After the assignment, it takes a few minutes until the policy is active in the cluster:

```bash
# Show Gatekeeper constraints in the cluster
kubectl get constraints

# Show constraint templates
kubectl get constrainttemplates

# Show details of a constraint
kubectl describe constraint <constraint-name>

# Check the Gatekeeper logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager --tail=50
```

---

## Check compliance status

```bash
# Compliance status of the policy assignment
az policy state list \
  --resource $AKS_ID \
  --query "[?complianceState=='NonCompliant'].{Resource:resourceId, Policy:policyDefinitionName}" \
  --output table

# All policy assignments for the cluster
az policy assignment list \
  --scope $AKS_ID \
  --query "[].{Name:displayName, Effect:parameters.effect.value}" \
  --output table
```

---

## Cleanup

```bash
# Delete all demo policy assignments
az policy assignment delete --name "aks-allowed-images-audit" --scope $AKS_ID
az policy assignment delete --name "aks-resource-limits" --scope $AKS_ID
az policy assignment delete --name "aks-required-labels" --scope $AKS_ID
# ... more as needed

# Delete the test namespace
kubectl delete namespace policy-demo --ignore-not-found
```

---

## Further documentation

- [Azure Policy for AKS](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
- [Built-in policy definitions](https://learn.microsoft.com/en-us/azure/aks/policy-reference)
- [Gatekeeper/OPA](https://open-policy-agent.github.io/gatekeeper/)
