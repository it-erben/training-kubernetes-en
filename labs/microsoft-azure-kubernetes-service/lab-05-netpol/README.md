# Lab 05: Network policies with Cilium in AKS

For this lab, create a cluster as in Lab 01 and set the environment variables described there.

> **Shell note:** The commands below are written for **bash** (`\` line continuations, `$(…)`,
> shell variables). Run them in **Azure Cloud Shell** (the `>_` button in the Azure Portal, with
> `az` and `kubectl` preinstalled) or in **WSL**. In native Windows PowerShell they won't run as written.

## Part 1: Set up the test environment

### Create namespaces

For our test scenario, we use three separate namespaces for different teams.
In real projects, the question always comes up whether to slice namespaces per
team or per application – there's no universal answer. Here, we go with the
team-based model.

```bash
# Three namespaces for different teams/applications
kubectl create namespace team-frontend
kubectl create namespace team-backend
kubectl create namespace team-database

# Add labels for policy selection
kubectl label namespace team-frontend environment=production tier=frontend
kubectl label namespace team-backend environment=production tier=backend
kubectl label namespace team-database environment=production tier=database
```

### Deploy test pods

We create three pods, one in each of our three namespaces:

```bash
# Frontend pod (Nginx)
kubectl run frontend --namespace=team-frontend \
  --image=nginx:alpine \
  --labels="app=frontend,tier=web" \
  --port=80

# Backend pod (with curl for testing)
kubectl run backend --namespace=team-backend \
  --image=curlimages/curl:latest \
  --labels="app=backend,tier=api" \
  --command -- sleep infinity

# Database pod (simulated)
kubectl run database --namespace=team-database \
  --image=nginx:alpine \
  --labels="app=database,tier=data" \
  --port=80

# Create services
kubectl expose pod frontend --namespace=team-frontend --port=80
kubectl expose pod database --namespace=team-database --port=80
```

### Test baseline connectivity

Right now, all pods should be able to reach each other.
Let's verify that with a few `curl` commands via `exec`:

```bash
# From the backend to the frontend (should work)
kubectl exec -n team-backend backend -- \
  curl -s --max-time 3 frontend.team-frontend.svc.cluster.local

# From the backend to the database (should work)
kubectl exec -n team-backend backend -- \
  curl -s --max-time 3 database.team-database.svc.cluster.local

# From the frontend to the database (should work)
kubectl exec -n team-frontend frontend -- \
  curl -s --max-time 3 database.team-database.svc.cluster.local
```

---

## Part 2: Kubernetes-native NetworkPolicies

### Default deny for a namespace

Now let's create a policy that blocks all incoming traffic
to the database namespace:

```yaml
# File: 01-default-deny-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: team-database
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

```bash
kubectl apply -f 01-default-deny-database.yaml
```

### Test connectivity again

Pods in the database namespace should no longer be reachable
from the other namespaces.

```bash
# From the backend to the database (should NOT work anymore)
kubectl exec -n team-backend backend -- \
  curl -s --max-time 3 database.team-database.svc.cluster.local

# Expectation: timeout after 3 seconds
```

### Allow selective access

Now let's allow the backend namespace to talk to the database:

```yaml
# File: 02-allow-backend-to-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: team-database
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              tier: backend
      ports:
        - protocol: TCP
          port: 80
```

```bash
kubectl apply -f 02-allow-backend-to-database.yaml
```

### Validation

The backend pod should now reach the simulated database,
while the frontend no longer can.

```bash
# Backend → Database (should work)
kubectl exec -n team-backend backend -- \
  curl -s --max-time 3 database.team-database.svc.cluster.local

# Frontend → Database (should NOT work)
kubectl exec -n team-frontend frontend -- \
  curl -s --max-time 3 database.team-database.svc.cluster.local
```

Before the next task, clean up the deny rule:

```bash
kubectl delete netpol default-deny-ingress  -n team-database
```

## Part 3: Global network policies with Cilium

Cilium doesn't stop at namespace-scoped network policies – it can also define
global ones. In a moment, we'll roll out a network policy that blocks all
incoming ingress traffic on the cluster. First, we create a deployment with a
LoadBalancer and test its external IP:

```bash
# Create a LoadBalancer service for the frontend
kubectl expose pod frontend --namespace=team-frontend \
  --name=frontend-lb \
  --type=LoadBalancer \
  --port=80

# Wait until an external IP is assigned (can take 1-2 minutes)
kubectl get svc frontend-lb -n team-frontend -w

# Store the external IP
FRONTEND_IP=$(kubectl get svc frontend-lb -n team-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend LoadBalancer IP: $FRONTEND_IP"

# Test from outside (should work)
curl -s --max-time 5 http://$FRONTEND_IP
# Expectation: Nginx welcome page
```

Now we use Cilium to block all incoming ingress traffic on the
cluster:

```yaml
# 03-ccnp-default-deny-ingress.yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: ccnp-default-deny-ingress
spec:
  endpointSelector: {}
  ingressDeny:
    - fromEntities:
        - all
```

```bash
kubectl apply -f 03-ccnp-default-deny-ingress.yaml
```

After a short time, the cluster should no longer be reachable via the
external IP:

```bash
curl -s --max-time 5 http://$FRONTEND_IP
```

Once you delete the policy, the IP becomes reachable again
after a short while.

**IMPORTANT**: Don't forget to delete the `CiliumClusterwideNetworkPolicy` now:

```bash
kubectl delete ccnp ccnp-default-deny-ingress
```
