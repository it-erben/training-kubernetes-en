# AKS CLI Setup & Cluster Creation

## 2. Set Up the Working Environment

### 2.1 Install the Azure CLI (locally)

```bash
# macOS
brew install azure-cli

# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows (PowerShell as admin)
winget install Microsoft.AzureCLI
```

### 2.2 Sign in and select a subscription

```bash
# Interactive sign-in (opens browser)
az login

# Show available subscriptions
az account list --output table

# Select a subscription (if there are several)
az account set --subscription "Subscription-name-or-ID"

# Check the current subscription
az account show --output table
```

### 2.3 Install important CLI extensions

```bash
# AKS preview features (optional, but useful for new features)
az extension add --name aks-preview

# Azure DevOps extension (for the CI/CD part)
az extension add --name azure-devops
```

### 2.4 Install kubectl (if not already present)

```bash
# Via the Azure CLI (recommended - installs a matching version)
az aks install-cli

# Or manually
# macOS: brew install kubectl
# Ubuntu: snap install kubectl --classic
```

### 2.5 Create a resource group for the training

```bash
# Set variables (we use these throughout)
export RESOURCE_GROUP="rg-aks-training"
export LOCATION="germanywestcentral"  # Frankfurt - relevant for German customers

# Create the resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# In the portal: "Resource groups" → "+ Create"
```

### 2.6 Prepare the subscription

```bash
# Register all important providers for AKS at once
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.KeyVault
```

---

## 3. Create the AKS Cluster

### 3.1 Create an AKS Automatic cluster

#### In the portal

1. **Search** → type "Kubernetes" or "AKS"
2. **Azure Kubernetes Service** → **"+ Create"**
3. Select **"Create an Automatic Kubernetes cluster (preview)"**

4. **"Basics" tab:**
    - Subscription: your training subscription
    - Resource group: `rg-aks-training`
    - Cluster name: `aks-automatic-cluster`
    - Region: `Germany West Central` (must support availability zones!)

5. **"Monitoring" tab:**
    - Azure Monitor is enabled by default
    - Prometheus metrics optional

6. **"Tags" tab:** optional

7. **"Review + create"** → **"Create"**

**📌 Note:** AKS Automatic has NO tabs for:

- Node pools (managed automatically)
- Networking (preconfigured with Azure CNI Overlay + Cilium)
- Many advanced settings

#### Via CLI

```bash
# Variables
export CLUSTER_NAME="aks-automatic-cluster"
export RESOURCE_GROUP="rg-aks-training"
export LOCATION="germanywestcentral"

# Create the AKS Automatic cluster - it's that simple!
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --sku automatic

# That's it! Everything else is configured automatically:
# ✅ Azure CNI Overlay + Cilium
# ✅ Node Auto-Provisioning (NAP/Karpenter)
# ✅ HPA, VPA, KEDA enabled
# ✅ Azure Key Vault Secrets Provider
# ✅ Managed NGINX Ingress
# ✅ Azure Policy & Deployment Safeguards
# ✅ Automatic upgrades
# ✅ Availability zones
# ✅ Standard tier SLA
```

> ⚠️ **Error "namespace not registered"?**
>
> New subscriptions often don't have the required resource providers registered yet. Fix:
>
> ```bash
> # Register the required resource providers
> az provider register --namespace Microsoft.OperationalInsights
> az provider register --namespace Microsoft.ContainerService
> az provider register --namespace Microsoft.OperationsManagement
>
> # Check the status (takes 1-2 minutes until "Registered")
> az provider show --namespace Microsoft.OperationalInsights --query "registrationState"
>
> # Then run az aks create again
> ```

<!-- markdownlint-disable MD028 -->

> ⚠️ **Error "could not find a suitable VM size" / quota problem?**
>
> New subscriptions often come with a quota of just 10 vCPUs, but AKS Automatic
> needs at least 16. Fix:
>
> ```bash
> # Option 1: Explicitly specify a smaller VM size (possible immediately)
> az aks create \
>   --resource-group $RESOURCE_GROUP \
>   --name $CLUSTER_NAME \
>   --location $LOCATION \
>   --sku automatic \
>   --node-vm-size Standard_D2s_v3
>
> # Option 2: Check the quota and increase it in the portal if necessary
> az vm list-usage --location $LOCATION --output table | grep -E "Name|vCPUs|Standard D"
> # Portal → "Quotas" → Compute → filter by region → "Request increase"
> ```

#### What AKS Automatic configures automatically

Once the cluster is created, you can inspect what was configured for you:

```bash
# Retrieve cluster details
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --output yaml

# Important automatically enabled features:
# - agentPoolProfiles[].enableAutoScaling: false (NAP takes over!)
# - agentPoolProfiles[].nodeTaints: ["CriticalAddonsOnly=true:NoSchedule"]
# - networkProfile.networkPlugin: "azure"
# - networkProfile.networkPluginMode: "overlay"
# - networkProfile.networkDataplane: "cilium"
# - addonProfiles.azureKeyvaultSecretsProvider.enabled: true
# - addonProfiles.azurepolicy.enabled: true
# - autoUpgradeProfile.upgradeChannel: "stable" (or similar)
```

#### Understanding Node Auto-Provisioning (NAP)

AKS Automatic does **not** use the classic cluster autoscaler. It uses
**Node Auto-Provisioning (NAP)** instead, which is based on the open-source
project **Karpenter**:

```bash
# System node pool has a taint - only for system components
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# When you deploy workloads, NAP automatically creates suitable nodes
# Example: deployment with a GPU requirement → NAP creates a GPU node

# Show NAP configuration
kubectl get nodepools -A  # Karpenter NodePools
kubectl get nodeclaims -A # Current node claims
```

#### NAP live demo: trigger automatic node creation

This one-liner creates a deployment big enough to make NAP spin up
**two new nodes**:

> ⚠️ **Important: Assign an Azure RBAC role!**
>
> AKS Automatic enables **Azure RBAC for Kubernetes** and disables local
> accounts. This means:
>
> - `--admin` does **not** work (local accounts disabled)
> - You need an explicit Azure RBAC role assignment
>
> **Without this role you'll get "User does not have access to the resource"
> errors!**

```bash
# 1. Set the kubeconfig
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# 2. Assign the Azure RBAC role (only needed once!)
USER_ID=$(az ad signed-in-user show --query id -o tsv)
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv)

az role assignment create \
  --assignee $USER_ID \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $AKS_ID

# 3. Clear the token cache and fetch credentials again
kubelogin remove-tokens
# If kubelogin is not installed: rm -rf ~/.kube/cache
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# 4. Test the connection (on error, wait 1 minute – propagation!)
kubectl get nodes
```

```bash
# 5. Create the deployment: 6 replicas with 1 CPU + 1Gi RAM each → NAP creates 2 nodes
kubectl create deployment nap-demo --image=nginx --replicas=6
kubectl set resources deployment/nap-demo --requests=cpu=1,memory=1Gi
kubectl get nodes -w
```

In a separate terminal, watch NAP provision the new nodes:

```bash
# Watch the nodes (in a separate terminal)
watch -n2 'kubectl get nodes'

# Show NodeClaims (Karpenter resources)
kubectl get nodeclaims -A -w

# Clean up after the demo
kubectl delete deployment nap-demo
```

**💡 Explanation:** The system node pool has a
`CriticalAddonsOnly=true:NoSchedule` taint, so user workloads can't run
there. NAP spots the pending pods and creates suitable worker nodes for
them.

---

### 3.2 Create an AKS Standard cluster

#### In the portal (detailed variant)

1. **Search** → type "Kubernetes" or "AKS"
2. **Azure Kubernetes Service** → **"+ Create"** → **"Create a Kubernetes
   cluster"**

3. **"Basics" tab:**
    - Subscription: your training subscription
    - Resource group: `rg-aks-training`
    - **Cluster preset configuration**: `Dev/Test` or `Production` (sets defaults)
    - Cluster name: `aks-standard-cluster`
    - Region: `Germany West Central`
    - Availability zones: for production select 1, 2, 3
    - Kubernetes version: current stable version (e.g. 1.30.x)
    - **Pricing tier**:
        - `Free` → for tests/training (no SLA, max 10 nodes)
        - `Standard` → for production (99.5% SLA, up to 5000 nodes)
        - `Premium` → for mission-critical (long-term support)
    - **Automatic upgrades**:
        - For the training: `Disabled`
        - For production: `Patch` or `Stable` recommended

4. **"Node pools" tab:**
    - **System node pool** (agentpool):
        - VM size: `Standard_DS2_v2` for the training
        - Node count: 2
        - Scale method: `Manual` or `Autoscale`
    - Optional: add another **user node pool**

5. **"Networking" tab:**
    - **Network configuration**:
        - `kubenet` → simpler, pods get internal IPs
        - `Azure CNI` → pods get VNet IPs directly
        - `Azure CNI Overlay` → like CNI, but with an overlay network (recommended)
        - `Azure CNI with Cilium` → with eBPF-based network policy
    - For the training: `kubenet` or `Azure CNI Overlay`
    - **Network policy**: `Azure` or `Calico`

6. **"Integrations" tab:**
    - **Container registry**: connect later (for the demo)
    - **Azure Monitor**: enable
    - **Azure Policy**: enable for the DevSecOps part

7. **"Advanced" tab:**
    - Infrastructure encryption
    - API server authorized IP ranges (IP whitelist)
    - For the training: defaults are OK

8. **"Review + create"** → **"Create"**

#### Via CLI (Standard cluster)

```bash
# Variables
export CLUSTER_NAME="aks-standard-cluster"
export RESOURCE_GROUP="rg-aks-training"
export LOCATION="germanywestcentral"

# Minimal Standard cluster for the training (Free tier)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --generate-ssh-keys \
  --enable-managed-identity \
  --network-plugin kubenet \
  --enable-addons monitoring \
  --tier free

# Production Standard cluster (all features)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name "${CLUSTER_NAME}-prod" \
  --location $LOCATION \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --generate-ssh-keys \
  --enable-managed-identity \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-dataplane cilium \
  --network-policy cilium \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5 \
  --tier standard \
  --zones 1 2 3 \
  --enable-aad \
  --enable-azure-rbac \
  --auto-upgrade-channel stable
```

---

### 3.4 Compare both clusters (live demo)

```bash
# Compare both cluster configurations
echo "=== AKS Automatic ==="
az aks show -g $RESOURCE_GROUP -n aks-automatic-cluster \
  --query "{Name:name, SKU:sku, NetworkPlugin:networkProfile.networkPlugin, NetworkDataplane:networkProfile.networkDataplane, AutoUpgrade:autoUpgradeProfile.upgradeChannel}" \
  -o table

echo "=== AKS Standard ==="
az aks show -g $RESOURCE_GROUP -n aks-standard-cluster \
  --query "{Name:name, SKU:sku, NetworkPlugin:networkProfile.networkPlugin, NetworkDataplane:networkProfile.networkDataplane, AutoUpgrade:autoUpgradeProfile.upgradeChannel}" \
  -o table

# Compare the enabled add-ons
echo "=== Automatic Add-ons ==="
az aks show -g $RESOURCE_GROUP -n aks-automatic-cluster \
  --query "addonProfiles | keys(@)" -o tsv

echo "=== Standard Add-ons ==="
az aks show -g $RESOURCE_GROUP -n aks-standard-cluster \
  --query "addonProfiles | keys(@)" -o tsv
```

---

### 3.6 Migrate from Automatic to Standard

Worth highlighting in the training: **AKS Automatic can be converted to
Standard** if you need more control later:

```bash
# Convert the cluster from Automatic to Standard
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name aks-automatic-cluster \
  --sku Base  # Switches to Standard mode

# Caution: This is a one-way street!
# Standard → Automatic is NOT possible
```

**💡 For the training:** This is a good selling point for starting with AKS
Automatic – you can always switch to Standard later if you need to.

---

### 3.5 Managed System Node Pools (Preview) – where AKS is heading

#### The problem with traditional system node pools

On **all** existing AKS clusters (Standard AND Automatic), you manage the
system node pool yourself:

- Choose the VM size
- Set the node count
- Plan capacity for system components
- Coordinate patching and upgrades
- **You pay for these VMs**

#### The solution: Managed System Node Pools

With the new preview feature (`--enable-hosted-system`), Microsoft manages the
system node pool for you – and covers the cost.

```bash
# AKS Automatic WITH a managed system node pool (preview)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name aks-automatic-hosted \
  --sku automatic \
  --enable-hosted-system \
  --location $LOCATION

# After creation: system nodes are NOT visible!
kubectl get nodes
# Shows only user/workload nodes, no system nodes
```

Microsoft hosts these components on its infrastructure:

- CoreDNS
- Metrics Server
- KEDA (Kubernetes Event-Driven Autoscaler)
- VPA (Vertical Pod Autoscaler)
- Konnectivity
- Eraser (Image Cleaner)
- Azure Monitor Collectors

Other add-ons and DaemonSets continue to run on `aks-system-surge` nodes in
your subscription.

#### Limitations (preview)

- Only available for **AKS Automatic** (not for Standard)
- No migration between Automatic with/without managed system node pools
- No custom VNet support
- Additional security restrictions:
  - No `kubectl exec` on system pods
  - No `kubectl debug` on system nodes
  - No wildcard tolerations for user workloads

---

### 3.6 Connect to the cluster

```bash
# Fetch credentials (like gcloud container clusters get-credentials)
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# Test the connection
kubectl get nodes

# Show cluster info
kubectl cluster-info

# In the portal: cluster → the "Connect" button also shows these commands
```

### 3.7 Explore the AKS architecture in the portal

Once the cluster is created, walk through these in the portal:

1. **Cluster overview:**
    - Kubernetes version
    - Node count
    - Status
    - API server address

2. **Left navigation in the cluster:**
    - **Node pools** → the VMs behind the nodes
    - **Kubernetes resources** → workloads, services, etc. (kubectl in the portal!)
    - **Settings** → networking, scaling, etc.
    - **Monitoring** → insights, metrics, logs

**📌 Show the participants:** Under "Node pools" you can see the actual VMs
and even SSH in (via the serial console) – unlike GKE, where the nodes are
more abstracted away.

---

## 4. Container Deployment & Networking

### 4.1 Create an Azure Container Registry (ACR)

**In the portal:**

1. Search for "Container Registries" → "+ Create"
2. Name: `acrakstraining` (must be globally unique, lowercase letters only)
3. SKU: `Basic` for the training
4. Create

**Via CLI:**

```bash
export ACR_NAME="acrakstraining$(openssl rand -hex 4)"

az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --location $LOCATION

# Attach the ACR to AKS (important!)
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --attach-acr $ACR_NAME
```

### 4.2 Build and push a sample application

```bash
# Create a sample app (Node.js)
mkdir -p ~/aks-demo-app && cd ~/aks-demo-app

# package.json
cat > package.json << 'EOF'
{
  "name": "aks-demo",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.18.2" }
}
EOF

# server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from AKS!',
    hostname: process.env.HOSTNAME,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => res.send('OK'));

app.listen(port, () => console.log(`Server running on port ${port}`));
EOF

# Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
USER node
CMD ["npm", "start"]
EOF

# Build with ACR (cloud build - like GCR)
az acr build \
  --registry $ACR_NAME \
  --image aks-demo:v1 \
  .

# Verify the image
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository aks-demo
```

### 4.3 Create the deployment

```bash
# Create the deployment YAML
cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-demo
  labels:
    app: aks-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: aks-demo
  template:
    metadata:
      labels:
        app: aks-demo
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: "topology.kubernetes.io/zone"
        whenUnsatisfiable: ScheduleAnyway
      containers:
      - name: aks-demo
        image: ${ACR_NAME}.azurecr.io/aks-demo:v1
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 3
EOF

# Apply the deployment
kubectl apply -f deployment.yaml

# Check the status
kubectl get deployments
kubectl get pods -w  # Watch mode
```

### 4.4 Create the service (LoadBalancer)

```bash
# Service YAML
cat > service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: aks-demo-service
  annotations:
    # Azure-specific annotation for an internal LB (optionally show this)
    # service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app: aks-demo
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
EOF

kubectl apply -f service.yaml

# Wait for the external IP
kubectl get service aks-demo-service -w

# Once the EXTERNAL-IP is there, test it
export SERVICE_IP=$(kubectl get service aks-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$SERVICE_IP
```

**💡 Show during the training:**

- In the portal, under the cluster → "Services and ingresses" you can see the
  service with its IP
- Point out that Azure automatically creates an Azure Load Balancer + public IP

### 4.5 Install the ingress controller

```bash
# Prepare the namespace
kubectl create namespace ingress-nginx
kubectl label namespace ingress-nginx admission.policy.azure.com/ignore=true

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# Wait for the external IP
kubectl get service -n ingress-nginx ingress-nginx-controller -w

# Create the Ingress resource
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aks-demo-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: aks-demo-service
            port:
              number: 80
EOF

kubectl apply -f ingress.yaml
```

Wait until the Ingress gets an IP, then test it with `curl`.

---

## 5. Storage in AKS

### 5.1 Show storage classes

```bash
kubectl get storageclass
```

### 5.2 Create persistent volume claims

```bash

# PVC for Azure Disk
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce  # Azure Disk: only one node can mount
  storageClassName: managed-csi-premium
  resources:
    requests:
      storage: 5Gi
EOF

# PVC with new StorageClass
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-file-pvc
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: azurefile-csi-premium
  resources:
    requests:
      storage: 5Gi
EOF

kubectl get pvc
```

### 5.3 Pod with persistent storage

```bash
cat > pod-with-storage.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-demo
spec:
  containers:
  - name: demo
    image: nginx:1.29.4
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
    volumeMounts:
    - name: disk-volume
      mountPath: /mnt/disk
    - name: file-volume
      mountPath: /mnt/files
  volumes:
  - name: disk-volume
    persistentVolumeClaim:
      claimName: azure-disk-pvc
  - name: file-volume
    persistentVolumeClaim:
      claimName: azure-file-pvc
EOF

kubectl apply -f pod-with-storage.yaml

# Look inside the pod
kubectl exec -it storage-demo -- df -h
```

### 5.4 Create a StorageClass for your own storage account

```bash
export SA_NAME="staksfiles$(openssl rand -hex 4)"
export SC_NAME="azurefile-training"

echo "=== 1. Create the storage account ==="
az storage account create \
  --name $SA_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --https-only true

export SA_ID=$(az storage account show \
  --name $SA_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

echo "Storage account created: $SA_NAME"

echo "=== 2. Create the StorageClass ==="
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $SC_NAME
provisioner: file.csi.azure.com
parameters:
  storageAccount: $SA_NAME
  resourceGroup: $RESOURCE_GROUP
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

echo "StorageClass created: $SC_NAME"

echo "=== 3. Determine the CSI identity (via probe PVC) ==="
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-identity-probe
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: $SC_NAME
  resources:
    requests:
      storage: 1Gi
EOF

echo "Waiting for the error message (10 seconds)..."
sleep 10

# Extract the identity from the error message
export CSI_IDENTITY=$(kubectl describe pvc csi-identity-probe 2>/dev/null | \
  grep -oE "object id '[a-f0-9-]+'" | \
  head -1 | \
  sed "s/object id '//;s/'//")

kubectl delete pvc csi-identity-probe --ignore-not-found

if [ -z "$CSI_IDENTITY" ]; then
  echo "❌ Could not determine the CSI identity. Please extract it manually from the error message."
  exit 1
fi

echo "CSI identity found: $CSI_IDENTITY"

echo "=== 4. Assign permissions ==="
az role assignment create \
  --assignee $CSI_IDENTITY \
  --role "Storage Account Contributor" \
  --scope $SA_ID

az role assignment create \
  --assignee $CSI_IDENTITY \
  --role "Storage File Data SMB Share Contributor" \
  --scope $SA_ID

echo "Waiting for RBAC propagation (60 seconds)..."
sleep 60

echo "=== 5. Create the PVC ==="
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-file-pvc
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: azurefile-training
  resources:
    requests:
      storage: 5Gi
EOF

echo "Waiting for the PVC binding..."
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/azure-file-pvc --timeout=120s
```
