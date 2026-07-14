# Lab 24: Kubernetes Cluster Plumbing – Under the Hood

## Part 1: Control Plane Anatomy

### Exercise 1.1 – Inspecting Static Pods

The control plane components run as **static pods** – the kubelet starts them directly from
manifest files, not via the API.

```bash
# SSH into the node
minikube ssh

# Get superuser privileges (you need to do this in the following exercises as well)
sudo su -

# Find the static pod manifests
ls -la /etc/kubernetes/manifests/

# Analyze the contents of a manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Tasks:**

1. List all static pod manifests
2. In `kube-apiserver.yaml`, identify:
    - Which port is used?
    - Where are the TLS certificates located?
    - Which etcd endpoints are configured?
3. Find out which admission controllers are enabled (`--enable-admission-plugins`)
    > An admission controller is a code module in the API server that intercepts requests after authentication and
    > authorization and either validates them (reject/allow) or mutates them
    > (add/change fields) before the object is stored in etcd. Typical examples: adding
    > default limits (`LimitRanger`), enforcing ResourceQuotas, or injecting
    > ServiceAccount tokens into pods.
4. Document the most important startup parameters of the API server

**Reflection:** What happens if you edit one of these files?

---

### Exercise 1.2 – Analyzing the Kubelet Configuration

The kubelet is the agent on every node. It receives pod specifications from the API server and
makes sure the container runtime starts, monitors, and if necessary restarts the corresponding
containers.

Let's take a closer look at it:

```bash
minikube ssh

# Find the kubelet process
ps aux | grep kubelet

# Kubelet configuration
cat /var/lib/kubelet/config.yaml
```

**Tasks:**

1. Determine:
    - `clusterDNS` – Which DNS server IP is configured?
    - `clusterDomain` – Which domain is used for Services?
    - `cgroupDriver` – Which cgroup driver is active?

2. Find the `staticPodPath` setting – how does the kubelet know where the static pods are located?
    > The `cgroupDriver` determines how Kubernetes limits and monitors container resources (CPU, memory, I/O) via
    > Linux control groups. The two options are `systemd` and `cgroupfs`, and both sides
    > (kubelet and container runtime) must use the same driver.

3. Check the kubelet service:

   ```bash
   sudo systemctl status kubelet
   sudo journalctl -u kubelet --no-pager | tail -50
   ```

---

### Exercise 1.3 – Certificates and PKI

In a Kubernetes cluster, all components communicate over encrypted connections and authenticate
each other with certificates. This is called **mTLS (mutual TLS)**: not only does the client verify
the server certificate (as with normal HTTPS), the server also demands a valid client certificate.
This is how the kubelet identifies itself to the API server, for example – and how the kubelet in
turn verifies that it is really talking to the genuine API server.

The entire chain of trust rests on a **cluster-owned Certificate Authority (CA)**.
This CA signs all certificates in the cluster – for the API server, etcd, the kubelets, and also
for users like the `minikube-user` in your kubeconfig. Anyone who trusts the CA certificate
automatically accepts every certificate it has signed.

For administrators, this matters for several reasons. Certificates expire (typically after
1-3 years) and must be renewed in time, otherwise the cluster grinds to a halt. When you
troubleshoot connection problems between components, an expired or misconfigured certificate is
often the cause. And understanding the PKI is essential for grasping how RBAC works: a user's
username and group membership are read straight from the certificate (`CN` for the name, `O` for
the group).

First, get an overview:

```bash
minikube ssh

# Certificate directory
ls -la /var/lib/minikube/certs/

# Inspect a certificate
openssl x509 -in /var/lib/minikube/certs/apiserver.crt -text -noout | head -30
```

**Tasks:**

1. Identify the CA certificate (Certificate Authority)
2. For the API server certificate, determine:
    - Subject and issuer
    - Validity period
    - Subject Alternative Names (SANs) – why are there several?
3. Find the client certificate that kubectl uses:

   ```bash
   # Outside of minikube ssh:
   kubectl config view --raw | grep client-certificate-data
   # Base64-decode and analyze
   ```

**Discussion:** What happens when certificates expire? How would you monitor this?

---

## Part 2: etcd – The Cluster's Memory

### Exercise 2.1 – Querying etcd Directly

etcd is the distributed key-value database in which Kubernetes stores the entire cluster state
– every object you create via kubectl ultimately ends up as an entry in etcd.

To use `etcdctl`, the CLI for etcd, we first need to install it:

```bash
minikube ssh

sudo su -

ETCD_VER=v3.5.17
curl -LO https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
rm -rf etcd-${ETCD_VER}-linux-amd64*
```

Now let's take a closer look at etcd using its CLI:

```bash
minikube ssh

# etcdctl with the correct certificates
alias etcdctl='etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key'

# Check cluster health
etcdctl endpoint health
etcdctl endpoint status --write-out=table

# Show all keys (careful: lots of output!)
etcdctl get / --prefix --keys-only | head -50
```

**Tasks:**

1. Check the etcd cluster health
2. How many members does the etcd cluster have?
3. List all keys belonging to Deployments:

   ```bash
   etcdctl get /registry/deployments --prefix --keys-only
   ```

4. Read the raw data of a Secret from etcd:

   ```bash
   # First create a test secret (outside SSH):
   kubectl create secret generic test-secret --from-literal=password=supersecret

   # In minikube ssh:
   etcdctl get /registry/secrets/default/test-secret
   ```

**⚠️ Security discussion:** What do you notice about the secret data? Why is "etcd encryption at rest" important?

---

### Exercise 2.2 – etcd Backup and Restore

etcd backups are your insurance against a control plane failure.
Fortunately, `etcdctl` does part of the work for us.

```bash
minikube ssh

# Create a snapshot
etcdctl snapshot save /tmp/etcd-backup.db

# Verify the snapshot
etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

**Tasks:**

1. Create an etcd snapshot
2. Note down the snapshot metadata (revision, total keys, size)
3. Create a new Deployment:

   ```bash
   # Outside SSH:
   kubectl create deployment backup-test --image=nginx --replicas=3
   ```

4. Create another snapshot – what has changed?
5. **Thought experiment:** Sketch the restore process:
    - What has to be stopped?
    - How is the snapshot restored?
    - What happens to resources that were created after the backup?

---

## Part 3: Container Runtime & Networking

### Exercise 3.1 – containerd and crictl

Kubernetes talks to its container runtime through the **Container Runtime Interface (CRI)**. In this
exercise you'll work with crictl, the low-level tool for it.

```bash
minikube ssh

# Show running containers (not pods!)
sudo crictl ps

# Show all pods
sudo crictl pods

# Container details
sudo crictl inspect <container-id>
```

**Tasks:**

1. List all running containers – how does this differ from `kubectl get pods`?
2. Find the containers belonging to the `kube-system` namespace
3. Inspect a container and find:
    - The image used (with SHA)
    - The process ID (PID) on the host
    - The mount points
4. Stop a container manually:

   ```bash
   sudo crictl stop <container-id>
   ```

   What happens? (Observe with `kubectl get pods -w`)

**Insight:** The kubelet restores the desired state.

---

### Exercise 3.2 – Understanding Pod Networking and DNS

#### Background: What Is DNS and Why Does Kubernetes Need It?

DNS (Domain Name System) translates names into IP addresses. Instead of memorizing `142.250.185.78`,
you type `google.com` – a DNS server handles the translation.

In Kubernetes, DNS is even more important: pods come and go all the time, and their IP addresses change.
If your frontend pod wants to talk to the backend, it cannot use a fixed IP.
Instead, it asks: *"Where do I find the Service `backend`?"* – and the cluster DNS answers with
the current Service IP.

**Kubernetes has its own DNS server (CoreDNS)** that only works inside the cluster
and automatically knows all Services and pods.

For this exercise, it makes sense to create a ClusterIP Service named `backend`.

---

#### Step 1: Start a Debug Pod

```bash
# Outside the Minikube VM
kubectl run netdebug --image=nicolaka/netshoot --rm -it -- bash
```

This image contains network tools such as `nslookup`, `dig`, `ip`, and `traceroute`.

---

#### Step 2: Look at the Pod's DNS Configuration

```bash
# Inside the pod started above
cat /etc/resolv.conf
```

**Expected output:**

```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**What does that mean?**

| Line | Meaning |
| ----- | --------- |
| `nameserver 10.96.0.10` | The IP of the CoreDNS Service – all DNS queries go here |
| `search default.svc.cluster.local ...` | Search domains that are appended automatically (see below) |
| `ndots:5` | If a name has fewer than 5 dots, the search domains are tried first |

---

#### Step 3: Understand the Search Domains

The `search` line is the key to the Kubernetes DNS magic. When you ask for `backend`, the resolver automatically tries:

1. `backend.default.svc.cluster.local` ← Service "backend" in your own namespace
2. `backend.svc.cluster.local`
3. `backend.cluster.local`
4. `backend` (if nothing was found)

**This means:** You can refer to Services in your own namespace simply by name!

```bash
# These queries are all equivalent (for a Service in the default namespace):
nslookup backend
nslookup backend.default
nslookup backend.default.svc
nslookup backend.default.svc.cluster.local
```

---

#### Step 4: Test DNS Resolution

**Resolve a cluster-internal Service:**

```bash
nslookup kubernetes
```

**Expected output:**

```text
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1
```

**Interpretation:**

- `Server: 10.96.0.10` – The query went to CoreDNS
- `kubernetes.default.svc.cluster.local` – The fully qualified DNS name
- `Address: 10.96.0.1` – The ClusterIP of the kubernetes API Service

**Resolve an external domain:**

```bash
nslookup google.com
```

CoreDNS forwards external queries to the host's DNS servers.

---

#### Step 5: Service Discovery in Action

Create a test Service (in a separate terminal):

```bash
kubectl create deployment webserver --image=nginx
kubectl expose deployment webserver --port=80
```

Back in the netdebug pod:

```bash
# Find the Service via DNS
nslookup webserver

# And talk to it directly!
curl http://webserver
```

**This is service discovery:** Your pod knows nothing about IPs – it asks DNS and gets an answer.

---

#### Step 6: Namespaces and DNS

Services in other namespaces require the namespace name:

```bash
# CoreDNS runs in the kube-system namespace
nslookup kube-dns.kube-system
```

**Expected output:**

```text
Name:   kube-dns.kube-system.svc.cluster.local
Address: 10.96.0.10
```

**Mnemonic for DNS names:**

```text
<service>.<namespace>.svc.cluster.local
    │         │       │       │
    │         │       │       └── Cluster domain (from the kubelet config)
    │         │       └── Marker: this is a Service
    │         └── Namespace of the Service
    └── Service name
```

---

#### Step 7: What Happens When DNS Fails?

Without DNS, your cluster is practically blind – pods can no longer find each other.

```bash
# In a separate terminal: stop CoreDNS
kubectl scale deployment coredns -n kube-system --replicas=0

# In the netdebug pod: the DNS query hangs
nslookup webserver
# ... waits ... timeout after ~15 seconds

# But: direct IP still works!
curl http://10.96.x.x  # (the Service IP, if known)

# Restore DNS
kubectl scale deployment coredns -n kube-system --replicas=2
```

---

#### Summary: DNS in the Kubernetes Cluster

| Concept | Meaning |
| ------- | --------- |
| CoreDNS | The cluster's DNS server (runs as a pod in kube-system) |
| ClusterIP of the DNS | Typically `10.96.0.10` (configured as nameserver in every pod) |
| Service resolution | `<service>` → `<service>.<namespace>.svc.cluster.local` |
| Search domains | Allow short forms like `backend` instead of the full name |
| External queries | Are forwarded by CoreDNS to upstream DNS |

---

## Part 4: Node Operations

### Exercise 4.1 – Node Drain and Maintenance

Before you update a node, you have to "evacuate" it: its pods get stopped, and the scheduler
assigns them to another node. This happens in two stages – first the node is marked as
"unschedulable", then the pods are stopped. Here are the individual steps:

```bash
# With Minikube and multiple nodes:
# minikube node add

# Or: simulation with cordon/uncordon on the single node

# Mark the node as unschedulable
kubectl cordon minikube

# Check the status
kubectl get nodes

# "Evacuate" the pods (on a single node: they become pending)
kubectl drain minikube --ignore-daemonsets --delete-emptydir-data --force

# Release the node again
kubectl uncordon minikube
```

**Tasks:**

Run through the steps above. Watch what happens to the pods after the `cordon` and after the `drain`.

---

## Part 5: Incident Simulation

### Exercise 5.1 – "Breaking" a Control Plane Component

**⚠️ Only in test environments!**

```bash
minikube ssh

# Temporarily stop the API server
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# What happens?
# (Outside SSH - this will fail!)
kubectl get nodes
```

**Tasks:**

1. Stop the API server by removing the manifest
2. Observe:
    - What can you still do with kubectl?
    - Do the workloads keep running?
    - What does `crictl ps` show?

3. Restore the API server
4. Repeat with the scheduler – what happens to new pods?

**Document:** What is the impact of each component failing?

| Component | Workloads running? | New pods possible? | kubectl works? |
| ---------- | ----------------- | ------------------ | --------------------- |
| API server | | | |
| Scheduler | | | |
| Controller manager | | | |
| etcd | | | |

---

### Exercise 5.2 – Simulating a Node Failure

```bash
# Simulate a "Not Ready" node by stopping the kubelet
minikube ssh
sudo systemctl stop kubelet

# Observe from outside
kubectl get nodes -w

# After ~40 seconds: the node becomes NotReady
# After ~5 minutes: pods are evacuated (on a multi-node cluster)
```

**Tasks:**

1. Stop the kubelet and measure:
    - When does the node become `NotReady`?
    - When does the pod evacuation begin?

2. Start the kubelet again – what happens?

3. Find the related configuration parameters:
    - `node-monitor-grace-period` (controller manager) – how quickly a node is marked as `NotReady`.
    - `default-not-ready-toleration-seconds` and `default-unreachable-toleration-seconds` (API server) –
      how long pods on a `NotReady`/`unreachable` node are tolerated before they are evacuated.
      Since Kubernetes 1.18, taint-based eviction has replaced the older `pod-eviction-timeout` flag of the
      controller manager.

---

## Summary: Admin Checklist

After these exercises you should be able to answer these questions:

- [ ] Where are the static pod manifests located?
- [ ] How do I access etcd and create backups?
- [ ] Which certificates does the cluster use and when do they expire?
- [ ] How do I debug at the container level with crictl?
- [ ] How does DNS resolution work in the cluster?
- [ ] How do I prepare a node for maintenance?
- [ ] What happens when individual control plane components fail?

---

## Quick Reference: Important Paths

| What | Path |
| --- | ---- |
| Static pods | `/etc/kubernetes/manifests/` |
| Kubelet config | `/var/lib/kubelet/config.yaml` |
| Certificates | `/var/lib/minikube/certs/` or `/etc/kubernetes/pki/` |
| etcd data | `/var/lib/etcd/` |
| CNI config | `/etc/cni/net.d/` |
| Container logs | `/var/log/containers/` |
| Kubelet logs | `journalctl -u kubelet` |

---

*These exercises give you the background to administer clusters, not just use them.*
