# Hands-on Exercise: Ingress in AKS

## Learning Objectives

- Understand the difference between a LoadBalancer service and Ingress
- Enable and configure the Application Routing add-on
- Implement host- and path-based routing
- Set up an internal ingress controller
- Get a first look at the Gateway API

## Prerequisites

- Existing AKS cluster
- Azure CLI installed and logged in
- kubectl configured

---

## Part 1: Check and Prepare the Cluster

### 1.1 Get cluster information

```bash
# Set variables (adjust!)
RESOURCE_GROUP="<your-resource-group>"
CLUSTER_NAME="<your-cluster-name>"

# Show cluster details
az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME \
  --query "{name:name, k8sVersion:kubernetesVersion, networkPlugin:networkProfile.networkPlugin}" \
  -o table

# Set the kubectl context
az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing

# Test cluster connectivity
kubectl get nodes
```

### 1.2 Enable the Application Routing add-on (if needed)

```bash
# Enable the add-on
az aks approuting enable -g $RESOURCE_GROUP -n $CLUSTER_NAME

# Verify the activation
kubectl get pods -n app-routing-system
kubectl get ingressclass
```

**Expected output:**

```text
NAME                                     CONTROLLER
webapprouting.kubernetes.azure.com       webapprouting.kubernetes.azure.com/nginx
```

---

## Part 2: Deploy Demo Applications

### 2.1 Create the namespace and base deployments

```bash
# Create the namespace
kubectl create namespace ingress-demo
kubectl config set-context --current --namespace=ingress-demo
```

### 2.2 Deploy three demo services

```yaml
# File: demo-apps.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  namespace: ingress-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: blue
  template:
    metadata:
      labels:
        app: blue
    spec:
      containers:
      - name: nginx
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 80
        env:
        - name: SERVER_NAME
          value: "BLUE"
---
apiVersion: v1
kind: Service
metadata:
  name: svc-blue
  namespace: ingress-demo
spec:
  selector:
    app: blue
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  namespace: ingress-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: green
  template:
    metadata:
      labels:
        app: green
    spec:
      containers:
      - name: nginx
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: svc-green
  namespace: ingress-demo
spec:
  selector:
    app: green
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-api
  namespace: ingress-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: svc-api
  namespace: ingress-demo
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
# Apply and verify
kubectl apply -f demo-apps.yaml
kubectl get pods,svc -n ingress-demo
```

---

## Part 3: LoadBalancer vs. Ingress

### 3.1 Scenario A: A plain LoadBalancer service

```yaml
# File: loadbalancer-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-blue-lb
  namespace: ingress-demo
spec:
  type: LoadBalancer
  selector:
    app: blue
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f loadbalancer-service.yaml

# Wait for the external IP (can take 1-2 minutes)
kubectl get svc svc-blue-lb -n ingress-demo -w

# Test as soon as EXTERNAL-IP is available
LB_IP=$(kubectl get svc svc-blue-lb -n ingress-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$LB_IP
```

**🔍 Observation:**

- Each LoadBalancer service creates its own Azure public IP
- You'll find it in the Azure Portal under "Load Balancers"
- Cost: ~$0.005/hour per public IP + traffic

```bash
# Show Azure resources
az network public-ip list -g MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_* \
  --query "[].{name:name, ip:ipAddress}" -o table
```

### 3.2 Scenario B: Ingress with one IP for all services

```yaml
# File: basic-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: ingress-demo
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: svc-blue
            port:
              number: 80
```

```bash
kubectl apply -f basic-ingress.yaml

# Now wait about a minute until the ingress has received an IP address
# Determine the ingress IP
INGRESS_IP=$(kubectl get ingress demo-ingress -n ingress-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
# If the ingress IP is still empty, please wait a bit longer

# Test
curl http://$INGRESS_IP
```

---

## Part 4: Path-based Routing

### 4.1 Multiple paths on one IP

```yaml
# File: path-routing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
  namespace: ingress-demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - http:
      paths:
      - path: /blue
        pathType: Prefix
        backend:
          service:
            name: svc-blue
            port:
              number: 80
      - path: /green
        pathType: Prefix
        backend:
          service:
            name: svc-green
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: svc-api
            port:
              number: 80
```

```bash
kubectl apply -f path-routing.yaml

# Determine the IP
INGRESS_IP=$(kubectl get ingress path-routing -n ingress-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test all three paths
echo "=== /blue ==="
curl http://$INGRESS_IP/blue

echo "=== /green ==="
curl http://$INGRESS_IP/green

echo "=== /api ==="
curl http://$INGRESS_IP/api
```

**🔍 Exercise:** Look at the output – each path lands on a different pod.

---

## Part 5: Internal Ingress Controller

### 5.1 Create a second (internal) NGINX controller

```yaml
# File: internal-controller.yaml
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: nginx-internal
spec:
  ingressClassName: nginx-internal
  controllerNamePrefix: nginx-internal
  loadBalancerAnnotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

```bash
kubectl apply -f internal-controller.yaml

# Wait until the controller is running
kubectl get pods -n app-routing-system -w

# Check the new IngressClass
kubectl get ingressclass
```

**Expected output:**

```text
NAME                                     CONTROLLER
nginx-internal                           webapprouting.kubernetes.azure.com/nginx-internal
webapprouting.kubernetes.azure.com       webapprouting.kubernetes.azure.com/nginx
```

### 5.2 Create an internal ingress

```yaml
# File: internal-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-ingress
  namespace: ingress-demo
spec:
  ingressClassName: nginx-internal
  rules:
  - host: api.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: svc-api
            port:
              number: 80
```

```bash
kubectl apply -f internal-ingress.yaml

# Check the internal IP (10.x.x.x range)
kubectl get ingress internal-ingress -n ingress-demo
```

**🔍 Observation:** The IP is a private VNet address – you can only reach it from inside the network.

---

## Part 6: Monitoring and Troubleshooting

### 6.1 Ingress controller logs

```bash
# Show the NGINX controller logs
kubectl logs -n app-routing-system -l app.kubernetes.io/component=controller --tail=50

# In case of problems: check the events
kubectl describe ingress -n ingress-demo
```

### 6.2 Ingress status at a glance

```bash
# All ingress resources with IPs
kubectl get ingress -A -o custom-columns=\
'NAMESPACE:.metadata.namespace,NAME:.metadata.name,CLASS:.spec.ingressClassName,HOSTS:.spec.rules[*].host,ADDRESS:.status.loadBalancer.ingress[0].ip'
```

### 6.3 Inspect the NGINX configuration

```bash
# Exec into the controller pod
NGINX_POD=$(kubectl get pods -n app-routing-system -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

# Show the current NGINX config
kubectl exec -n app-routing-system $NGINX_POD -- cat /etc/nginx/nginx.conf | head -100
```

---

## Part 7: Cleanup

```bash
# Delete all demo resources
kubectl delete namespace ingress-demo

# Remove the internal controller (optional)
kubectl delete nginxingresscontroller nginx-internal
```

---

## Bonus: A First Look at the Gateway API

The Gateway API is the successor to the Ingress API. Here's a quick preview:

```yaml
# Example: Gateway API with Application Gateway for Containers
# (Requires separate setup of the ALB controller)

apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: demo-gateway
  namespace: ingress-demo
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: blue-route
  namespace: ingress-demo
spec:
  parentRefs:
  - name: demo-gateway
  hostnames:
  - "blue.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: svc-blue
      port: 80
```

**Differences from the Ingress API:**

- Role-based model (infra admin vs. app developer)
- Better typing and validation
- Native traffic splitting
- Cross-namespace routing

## Further Reading

- [AKS Application Routing documentation](https://learn.microsoft.com/en-us/azure/aks/app-routing)
- [Kubernetes Ingress concepts](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Gateway API documentation](https://gateway-api.sigs.k8s.io/)
- [Application Gateway for Containers](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)
