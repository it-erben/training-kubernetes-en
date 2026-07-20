# Lab 07: Deploy a Node.js application to AKS via ACR

> **Shell note:** The commands below are written for **bash** (`\` line continuations, `$(…)`,
> shell variables). Run them in **Azure Cloud Shell** (the `>_` button in the Azure Portal, with
> `az` and `kubectl` preinstalled) or in **WSL**. In native Windows PowerShell they won't run as written.

---

## Part 1: Create an Azure Container Registry

Create an ACR instance and connect it to your AKS cluster.

```bash
# Set variables
RESOURCE_GROUP="<Your-Resource-Group>"
CLUSTER_NAME="<Your-AKS-Cluster>"
ACR_NAME="acr$(openssl rand -hex 4)"  # Must be globally unique

# Create the ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic

# Connect the ACR to AKS (AcrPull permission)
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --attach-acr $ACR_NAME

# Determine the login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
echo "ACR Login Server: $ACR_LOGIN_SERVER"
```

---

## Part 2: Create a Node.js application

Create the following files in a new directory `hello-aks/`:

### package.json

```json
{
  "name": "hello-aks",
  "version": "1.0.0",
  "description": "Demo app for AKS deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### server.js

```javascript
const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        message: 'Hello from AKS!',
        hostname: os.hostname(),
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

### Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

# Application code
COPY server.js ./

# Do not run as root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]
```

---

## Part 3: Build the image and push it to ACR

Run the following commands:

```bash
cd hello-aks/

# Log in to ACR
az acr login --name $ACR_NAME

# Build and tag the image
docker build -t ${ACR_LOGIN_SERVER}/hello-aks:v1 .

# Push the image
docker push ${ACR_LOGIN_SERVER}/hello-aks:v1

# Verify
az acr repository list --name $ACR_NAME -o table
az acr repository show-tags --name $ACR_NAME --repository hello-aks -o table
```

---

## Part 4: Create the Kubernetes manifests

Create the following manifests. Don't forget to replace the `<ACR_LOGIN_SERVER>`
placeholder:

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-aks
  labels:
    app: hello-aks
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-aks
  template:
    metadata:
      labels:
        app: hello-aks
    spec:
      containers:
        - name: hello-aks
          image: "<ACR_LOGIN_SERVER>/hello-aks:v1"  # Replace!
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 250m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 3
            periodSeconds: 5
```

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-aks
spec:
  type: LoadBalancer
  selector:
    app: hello-aks
  ports:
    - port: 80
      targetPort: 3000
```

---

## Part 5: Run the deployment

Roll everything out.

```bash
# Deploy
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check the status
kubectl get deployments
kubectl get pods -l app=hello-aks
kubectl get service hello-aks

# Wait for the external IP
kubectl get service hello-aks -w
```

---

## Part 6: Test and verify

Time to test the application.

```bash
# Retrieve the external IP
EXTERNAL_IP=$(kubectl get service hello-aks -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test the application
curl http://${EXTERNAL_IP}/

# Call it multiple times (different hostnames due to load balancing)
for i in {1..5}; do
  curl -s http://${EXTERNAL_IP}/ | jq .hostname
done

# Test the health endpoint
curl http://${EXTERNAL_IP}/health
```
