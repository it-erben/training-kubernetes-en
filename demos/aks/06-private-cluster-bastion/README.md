# Demo: Private AKS Cluster with Access via Command Invoke

This demo shows how to create a private AKS cluster and access it without needing a jump VM.

## Use Cases

- The API server isn't reachable from the internet
- Tighter security for sensitive workloads
- Compliance requirements (e.g. no public endpoints)
- No extra infrastructure (jump VMs) needed

---

## Access Methods at a Glance

| Method                      | Infrastructure | Use case                                          |
| --------------------------- | -------------- | ------------------------------------------------- |
| **`az aks command invoke`** | None           | Simple kubectl commands, quick diagnostics        |
| **Bastion + tunnel**        | Bastion + VM   | Full kubectl functionality, Helm, local files     |
| **VPN Gateway**             | VPN Gateway    | Permanent access, multiple developers             |

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                         Azure VNet                               │
│                      (10.224.0.0/16)                            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  AKS Subnet                                                 ││
│  │  10.224.0.0/20                                              ││
│  │                                                             ││
│  │  ┌────────────┐      ┌────────────┐                         ││
│  │  │ AKS Nodes  │      │ Private    │                         ││
│  │  │ 10.224.x.x │◄────►│ API server │                         ││
│  │  └────────────┘      └────────────┘                         ││
│  │                            ▲                                ││
│  └────────────────────────────┼────────────────────────────────┘│
└───────────────────────────────┼─────────────────────────────────┘
                                │
                                │ Private Link
                                │
┌───────────────────────────────┼─────────────────────────────────┐
│  Azure Control Plane          │                                  │
│                               ▼                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  az aks command invoke                                      ││
│  │  (runs commands in the cluster without direct network       ││
│  │   access - goes through Azure Resource Manager)             ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                ▲
                                │ HTTPS (Azure API)
                                │
                    ┌───────────┴───────────┐
                    │   Local machine       │
                    │   (az cli)            │
                    └───────────────────────┘

Pod overlay network: 192.168.0.0/16 (not in the VNet, virtual)
```

---

## Part 1: Create the Cluster

### 1.1 Set variables

```bash
export RESOURCE_GROUP="rg-aks-private"
export LOCATION="germanywestcentral"
export CLUSTER_NAME="aks-private-cluster"
export VNET_NAME="vnet-aks-private"
```

### 1.2 Create resource group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### 1.3 Create virtual network

```bash
# Create VNet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefixes 10.224.0.0/16 \
  --location $LOCATION

# AKS Subnet
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name aks-subnet \
  --address-prefixes 10.224.0.0/20
```

### 1.4 Get the subnet ID

```bash
export AKS_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name aks-subnet \
  --query id \
  --output tsv)

echo "AKS Subnet ID: $AKS_SUBNET_ID"
```

### 1.5 Create the private AKS cluster

```bash
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 192.168.0.0/16 \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --enable-private-cluster \
  --private-dns-zone system \
  --generate-ssh-keys \
  --enable-managed-identity

# Duration: approx. 5-10 minutes
```

**Important parameters:**

- `--enable-private-cluster`: Makes the API server private
- `--private-dns-zone system`: Azure manages the private DNS zone automatically
- `--network-plugin-mode overlay`: Pods get IPs from a separate overlay network

### 1.6 Check cluster status

```bash
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query "{Name:name, PrivateFQDN:privateFqdn, PublicFQDN:fqdn}" \
  --output table

# Expected output:
# - PrivateFQDN: aks-private-cluster-xxxxx.privatelink.germanywestcentral.azmk8s.io
# - PublicFQDN: (empty, since private)
```

### 1.7 Local kubectl access fails (demo)

```bash
# Get kubeconfig
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --overwrite-existing

# This will fail because the API server is not reachable:
kubectl get nodes

# Error: Unable to connect to the server: dial tcp: lookup aks-private-cluster-xxx...
```

---

## Part 2: Access via Command Invoke (recommended)

`az aks command invoke` runs commands inside the cluster through the Azure control plane -
your local machine never needs network access to the API server.

### 2.1 Run simple commands

```bash
# Show nodes
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl get nodes"

# Pods in all namespaces
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl get pods -A"

# Cluster info
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl cluster-info"
```

### 2.2 Create a deployment

```bash
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl create deployment nginx --image=nginx"

# Check status
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl get pods"
```

### 2.3 Apply local manifest files

The `--file` flag lets you send local files to the cluster:

```bash
# Create a local file
cat > /tmp/test-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
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

# Apply the file
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl apply -f test-pod.yaml" \
  --file /tmp/test-pod.yaml

# Verify
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl get pod test-pod"
```

### 2.4 Transfer multiple files

```bash
# Directory with manifests
mkdir -p /tmp/k8s-manifests

cat > /tmp/k8s-manifests/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
EOF

cat > /tmp/k8s-manifests/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
EOF

# Apply all files in the directory
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl apply -f ." \
  --file /tmp/k8s-manifests/
```

### 2.5 Install Helm charts

```bash
# Helm is preinstalled in the command invoke container
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update"

# Install a chart
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "helm install my-redis bitnami/redis --set auth.enabled=false"

# Check status
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "helm list"
```

### 2.6 Debugging and logs

```bash
# Show pod logs
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl logs deployment/nginx"

# Describe a pod
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl describe pod test-pod"

# Show events
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --command "kubectl get events --sort-by='.lastTimestamp'"
```

### 2.7 Limitations of Command Invoke

| Works                     | Does not work                              |
| ------------------------- | ------------------------------------------ |
| kubectl commands          | Interactive sessions (`kubectl exec -it`)  |
| Helm install/upgrade      | Port forwarding (`kubectl port-forward`)   |
| Applying local files      | Streaming logs (`kubectl logs -f`)         |
| One-off logs              | Direct API access (client-go)              |

For those, see Part 3 (Bastion tunnel).

---

## Part 3: Access via Bastion Tunnel (optional)

For full kubectl functionality (interactive sessions, port forwarding), you need a jump VM.

### 3.1 Additional variables

```bash
export BASTION_NAME="bastion-aks"
export VM_NAME="vm-jump"
export ADMIN_USERNAME="azureuser"
```

### 3.2 Add the Azure Bastion subnet

```bash
# IMPORTANT: The name MUST be exactly "AzureBastionSubnet"!
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name AzureBastionSubnet \
  --address-prefixes 10.224.16.0/26
```

### 3.3 Create Azure Bastion

```bash
# Public IP for Bastion
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name "${BASTION_NAME}-pip" \
  --sku Standard \
  --allocation-method Static \
  --location $LOCATION

# Create Azure Bastion (takes approx. 5-10 minutes)
az network bastion create \
  --resource-group $RESOURCE_GROUP \
  --name $BASTION_NAME \
  --public-ip-address "${BASTION_NAME}-pip" \
  --vnet-name $VNET_NAME \
  --sku Standard \
  --location $LOCATION

# IMPORTANT: SKU "Standard" is required for native client / tunnel!
```

### 3.4 Create a minimal jump VM

```bash
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image Ubuntu2204 \
  --size Standard_D2s_v5 \
  --vnet-name $VNET_NAME \
  --subnet aks-subnet \
  --admin-username $ADMIN_USERNAME \
  --generate-ssh-keys \
  --public-ip-address "" \
  --nsg ""
```

### 3.5 Prepare the VM (one-time)

```bash
# Install the Bastion extension
az extension add --name bastion --upgrade
az extension add -n ssh --upgrade

# SSH connection via Bastion
az network bastion ssh \
  --name $BASTION_NAME \
  --resource-group $RESOURCE_GROUP \
  --target-resource-id $(az vm show \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --query id \
    --output tsv) \
  --auth-type ssh-key \
  --username $ADMIN_USERNAME \
  --ssh-key ~/.ssh/id_rsa
```

On the VM, run:

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
sudo az aks install-cli

# Done - close the connection
exit
```

### 3.6 Set up the tunnel

Now set up a tunnel from your local machine through Bastion to the VM:

#### Terminal 1: Start the Bastion tunnel

```bash
# Set up a tunnel to port 22 of the VM
az network bastion tunnel \
  --name $BASTION_NAME \
  --resource-group $RESOURCE_GROUP \
  --target-resource-id $(az vm show \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --query id \
    --output tsv) \
  --resource-port 22 \
  --port 2222

# Output: "Tunnel is ready, connect on port 2222"
# Keep this terminal open!
```

#### Terminal 2: SSH tunnel for kubectl

```bash
# Get the private FQDN of the API server
export API_FQDN=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query privateFqdn \
  --output tsv)

echo "API Server: $API_FQDN"

# SSH connection with port forwarding
ssh -o StrictHostKeyChecking=no \
  -L 6443:${API_FQDN}:443 \
  -p 2222 \
  azureuser@127.0.0.1
```

#### Terminal 3: Use kubectl

```bash
# Get kubeconfig (if not done already)
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --overwrite-existing

# Point the server URL to localhost
kubectl config set-cluster $CLUSTER_NAME \
  --server=https://127.0.0.1:6443

# Now kubectl works locally!
kubectl get nodes

# Interactive session
kubectl run -it --rm debug --image=busybox -- sh

# Port forwarding
kubectl port-forward svc/web-service 8080:80
```

### 3.7 Tunnel architecture

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Local PC     │────►│ Azure        │────►│ Jump VM      │────►│ Private      │
│              │     │ Bastion      │     │              │     │ API server   │
│ :2222 → :22  │     │              │     │ DNS lookup   │     │              │
│ :6443 ──────────────────────────────────► :443         │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘

Tunnel 1: az network bastion tunnel (port 2222 → VM port 22)
Tunnel 2: SSH -L 6443:api-server:443 (port 6443 → API server port 443)
```

---

## Cleanup

```bash
# Delete everything
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait

echo "Deletion started. Takes a few minutes."
```

---

## Cost Estimate

| Resource                     | Estimated cost/month    |
| ---------------------------- | ----------------------- |
| AKS cluster (2x D2s_v3)      | ~140€                   |
| **Command Invoke only**      | **~140€**               |
| + Azure Bastion (Standard)   | +165€                   |
| + Jump VM (B1s)              | +8€                     |
| **With Bastion + VM**        | **~313€**               |

---

## Summary

| Method | Advantages | Disadvantages |
| --- | --- | --- |
| **Command Invoke** | No extra infrastructure, works right away | No interactive sessions |
| **Bastion tunnel** | Full kubectl functionality | Extra cost and setup work |

**Recommendation:**

- `az aks command invoke` is enough for most scenarios
- Set up Bastion + VM only if you need interactive sessions or port forwarding
