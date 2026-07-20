# Lab 06: GitOps with Flux on AKS

For this lab, create a cluster as in Lab 01 and set the environment variables described there.

> **Shell note:** The commands below are written for **bash** (`\` line continuations, `$(…)`,
> shell variables). Run them in **Azure Cloud Shell** (the `>_` button in the Azure Portal, with
> `az` and `kubectl` preinstalled) or in **WSL**. In native Windows PowerShell they won't run as written.

## Background: What is GitOps?

GitOps is a deployment paradigm in which Git serves as the **single source of truth**
for the desired cluster state. A GitOps operator (like Flux) runs
in the cluster and continuously watches the Git repository:

```text
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Git Repo      │◄────────│     Flux        │────────►│   Kubernetes    │
│  (Helm Charts)  │  watch  │  (in cluster)   │  sync   │    Cluster      │
└─────────────────┘         └─────────────────┘         └─────────────────┘
        ▲                                                       │
        │                     Drift Detection                   │
        └───────────────────────────────────────────────────────┘
```

**Advantages over push-based pipelines:**

- **Declarative:** The desired state is defined in Git
- **Drift detection:** Manual changes in the cluster are detected and
  corrected
- **Audit trail:** Every change is a Git commit
- **Security:** No external credentials needed for cluster access
- **Rollback:** Git revert = automatic rollback

---

## Part 1: Create the repository structure

Flux expects a specific structure. Create the following directories.
For the contents of the `charts/nginx` directory, you can reuse the chart
you built in the Helm exercise.

```text
/
├── charts/
│   └── nginx/ # Your Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
└── releases/
    └── helmrelease.yaml
```

Create the file `releases/helmrelease.yaml` with the following content:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: nginx
  namespace: flux-system
spec:
  interval: 1m
  releaseName: nginx
  driftDetection:
    mode: enabled
    
  chart:
    spec:
      chart: ./charts/nginx
      sourceRef:
        kind: GitRepository
        name: nginx
        namespace: flux-system
      interval: 1m

  targetNamespace: nginx

  install:
    createNamespace: true
    remediation:
      retries: 3

  upgrade:
    remediation:
      retries: 3

  values:
    containerPort: 80
    replicaCount: 1
    image:
      tag: "1.29"
    service:
      type: LoadBalancer

```

Then commit and push the changes:

```bash
git add .
git commit -m "feat: implement helmrelease for nginx"
git push origin main
```

---

## Part 2: Enable Flux on AKS

### Task 2.1: Install the Azure CLI extension

Make sure the required CLI extension is installed:

```bash
# Install/update the extension
az extension add --name k8s-configuration --upgrade

# Check whether the extension is available
az extension show --name k8s-configuration
```

### Task 2.2: Retrieve Kubernetes credentials

Connect to your AKS cluster:

```bash
export RG="YOUR_RESOURCE_GROUP"
export CLUSTER_NAME="YOUR_AKS_CLUSTER"

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# Test the connection
kubectl get nodes
```

### Task 2.3: Enable the Flux extension and set up the namespace

Enable Flux as an AKS extension and connect it to your Git repository.
Your trainer will give you the repository URL and the token.

```bash
kubectl create namespace nginx
az k8s-configuration flux create \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --cluster-type managedClusters \
  --name nginx \
  --namespace flux-system \
  --scope cluster \
  --url <YOUR-URL> \
  --branch main \
  --https-user "gitlab-group-token" \
  --https-key "<YOUR-GROUP-ACCESS-TOKEN>" \
  --kustomization name=releases path=./releases prune=true
```

---

## Part 3: Verify the deployment

### Check the Flux synchronization

Give Flux about 1-2 minutes to pick up the changes:

```bash
# Show HelmReleases
kubectl get helmreleases -A

# Check the status of the HelmReleases
kubectl describe helmrelease nginx -n flux-system
```

### Check the deployments

```bash
# Check pods in both namespaces
kubectl get pods -n nginx

# Check services (for external IPs)
kubectl get svc -n nginx

# Check Helm releases
helm list -n nginx
```

### Test GitOps in action

Test the GitOps principle by making a change in Git:

1. In the HelmRelease, change the `replicaCount` from `1` to `2`
2. Commit and push the change
3. Wait about 1 minute
4. Check whether 2 pods are now running in the nginx namespace:

```bash
kubectl get pods -n nginx -w
```

---

## Part 4: Test drift detection

### Manual change in the cluster

Simulate a manual change (drift) in the cluster:

```bash
# Manually scale the deployment down
kubectl scale deployment nginx-nginx-deployment -n nginx --replicas=1
```

### Observe the drift correction

Flux notices the drift and corrects it automatically:

```bash
# Watch Flux scale the pods back up
kubectl get pods -n nginx -w
```

After a short time, 2 pods should be running again (matching the
Git configuration).
