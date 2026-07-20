# Lab 01: Create a classic AKS cluster with node pools

In this exercise, you will create an AKS cluster in **standard mode** and learn
how to manage node pools manually.

> **Shell note:** The commands below are written for **bash** (`\` line continuations, `$(…)`,
> shell variables). Run them in **Azure Cloud Shell** (the `>_` button in the Azure Portal, with
> `az` and `kubectl` preinstalled) or in **WSL**. In native Windows PowerShell they won't run as written.

## Part 1: Create a resource group

**Task:** Create a new resource group for this exercise.

```bash
# Set variables (adjust INITIALS)
export INITIALS="abc"
export RESOURCE_GROUP="rg-aks-classic-${INITIALS}"
export LOCATION="germanywestcentral"
export CLUSTER_NAME="aks-classic-${INITIALS}"

# Create the resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

---

## Part 2: Create an AKS standard cluster

**Task:** Create an AKS cluster in standard mode with a
system node pool.

```bash
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --sku Base \
  --tier Free \
  --node-count 1 \
  --node-vm-size Standard_D2s_v3 \
  --enable-aad \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-dataplane cilium \
  --enable-azure-rbac \
  --enable-keda \
  --generate-ssh-keys
```

Creating the cluster takes about 5-10 minutes.

---

## Part 3: Configure kubectl

**Task:** Connect your local kubectl to the cluster.

```bash
# Get credentials
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# Test the connection
kubectl get nodes
```

You should now see one node in the `Ready` state.

---

## Part 4: Understand the cluster

### Retrieve cluster information

Before we work with the cluster, let's get an overview:

```bash
# Shows the kubectl and Kubernetes versions
kubectl version

# Prints basic cluster information
kubectl cluster-info

# Lists all nodes (compute nodes) in the cluster
kubectl get nodes
```

**Task:** Run these commands and answer:

- Which Kubernetes version is running on your cluster?
- How many nodes does your cluster have?
- Is the node in the `Ready` state?

### Examine node details

`describe` gives you detailed information about a resource.
Replace `<NODENAME>` with a real node name:

```bash
kubectl describe node <NODENAME>
```

**Tasks:**

1. Find out:
    - How many CPUs are available on the node?
    - Which operating system and version is installed? (Hint: "OS Image")
    - How much RAM is available in total? (Hint: "Capacity")
    - What percentage of the RAM is already allocated? (Hint: "Allocated resources")

2. Scroll to "Non-terminated Pods" – which system pods are already running on the node?

### Explore resources in the cluster

Pods are the smallest deployable unit in Kubernetes. Let's see what's already running:

```bash
# All pods in the current namespace (default)
kubectl get pods

# All pods across all namespaces
kubectl get pods --all-namespaces

# Short form with -A instead of --all-namespaces
kubectl get pods -A
```

**What do you notice?**

- The `default` namespace probably has nothing running yet
- System components run in `kube-system` (CoreDNS, kube-proxy, etc.)
- Every pod has a status (Running, Pending, etc.)

### Which resource types are there, anyway?

Kubernetes has a lot of different resource types. List them all:

```bash
kubectl api-resources
```

**Tasks:**

1. Find the entry for `pods` in the list – what is its short form (SHORTNAMES)?
2. Which short forms do `services`, `deployments`, and `namespaces` have?
3. Try out:

   ```bash
   kubectl get po -A        # instead of pods
   kubectl get svc -A       # instead of services
   kubectl get deploy -A    # instead of deployments
   kubectl get ns           # instead of namespaces
   ```

**Tip:** The short forms save a lot of typing – worth memorizing.

### Understand the namespace system

Namespaces are like folders – they group resources logically:

```bash
# Show all namespaces
kubectl get namespaces

# Pods in a specific namespace
kubectl get pods -n kube-system
kubectl get pods --namespace kube-system  # long form

# Pods in the default namespace (when nothing is specified)
kubectl get pods
```

**Task:** How many pods are running in the namespace `kube-system`?

### The _wide_ output format

By default, `kubectl get` only shows the most important columns. With `-o wide` you get more details:

```bash
kubectl get pods -A -o wide
```

**What extra information do you get now?**

- IP addresses of the pods
- Which node the pod is running on
- Nominated Node, Readiness Gates (if present)

**Task:** Write down the IP address of a pod from the `kube-system` namespace.

### Output YAML and JSON

Every resource in Kubernetes is stored internally as JSON/YAML. You can view the full
definition:

```bash
# YAML format (readable)
kubectl get pod <POD-NAME> -n kube-system -o yaml

# JSON format (machine-readable)
kubectl get pod <POD-NAME> -n kube-system -o json
```

**Replace `<POD-NAME>`** with a real pod name.

**Tasks:**

1. Look at the YAML output – can you find sections like `metadata`, `spec`, and `status`?
2. With `jsonpath` you can extract specific fields:

   ```bash
   # Output only the pod's IP
   kubectl get pod <POD-NAME> -n kube-system -o jsonpath='{.status.podIP}'
   ```

### Custom columns

You can also build your own tables:

```bash
kubectl get pods -A -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

**In your own words:** what does this command display?

## Kubectl help

`kubectl explain` is your built-in API documentation:

```bash
# What is a pod?
kubectl explain pod

# What belongs in pod.spec?
kubectl explain pod.spec

# Which container fields exist?
kubectl explain pod.spec.containers
```

**Task:** Use `explain` to find out which fields `pod.spec.containers.resources` has.

## Part 5: Add a user node pool

**Task:** Create a separate user node pool for workloads.

**Background:** It's best practice to separate system workloads (CoreDNS, etc.) from
application workloads. That's what separate node pools with different `mode` settings
are for.

```bash
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name workloads \
  --mode User \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --labels workload-type=applications
```

**Explanation:**

- `--mode User`: This pool is intended for application workloads
- `--labels`: Adds labels that can be used for node selectors

Check the node pools:

```bash
az aks nodepool list \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --output table
```

---

## Part 6: Scale the node pool

**Task:** Scale the user node pool to 3 nodes.

```bash
az aks nodepool scale \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name workloads \
  --node-count 3
```

Verify the change:

```bash
kubectl get nodes -l workload-type=applications
```

---

## Part 7: Enable autoscaling

**Task:** Enable the cluster autoscaler for the user node pool.

```bash
az aks nodepool update \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name workloads \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5
```

The cluster autoscaler scales automatically based on pod resource requests.

---

## Part 8: Deploy a test application

**Task:** Deploy an application that runs on the user node pool.

Create a file `test-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kubernetes
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-kubernetes
  template:
    metadata:
      labels:
        app: hello-kubernetes
    spec:
      nodeSelector:
        workload-type: applications
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

Deploy the application:

```bash
kubectl apply -f test-deployment.yaml

# Check which nodes the pods are running on
kubectl get pods -o wide
```

The pods should only run on nodes with the label `workload-type=applications`.

---

## Part 9: Display node pool information

**Task:** Examine the configuration of your node pools.

```bash
# Detailed node pool info
az aks nodepool show \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name workloads \
  --output yaml

# Show node labels and taints in Kubernetes
kubectl describe nodes | grep -A5 "Labels:"

# Resource usage of the nodes
kubectl top nodes
```
