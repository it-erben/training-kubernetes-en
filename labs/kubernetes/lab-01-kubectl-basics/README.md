# Lab 01: Kubectl Basics – The Command Center of Kubernetes

In this exercise you will get to know the most important `kubectl` commands. `kubectl` is the tool for communicating
with the Kubernetes cluster.

**Goal of this exercise:** By the end you should be able to confidently find your way around the cluster, locate
resources, and understand how to pull information out of the cluster.

---

## Part 1: Understanding the cluster

### 1.1 Retrieving cluster information

Before we start working with the cluster, let's get an overview:

```bash
# Shows the kubectl and Kubernetes versions
kubectl version

# Prints basic cluster information
kubectl cluster-info

# Lists all nodes (compute machines) in the cluster
kubectl get nodes
```

**Task:** Run these commands and answer:

- Which Kubernetes version is running on your cluster?
- How many nodes does your cluster have?
- Is the node in the `Ready` state?

### 1.2 Inspecting node details

With `describe` we get detailed information about a resource:

```bash
kubectl describe node minikube
```

**Tasks:**

1. Find out:
   - How many CPUs are available on the node?
   - Which operating system and version is installed? (Hint: "OS Image")
   - How much RAM is available in total? (Hint: "Capacity")
   - What percentage of the RAM is already allocated? (Hint: "Allocated resources")

2. Scroll to "Non-terminated Pods" – which system pods are already running on the node?

---

## Part 2: Exploring resources in the cluster

### 2.1 Displaying all pods

Pods are the smallest deployable unit in Kubernetes. Let's take a look at what is already running:

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
- `kube-system` runs system components (CoreDNS, kube-proxy, etc.)
- Every pod has a status (Running, Pending, etc.)

### 2.2 Which resources exist in the first place?

Kubernetes knows many different resource types. Display all of them:

```bash
kubectl api-resources
```

**Tasks:**

1. Find the entry for `pods` in the list – what is its short form (SHORTNAMES)?
2. What are the short forms of `services`, `deployments`, and `namespaces`?
3. Try it out:

   ```bash
   kubectl get po -A        # instead of pods
   kubectl get svc -A       # instead of services
   kubectl get deploy -A    # instead of deployments
   kubectl get ns           # instead of namespaces
   ```

**Tip:** The short forms save you typing. It's worth memorizing them.

### 2.3 Understanding the namespace system

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

**Task:** How many pods are running in the `kube-system` namespace?

---

## Part 3: Mastering output formats

### 3.1 Extended information with `-o wide`

By default, `kubectl get` only shows the most important columns. With `-o wide` you get more details:

```bash
kubectl get pods -A -o wide
```

**What do you see now in addition?**

- IP addresses of the pods
- Which node the pod is running on
- Nominated Node, Readiness Gates (if present)

**Task:** Write down the IP address of a pod from the `kube-system` namespace.

### 3.2 Outputting YAML and JSON

Every resource in Kubernetes is stored internally as JSON/YAML. You can inspect the full
definition:

```bash
# YAML format (human-readable)
kubectl get pod <POD-NAME> -n kube-system -o yaml

# JSON format (machine-readable)
kubectl get pod <POD-NAME> -n kube-system -o json
```

**Replace `<POD-NAME>`** with a real pod name, e.g. `kube-scheduler-minikube`

**Tasks:**

1. Look at the YAML output – can you find sections like `metadata`, `spec`, and `status`?
2. With `jsonpath` you can extract specific fields:

   ```bash
   # Output only the pod's IP
   kubectl get pod <POD-NAME> -n kube-system -o jsonpath='{.status.podIP}'
   ```

### 3.3 Custom Columns

You can also build your own tables:

```bash
kubectl get pods -A -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

**Explain in your own words:** What does this command display?

---

## Part 4: Live observation with `--watch`

With `--watch` (or `-w`) you can follow changes in real time:

```bash
kubectl get pods -A --watch
```

Leave this command running and open the following **in a second terminal**:

```bash
# Creates a test pod
kubectl run nginx-test --image=nginx

# In terminal 1 you can now watch the pod come to life:
# - First: Pending
# - Then: ContainerCreating
# - Finally: Running
```

Stop `--watch` with `Ctrl+C`.

**Cleaning up:**

```bash
kubectl delete pod nginx-test
```

Watch the deletion in real time as well if you run `--watch` again!

---

## Part 5: Kubectl help

### 5.1 The `explain` function

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

---

## Part 6: Checking resource usage (bonus)

If the metrics-server addon is installed, you can inspect resource
usage:

```bash
# Enable metrics-server (if not active)
minikube addons enable metrics-server

# Wait 3 minutes, then:
kubectl top nodes
kubectl top pods -A
```

**What does it show?**

- CPU and RAM usage of the nodes
- CPU and RAM usage of individual pods

---

## Summary: The most important commands

| Command | Purpose |
| ------ | ----- |
| `kubectl version` | Show client and server version |
| `kubectl cluster-info` | Show cluster endpoints |
| `kubectl get <resource>` | List resources |
| `kubectl get <resource> -A` | Across all namespaces |
| `kubectl get <resource> -o wide` | With additional columns |
| `kubectl get <resource> -o yaml` | As a full YAML definition |
| `kubectl describe <resource> <name>` | Detailed information + events |
| `kubectl api-resources` | All available resource types |
| `kubectl explain <resource>` | API documentation |
| `kubectl get <resource> --watch` | Watch changes in real time |
| `kubectl top nodes / pods` | Resource usage (requires metrics-server) |

**Short forms:** `po` (pods), `svc` (services), `deploy` (deployments), `ns` (namespaces), `cm` (configmaps)

---

## Further resources

- [Kubectl for Docker CLI Users](https://kubernetes.io/docs/reference/kubectl/docker-cli-to-kubectl/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubectl Reference Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [JSONPath syntax in kubectl](https://kubernetes.io/docs/reference/kubectl/jsonpath/)
