# Demo: ZRS vs. LRS Disks in AKS

## Learning Objectives

After this demo, you'll understand:

- The difference between zonal (LRS) and zone-redundant (ZRS) Azure disks
- The impact on pod scheduling and high availability
- When to use which storage type

## Check the Cluster Setup

```bash
# Get cluster information
RESOURCE_GROUP="rg-aks-training"
CLUSTER_NAME="aks-training-cluster"

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# Show nodes and their zones
kubectl get nodes -L topology.kubernetes.io/zone

# Expected output: nodes spread across westeurope-1, westeurope-2, westeurope-3
```

---

## Part 1: Create Storage Classes

### 1.1 Standard LRS StorageClass (zonal)

```yaml
# storageclass-lrs.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-lrs
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### 1.2 ZRS StorageClass (zone-redundant)

```yaml
# storageclass-zrs.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-zrs
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_ZRS
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### 1.3 Create the StorageClasses

```bash
kubectl apply -f storageclass-lrs.yaml
kubectl apply -f storageclass-zrs.yaml

# Show available StorageClasses
kubectl get storageclass
```

---

## Part 2: Deploy Test Workloads

### 2.1 Deployment with an LRS disk

```yaml
# deployment-lrs.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-lrs-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-lrs
  resources:
    requests:
      storage: 4Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-lrs-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lrs-demo
  template:
    metadata:
      labels:
        app: lrs-demo
    spec:
      containers:
        - name: busybox
          image: busybox:1.36
          command: [ "sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done" ]
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: pvc-lrs-demo
```

### 2.2 Deployment with a ZRS disk

```yaml
# deployment-zrs.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-zrs-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-zrs
  resources:
    requests:
      storage: 4Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-zrs-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zrs-demo
  template:
    metadata:
      labels:
        app: zrs-demo
    spec:
      containers:
        - name: busybox
          image: busybox:1.36
          command: [ "sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done" ]
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: pvc-zrs-demo
```

### 2.3 Deploy the workloads

```bash
kubectl apply -f deployment-lrs.yaml
kubectl apply -f deployment-zrs.yaml

# Wait until both pods are running
kubectl get pods -w
```

---

## Part 3: Check the Starting State

### 3.1 Find where the pods run

```bash
# Which nodes are the pods running on?
kubectl get pods -o wide

# Example output:
# NAME                            READY   STATUS    NODE                                
# app-lrs-demo-7b9d8f6c5-x2k4m    1/1     Running   aks-nodepool1-12345678-vmss000000   
# app-zrs-demo-8c5d9f7e6-y3l5n    1/1     Running   aks-nodepool1-12345678-vmss000001   
```

### 3.2 Find each node's zone

```bash
# Detailed node information
LRS_POD=$(kubectl get pods -l app=lrs-demo -o jsonpath='{.items[0].metadata.name}')
ZRS_POD=$(kubectl get pods -l app=zrs-demo -o jsonpath='{.items[0].metadata.name}')

LRS_NODE=$(kubectl get pod $LRS_POD -o jsonpath='{.spec.nodeName}')
ZRS_NODE=$(kubectl get pod $ZRS_POD -o jsonpath='{.spec.nodeName}')

echo "LRS pod is running on: $LRS_NODE"
echo "ZRS pod is running on: $ZRS_NODE"

# Show zones
kubectl get node $LRS_NODE -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
echo ""
kubectl get node $ZRS_NODE -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
```

### 3.3 Check PV zones

```bash
# Show PersistentVolumes and their topology
kubectl get pv -o custom-columns=\
'NAME:.metadata.name,CLAIM:.spec.claimRef.name,ZONE:.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[?(@.key=="topology.kubernetes.io/zone")].values[0]'
```

**Write down what you see:**

| Resource  | Zone | Notes                  |
|-----------|------|------------------------|
| LRS PV    |      | Bound to one zone      |
| ZRS PV    |      | No zone restriction    |

---

## Part 4: Simulate a Zone Failover

### 4.1 Find the LRS pod's zone and cordon it

```bash
# Determine the node the LRS pod is running on
LRS_NODE=$(kubectl get pod -l app=lrs-demo -o jsonpath='{.items[0].spec.nodeName}')
LRS_ZONE=$(kubectl get node $LRS_NODE -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')

echo "LRS pod is running on node: $LRS_NODE in zone: $LRS_ZONE"

# Cordon ALL nodes in this zone to block scheduling
for node in $(kubectl get nodes -l topology.kubernetes.io/zone=$LRS_ZONE -o name); do
  kubectl cordon $node
  echo "Cordoned: $node"
done
```

### 4.2 Delete the pods and watch the restart

```bash
# Terminal 1: watch the pods
kubectl get pods -w

# Terminal 2: delete both pods at the same time
kubectl delete pod -l app=lrs-demo
kubectl delete pod -l app=zrs-demo
```

### 4.3 Analyze the result

```bash
# Check the status after approx. 30 seconds
kubectl get pods -o wide

# Check the events of the LRS pod
kubectl describe pod -l app=lrs-demo | grep -A 20 "Events:"
```

**Expected result:**

| Workload     | Status  | Explanation                                             |
|--------------|---------|---------------------------------------------------------|
| app-zrs-demo | Running | The ZRS disk can be mounted in any zone                 |
| app-lrs-demo | Pending | The LRS disk is pinned to its zone, so no node fits     |

### 4.4 Examine the scheduler events

```bash
# Why can't the LRS pod be started?
kubectl get events --field-selector involvedObject.name=$(kubectl get pods -l app=lrs-demo -o jsonpath='{.items[0].metadata.name}') --sort-by='.lastTimestamp'

# Typical error message:
# "0/3 nodes are available: 1 node(s) had volume node affinity conflict, 
# 2 node(s) were unschedulable."
```

---

## Part 5: Recover

### 5.1 Uncordon the nodes

```bash
# Uncordon all nodes
for node in $(kubectl get nodes -l topology.kubernetes.io/zone=$LRS_ZONE -o name); do
  kubectl uncordon $node
  echo "Uncordoned: $node"
done

# Wait until the LRS pod starts
kubectl get pods -w
```

### 5.2 Check the disk properties in Azure

```bash
# Determine the resource group of the AKS cluster
NODE_RG=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)

# List the disks
az disk list -g $NODE_RG -o table --query "[?contains(name, 'pvc')].{Name:name, SKU:sku.name, Zones:zones}"
```

**Expected output:**

```text
Name                                    SKU          Zones
--------------------------------------  -----------  -------
pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx  Premium_LRS  ["1"]
pvc-yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy  Premium_ZRS  null
```

---

## Part 6: Cleanup

```bash
kubectl delete -f deployment-lrs.yaml
kubectl delete -f deployment-zrs.yaml
kubectl delete -f storageclass-lrs.yaml
kubectl delete -f storageclass-zrs.yaml
```

---

## Discussion Questions

1. How would a StatefulSet with 3 replicas and LRS disks behave if a zone fails?

2. If an application needs ReadWriteMany, what's the alternative to ZRS?

3. How does `volumeBindingMode: WaitForFirstConsumer` interact with zone placement?

4. What happens to a ZRS disk when the whole AKS cluster is deleted (ReclaimPolicy)?
