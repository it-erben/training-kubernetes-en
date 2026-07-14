# Answers for Cluster Plumbing

## Part 1: Control Plane Anatomy

### Exercise 1.1 – Inspecting Static Pods

#### Task 1: List the static pod manifests

```bash
minikube ssh
ls -la /etc/kubernetes/manifests/
```

**Expected output:**

```text
-rw------- 1 root root  2384 Jan 15 10:00 etcd.yaml
-rw------- 1 root root  3847 Jan 15 10:00 kube-apiserver.yaml
-rw------- 1 root root  3352 Jan 15 10:00 kube-controller-manager.yaml
-rw------- 1 root root  1435 Jan 15 10:00 kube-scheduler.yaml
```

---

#### Task 2: Identify API server parameters

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -E "(--secure-port|--tls-cert-file|--etcd-servers)"
```

**Expected values:**

| Parameter | Typical value (Minikube) |
| --------- | ------------------------- |
| Port | `--secure-port=8443` |
| TLS certificate | `--tls-cert-file=/var/lib/minikube/certs/apiserver.crt` |
| TLS key | `--tls-private-key-file=/var/lib/minikube/certs/apiserver.key` |
| etcd endpoints | `--etcd-servers=https://127.0.0.1:2379` |

---

#### Task 3: Determine the admission controllers

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep enable-admission-plugins
```

**Expected output (example):**

```text
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota
```

**What the important ones do:**

| Plugin | Function |
| ------ | -------- |
| `NamespaceLifecycle` | Prevents creation in terminating namespaces |
| `LimitRanger` | Enforces default limits |
| `ServiceAccount` | Automatic SA assignment |
| `NodeRestriction` | Kubelets may only modify their own node objects |
| `ResourceQuota` | Enforces namespace quotas |

---

#### Task 4: What happens when a manifest changes?

**Answer:** The kubelet watches `/etc/kubernetes/manifests/` via inotify. When a file changes:

1. The kubelet detects the change
2. It stops the pod
3. It starts a new pod with the changed config
4. The API server is never involved (static pods bypass the API)

**See for yourself:**

```bash
# Terminal 1: watch the logs
journalctl -u kubelet -f | grep -i "static"

# Terminal 2: harmless change (add an annotation)
sed -i 's/kube-scheduler/kube-scheduler\n    test: "true"/' /etc/kubernetes/manifests/kube-scheduler.yaml

# Observe: the scheduler pod is recreated
```

---

### Exercise 1.2 – Kubelet Configuration

#### Task 1: Determine important kubelet parameters

```bash
cat /var/lib/kubelet/config.yaml | grep -E "(clusterDNS|clusterDomain|cgroupDriver|staticPodPath)"
```

**Expected values (Minikube):**

```yaml
clusterDNS:
  - 10.96.0.10
clusterDomain: cluster.local
cgroupDriver: systemd
staticPodPath: /etc/kubernetes/manifests
```

**Explanation:**

| Parameter | Meaning |
| --------- | --------- |
| `clusterDNS: 10.96.0.10` | IP of the CoreDNS service (first service IP + 10) |
| `clusterDomain: cluster.local` | DNS suffix for services |
| `cgroupDriver: systemd` | Must match the container runtime |
| `staticPodPath` | Where the kubelet looks for static pod manifests |

---

#### Task 2: Check the kubelet status

```bash
systemctl status kubelet
```

**Expected output (truncated):**

```text
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled)
     Active: active (running) since Mon 2024-01-15 10:00:00 UTC
```

**Finding important log entries:**

```bash
# Errors from the last hour
journalctl -u kubelet --since "1 hour ago" | grep -i error

# Sync loop activity
journalctl -u kubelet | grep "SyncLoop"
```

---

### Exercise 1.3 – Certificates and PKI

#### Task 1: Identify the CA certificate

```bash
ls /var/lib/minikube/certs/ | grep ca
```

**Answer:** `ca.crt` and `ca.key` – the cluster CA

---

#### Task 2: Analyze the API server certificate

```bash
openssl x509 -in /var/lib/minikube/certs/apiserver.crt -text -noout
```

**What you should see:**

```text
Subject: CN = minikube
Issuer: CN = minikubeCA
Validity
    Not Before: Jan 15 10:00:00 2024 GMT
    Not After : Jan 15 10:00:00 2027 GMT    # valid for 3 years

X509v3 Subject Alternative Name:
    DNS:minikube, DNS:kubernetes, DNS:kubernetes.default,
    DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local,
    IP Address:10.96.0.1, IP Address:192.168.49.2, IP Address:127.0.0.1
```

**Why multiple SANs?**

- `kubernetes.default.svc` – service DNS name
- `10.96.0.1` – Kubernetes service ClusterIP
- `192.168.49.2` – node IP
- `127.0.0.1` – localhost access

---

#### Task 3: Extract the client certificate from the kubeconfig

```bash
# Outside of minikube ssh:
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -text -noout
```

**Expected output:**

```text
Subject: O = system:masters, CN = minikube-user
```

**Explanation:**

- `O = system:masters` → group with cluster admin privileges
- `CN = minikube-user` → username for RBAC

---

#### Discussion: Monitoring certificate expiry

```bash
# All certificates with their expiry date
for cert in /var/lib/minikube/certs/*.crt; do
  echo "=== $cert ==="
  openssl x509 -in "$cert" -noout -enddate
done
```

**Production recommendation:**

- Prometheus + cert-manager metrics
- Alert when < 30 days remain
- kubeadm: `kubeadm certs check-expiration`

---

## Part 2: etcd – The Cluster's Memory

### Exercise 2.1 – Querying etcd Directly

#### Setup: etcdctl alias

```bash
minikube ssh

# Set the alias (for this session)
alias etcdctl='etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key'
```

---

#### Task 1: Cluster health

```bash
etcdctl endpoint health
```

**Expected output:**

```text
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.234ms
```

---

#### Task 2: Cluster status and member count

```bash
etcdctl endpoint status --write-out=table
etcdctl member list --write-out=table
```

**Expected output:**

```text
+------------------------+------------------+---------+---------+-----------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER |
+------------------------+------------------+---------+---------+-----------+
| https://127.0.0.1:2379 | 8e9e05c52164694d |  3.5.9  |  5.4 MB |   true    |
+------------------------+------------------+---------+---------+-----------+

+------------------+---------+----------+------------------------+------------------------+
|        ID        | STATUS  |   NAME   |       PEER ADDRS       |      CLIENT ADDRS      |
+------------------+---------+----------+------------------------+------------------------+
| 8e9e05c52164694d | started | minikube | https://127.0.0.1:2380 | https://127.0.0.1:2379 |
+------------------+---------+----------+------------------------+------------------------+
```

**Answer:** 1 member (single-node Minikube)

---

#### Task 3: List the deployment keys

```bash
etcdctl get /registry/deployments --prefix --keys-only
```

**Expected output (example):**

```text
/registry/deployments/default/nginx
/registry/deployments/kube-system/coredns
```

---

#### Task 4: Read a secret from etcd

```bash
# Outside SSH: create the secret
kubectl create secret generic test-secret --from-literal=password=supersecret

# In minikube ssh:
etcdctl get /registry/secrets/default/test-secret
```

**Expected output (truncated, binary):**

```text
/registry/secrets/default/test-secret
k8s

v1Secret

test-secretdefault"*$3f8e9a12-...28B
password
supersecret
```

**⚠️ Security discussion:**

- The secret is stored **unencrypted**
- Base64 in the API is just encoding, not encryption
- **Solution:** configure etcd encryption at rest
- Documentation: <https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/>

---

### Exercise 2.2 – etcd Backup

#### Tasks 1-2: Create and verify a snapshot

```bash
etcdctl snapshot save /tmp/etcd-backup.db
etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

**Expected output:**

```text
Snapshot saved at /tmp/etcd-backup.db

+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 2c3d4e5f |    15847 |       1023 |     5.4 MB |
+----------+----------+------------+------------+
```

---

#### Tasks 3-4: Compare before/after creating a deployment

```bash
# Note the status of snapshot 1

# Create the deployment (outside SSH):
kubectl create deployment backup-test --image=nginx --replicas=3

# Create snapshot 2 and compare
etcdctl snapshot save /tmp/etcd-backup-2.db
etcdctl snapshot status /tmp/etcd-backup-2.db --write-out=table
```

**Expected changes:**

- `REVISION`: higher (every change increments the revision)
- `TOTAL KEYS`: more keys (deployment, ReplicaSet, 3 pods)
- `TOTAL SIZE`: slightly larger

---

## Part 3: Container Runtime & Networking

### Exercise 3.1 – containerd and crictl

#### Task 1: List the containers

```bash
crictl ps
```

**Expected output:**

```text
CONTAINER       IMAGE           CREATED         STATE    NAME                      POD ID
a1b2c3d4e5f6    6d5f77893abc    2 hours ago     Running  kube-apiserver            abc123
b2c3d4e5f6g7    7e6f88904bcd    2 hours ago     Running  etcd                      def456
c3d4e5f6g7h8    8f7g99015cde    2 hours ago     Running  kube-scheduler            ghi789
...
```

**Difference from `kubectl get pods`:**

- `crictl` shows **containers**, not pods
- One pod can have multiple containers (plus the pause container)
- `crictl` also works when the API server is down

---

#### Task 2: Filter kube-system containers

```bash
crictl pods --namespace kube-system
# or
crictl ps -o json | jq '.containers[] | select(.labels["io.kubernetes.pod.namespace"]=="kube-system")'
```

---

#### Task 3: Inspect a container

```bash
# Determine the container ID
crictl ps | grep coredns
# e.g. abc123def456

crictl inspect abc123def456
```

**Important fields in the output:**

```json
{
  "status": {
    "id": "abc123def456",
    "image": {
      "image": "registry.k8s.io/coredns/coredns:v1.11.1@sha256:abc123..."
    }
  },
  "info": {
    "pid": 4523,
    "config": {
      "mounts": [
        {
          "containerPath": "/etc/coredns",
          "hostPath": "/var/lib/kubelet/pods/.../volumes/kubernetes.io~configmap/config-volume"
        }
      ]
    }
  }
}
```

**How to extract them:**

```bash
# Image with SHA
crictl inspect abc123 | jq '.status.image'

# PID on the host
crictl inspect abc123 | jq '.info.pid'

# Mounts
crictl inspect abc123 | jq '.info.config.mounts'
```

---

#### Task 4: Stop a container manually

```bash
crictl stop <container-id>
```

**Watch from a separate terminal:**

```bash
kubectl get pods -w
# Pod status: Running → ContainerNotReady → Running (after ~10-30s)
```

**Explanation:** The kubelet notices the missing container and restarts it (reconciliation loop).

---

### Exercise 3.2 – Pod Networking

#### Tasks 1-3: Network information inside the pod

```bash
kubectl run netdebug --image=nicolaka/netshoot --rm -it -- bash

# Inside the pod:
ip addr show eth0
```

**Expected output:**

```text
3: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 10.244.0.15/24 brd 10.244.0.255 scope global eth0
```

```bash
ip route
```

**Expected output:**

```text
default via 10.244.0.1 dev eth0
10.244.0.0/24 dev eth0 proto kernel scope link src 10.244.0.15
```

```bash
cat /etc/resolv.conf
```

**Expected output:**

```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**This matches the kubelet config:** `clusterDNS: 10.96.0.10` ✓

---

## Part 4: Node Operations

### Exercise 4.1 – Node Drain

#### Tasks 1-2: Cordon

```bash
kubectl cordon minikube
kubectl get nodes
```

**Expected output:**

```text
NAME       STATUS                     ROLES           AGE   VERSION
minikube   Ready,SchedulingDisabled   control-plane   2d    v1.28.0
```

**Existing pods:** They keep running; cordon only prevents new pods from being scheduled.

---

#### Task 3: Drain

```bash
kubectl drain minikube --ignore-daemonsets --delete-emptydir-data --force
```

**Flags explained:**

| Flag | Reason |
| ---- | ----- |
| `--ignore-daemonsets` | DaemonSet pods cannot be evacuated (they run on every node by definition) |
| `--delete-emptydir-data` | Pods with emptyDir volumes lose their data – this flag confirms you accept that |
| `--force` | Pods without a controller (standalone) are deleted, not rescheduled |

---

## Part 5: Incident Simulation

### Exercise 5.1 – Control Plane Failure

**Component failure matrix (sample answer):**

| Component | Workloads keep running? | New pods possible? | kubectl works? |
| ---------- | ----------------- | ------------------ | --------------------- |
| **API server** | ✅ Yes | ❌ No | ❌ No |
| **Scheduler** | ✅ Yes | ❌ No (stay Pending) | ✅ Yes |
| **Controller manager** | ✅ Yes | ⚠️ Partially* | ✅ Yes |
| **etcd** | ✅ Yes | ❌ No | ❌ No (API hangs) |

*Controller manager: ReplicaSet changes no longer produce new pods, but creating pods manually still works.

---

**Test commands:**

```bash
# Stop the API server
minikube ssh
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# Test (outside SSH)
kubectl get nodes
# Error: connection refused

# Check the workloads (in SSH)
crictl ps | grep nginx
# Container is still running!

# Restore
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

---

### Exercise 5.2 – Node Failure

#### Task 1: Measure the timing

```bash
minikube ssh
systemctl stop kubelet

# In a separate terminal:
kubectl get nodes -w
```

**Expected timeline:**

| Time | Event |
| ---- | ----- |
| 0s | Kubelet stopped |
| ~40s | Node becomes `NotReady` (node-monitor-grace-period default: 40s) |
| ~5m | Pod eviction begins (pod-eviction-timeout default: 5m) |

---

#### Task 2: Restore the kubelet

```bash
systemctl start kubelet
```

**What you'll see:**

- The node becomes `Ready` again within ~10s
- Pods are reported as `Running` again (they never went away, they were just unreachable)

---

#### Task 3: Find the configuration parameters

```bash
# Controller manager manifest
cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep -E "(node-monitor|eviction)"
```

**Or via the API:**

```bash
kubectl get pods -n kube-system kube-controller-manager-minikube -o yaml | grep -A1 command
```

**Relevant parameters:**

```text
--node-monitor-grace-period=40s      # How long to wait before NotReady
--pod-eviction-timeout=5m0s          # How long until pods are evicted
--node-monitor-period=5s             # How often nodes are checked
```

---

## Quick Reference: All Commands

```bash
# === STATIC PODS ===
ls /etc/kubernetes/manifests/
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# === KUBELET ===
cat /var/lib/kubelet/config.yaml
systemctl status kubelet
journalctl -u kubelet -f

# === CERTIFICATES ===
openssl x509 -in /var/lib/minikube/certs/apiserver.crt -text -noout
# Expiry date of all certs:
for f in /var/lib/minikube/certs/*.crt; do echo "$f:"; openssl x509 -in "$f" -noout -enddate; done

# === ETCD ===
alias etcdctl='etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/var/lib/minikube/certs/etcd/ca.crt --cert=/var/lib/minikube/certs/etcd/server.crt --key=/var/lib/minikube/certs/etcd/server.key'
etcdctl endpoint health
etcdctl snapshot save /tmp/backup.db
etcdctl get /registry/secrets/default/<name>

# === CONTAINER RUNTIME ===
crictl ps
crictl pods
crictl inspect <id>
crictl logs <id>

# === NETWORKING ===
cat /etc/cni/net.d/*.conflist
iptables -t nat -L KUBE-SERVICES -n

# === COREDNS ===
kubectl get configmap coredns -n kube-system -o yaml
kubectl logs -n kube-system -l k8s-app=kube-dns

# === NODE OPS ===
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node>
```
