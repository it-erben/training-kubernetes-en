# Sample Solution: Kubectl Basics

## Part 1: Understanding the Cluster

### 1.1 Retrieving Cluster Information

```bash
kubectl version
```

**Example output:**

```text
Client Version: v1.28.3
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.3
```

**Answers:**

- **Kubernetes version:** v1.28.3 (the server version is what matters)
- **Number of nodes:** 1 (with a standard Minikube setup)
- **Node status:** Ready

```bash
kubectl cluster-info
```

**Example output:**

```text
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```bash
kubectl get nodes
```

**Example output:**

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5d    v1.28.3
```

### 1.2 Examining Node Details

```bash
kubectl describe node minikube
```

**Answers:**

1. **CPUs:** Found under `Capacity` → `cpu: 2` (or 4, depending on your configuration)
2. **OS/version:** Under `System Info` → `OS Image: Buildroot 2023.02.1` or similar
3. **RAM available:** Under `Capacity` → `memory: 7949876Ki` (about 8 GB, depending on your configuration)
4. **RAM allocated:** Under `Allocated resources`:

   ```text
   Resource           Requests    Limits
   --------           --------    ------
   memory             170Mi (2%)  350Mi (4%)
   ```

   **What this means:** On a fresh Minikube cluster, typically 2-5% of the RAM is allocated.

5. **System pods:** Under `Non-terminated Pods` you'll find pods such as:
   - `kube-apiserver-minikube`
   - `kube-controller-manager-minikube`
   - `kube-scheduler-minikube`
   - `etcd-minikube`
   - `coredns-...`
   - `kube-proxy-...`
   - `storage-provisioner`

---

## Part 2: Exploring Resources in the Cluster

### 2.1 Listing All Pods

```bash
kubectl get pods
```

**Expected output:** `No resources found in default namespace.`

```bash
kubectl get pods -A
```

**Example output:**

```text
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-5dd5756b68-abcde          1/1     Running   0          5d
kube-system   etcd-minikube                      1/1     Running   0          5d
kube-system   kube-apiserver-minikube            1/1     Running   0          5d
kube-system   kube-controller-manager-minikube   1/1     Running   0          5d
kube-system   kube-proxy-xyz12                   1/1     Running   0          5d
kube-system   kube-scheduler-minikube            1/1     Running   0          5d
kube-system   storage-provisioner                1/1     Running   0          5d
```

### 2.2 What Resources Are There, Anyway?

```bash
kubectl api-resources
```

**Answers:**

1. **Short name for `pods`:** `po`
2. **Short names:**
   - `services` → `svc`
   - `deployments` → `deploy`
   - `namespaces` → `ns`

**Example output (excerpt):**

```text
NAME           SHORTNAMES   APIVERSION   NAMESPACED   KIND
pods           po           v1           true         Pod
services       svc          v1           true         Service
deployments    deploy       apps/v1      true         Deployment
namespaces     ns           v1           false        Namespace
configmaps     cm           v1           true         ConfigMap
```

**Testing the short names:**

```bash
kubectl get po -A        # works
kubectl get svc -A       # works
kubectl get deploy -A    # works
kubectl get ns           # works
```

### 2.3 Understanding the Namespace System

```bash
kubectl get namespaces
```

**Example output:**

```text
NAME              STATUS   AGE
default           Active   5d
kube-node-lease   Active   5d
kube-public       Active   5d
kube-system       Active   5d
```

```bash
kubectl get pods -n kube-system
```

**Answer:** On a fresh Minikube cluster, typically 6-8 pods run in the `kube-system` namespace.

---

## Part 3: Mastering Output Formats

### 3.1 Extended Information with `-o wide`

```bash
kubectl get pods -A -o wide
```

**Example output:**

```text
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE   IP             NODE
kube-system   coredns-5dd5756b68-abcde          1/1     Running   0          5d    10.244.0.3     minikube
kube-system   etcd-minikube                      1/1     Running   0          5d    192.168.49.2   minikube
kube-system   kube-apiserver-minikube            1/1     Running   0          5d    192.168.49.2   minikube
```

**The extra columns show:**

- Pod IP addresses (e.g. `10.244.0.3`)
- Which node the pod is running on (with Minikube, always `minikube`)

### 3.2 Outputting YAML and JSON

```bash
kubectl get pod coredns-5dd5756b68-abcde -n kube-system -o yaml
```

**Answers:**

1. **Yes**, the YAML output contains these main sections:
   - `metadata`: name, namespace, labels, annotations
   - `spec`: the desired configuration (containers, volumes, etc.)
   - `status`: the current state (phase, conditions, IP, etc.)

2. **JSONPath example:**

   ```bash
   kubectl get pod coredns-5dd5756b68-abcde -n kube-system -o jsonpath='{.status.podIP}'
   ```

   **Output:** `10.244.0.3`

### 3.3 Custom Columns

```bash
kubectl get pods -A -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

**Example output:**

```text
NAME                               STATUS    IP
coredns-5dd5756b68-abcde          Running   10.244.0.3
etcd-minikube                      Running   192.168.49.2
kube-apiserver-minikube            Running   192.168.49.2
```

**Explanation:** This command builds a custom table with three columns:

- `NAME`: pod name from `.metadata.name`
- `STATUS`: pod phase from `.status.phase`
- `IP`: pod IP from `.status.podIP`

---

## Part 4: Live Observation with `--watch`

**Terminal 1:**

```bash
kubectl get pods -A --watch
```

**Terminal 2:**

```bash
kubectl run nginx-test --image=nginx
```

**What you'll see in terminal 1:**

```text
NAMESPACE   NAME         READY   STATUS              RESTARTS   AGE
default     nginx-test   0/1     Pending             0          0s
default     nginx-test   0/1     Pending             0          0s
default     nginx-test   0/1     ContainerCreating   0          0s
default     nginx-test   1/1     Running             0          2s
```

**Lifecycle phases:**

1. `Pending` – the pod has been accepted, but the container hasn't started yet
2. `ContainerCreating` – the container image is being pulled and the container is being created
3. `Running` – the container is running

**Cleanup:**

```bash
kubectl delete pod nginx-test
```

**What you'll see during deletion:**

```text
default     nginx-test   1/1     Terminating   0          30s
default     nginx-test   0/1     Terminating   0          31s
```

---

## Part 5: Kubectl Help

### 5.1 The `explain` Feature

```bash
kubectl explain pod
```

**Output:** A description of pods with the available fields.

```bash
kubectl explain pod.spec
```

**Output:** A description of the `spec` fields of a pod.

```bash
kubectl explain pod.spec.containers
```

**Output:** A description of the container configuration.

**Task: the fields of `pod.spec.containers.resources`:**

```bash
kubectl explain pod.spec.containers.resources
```

**Answer:** The most important fields are:

- `limits`: the maximum resources (CPU, memory) the container is allowed to use
- `requests`: the guaranteed resources reserved for the container

**Example from the output:**

```text
FIELDS:
  limits        <map[string]string>
    Limits describes the maximum amount of compute resources allowed.

  requests      <map[string]string>
    Requests describes the minimum amount of compute resources required.
```

---

## Part 6: Checking Resource Consumption (Bonus)

```bash
minikube addons enable metrics-server
```

**Wait 30-60 seconds, then:**

```bash
kubectl top nodes
```

**Example output:**

```text
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   250m         12%    1200Mi          15%
```

```bash
kubectl top pods -A
```

**Example output:**

```text
NAMESPACE     NAME                               CPU(cores)   MEMORY(bytes)
kube-system   coredns-5dd5756b68-abcde          3m           15Mi
kube-system   etcd-minikube                      25m          50Mi
kube-system   kube-apiserver-minikube            60m          250Mi
```

**How to read this:**

- **Nodes:** shows CPU and RAM usage for the whole node
- **Pods:** shows the resource consumption of each pod
- `m` = millicores (1000m = 1 CPU core)
- `Mi` = mebibytes (RAM)
