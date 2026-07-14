# Lab 03: Horizontal Pod Autoscaling with HPA and KEDA on AKS

For this exercise, create a cluster as in exercise 1 and set the
environment variables as described there.

## Part 1: Horizontal Pod Autoscaler (HPA) – basics

### Task 1.1: Deploy a demo application

Create a CPU-intensive application for the load test scenarios.

**File: `cpu-stress-deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress-app
  labels:
    app: cpu-stress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-stress
  template:
    metadata:
      labels:
        app: cpu-stress
    spec:
      containers:
        - name: stress
          image: vish/stress
          resources:
            requests:
              cpu: "100m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
          args:
            - -cpus
            - "1"
---
apiVersion: v1
kind: Service
metadata:
  name: cpu-stress-svc
spec:
  selector:
    app: cpu-stress
  ports:
    - port: 80
      targetPort: 8080
```

```bash
kubectl apply -f cpu-stress-deployment.yaml
```

### Task 1.2: Create an HPA with a CPU metric

Create an HPA that reacts to CPU utilization.

**File: `hpa-cpu.yaml`**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-stress-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-stress-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 30
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
      selectPolicy: Max
```

```bash
kubectl apply -f hpa-cpu.yaml
```

### Task 1.3: Observe and test the HPA

Observe the behavior of the HPA. It can take about a minute until it starts
doing its work – until then, the last measured CPU utilization is still
`<unknown>`.

```bash
# Continuously observe HPA status
kubectl get hpa cpu-stress-hpa --watch

# In a separate terminal: show details
kubectl describe hpa cpu-stress-hpa
```

**Questions for reflection:**

1. Which metrics are currently collected by the HPA?
2. What do the values in the TARGETS column mean?
3. How long does it typically take for the HPA to react to load
   changes?

By the way, you can now also test cluster autoscaling if it is enabled in the
cluster. If you set the `maxReplicas` field in the YAML to a very high value,
e.g. `100`, AKS will soon have to start new nodes. But please remember
to delete the deployment afterwards to relieve the cluster again.

## Part 2: Enable KEDA on AKS

### Task 2.1: Enable the KEDA add-on

KEDA is available as a native AKS add-on and is managed by Microsoft. This
is the recommended method for AKS.

**Enable it on an existing cluster:**

```bash
# Enable the KEDA add-on
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --enable-keda

# Verify the installation
kubectl get pods -n kube-system -l app=keda-operator
```

**Note:** When creating a cluster, KEDA can be enabled directly with `--enable-keda`
(see prerequisites).

### Task 2.2: Check the KEDA add-on status

As a final test, we now check whether KEDA is really enabled:

```bash
# Show the add-on status in the cluster
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --query "workloadAutoScalerProfile.keda" -o json
```

---

## Part 3: Event-based autoscaling with KEDA

### Scenario A: Azure Service Bus queue scaler

This scenario shows how KEDA scales based on the message count of an Azure
Service Bus queue.

Azure Service Bus is an Azure service that transports messages between
applications. This decouples systems from each other, so they can work
independently and no messages are lost, even if a system
is briefly offline.

#### Task 3.1: Set up Azure Service Bus

```bash
# Create a Service Bus namespace
az servicebus namespace create \
  --resource-group $RESOURCE_GROUP \
  --name sb-keda-demo-$RANDOM \
  --location germanywestcentral \
  --sku Standard

# Create a queue
SB_NAMESPACE=$(az servicebus namespace list -g $RESOURCE_GROUP --query "[0].name" -o tsv)
az servicebus queue create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $SB_NAMESPACE \
  --name orders-queue

# Retrieve the connection string
SB_CONNECTION=$(az servicebus namespace authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $SB_NAMESPACE \
  --name RootManageSharedAccessKey \
  --query primaryConnectionString -o tsv)

echo "Connection String: $SB_CONNECTION"
```

#### Task 3.2: Create the queue consumer deployment

In this scenario, we simulate an order processor that processes messages from
a Service Bus queue. In practice, this would be an application
that:

- Reads messages from the queue
- Processes the order (e.g. validation, database writes)
- Acknowledges the message after successful processing

For the exercise, we use a simple demo image that simulates the
processing:

**File: `queue-consumer-deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-processor
  labels:
    app: order-processor
spec:
  replicas: 0  # KEDA starts at 0 and scales based on queue length
  selector:
    matchLabels:
      app: order-processor
  template:
    metadata:
      labels:
        app: order-processor
    spec:
      containers:
        - name: processor
          # Demo image: simulates message processing via sleep
          # In production: your own consumer application (e.g. .NET, Java, Python)
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - |
              echo "Order processor started"
              echo "Waiting for messages from queue: $QUEUE_NAME"
              # Simulates continuous processing
              while true; do
                echo "[$(date)] Processing orders..."
                sleep 10
              done
          env:
            - name: QUEUE_NAME
              value: "orders-queue"
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
```

Note for practice: a real Service Bus consumer would look like this, for example:

- .NET: `Azure.Messaging.ServiceBus` SDK with `ServiceBusProcessor`
- Java: `azure-messaging-servicebus` with `ServiceBusProcessorClient`
- Python: `azure-servicebus` with `ServiceBusReceiver`

```bash
kubectl apply -f queue-consumer-deployment.yaml

# Verify that no pod is running (replicas: 0)
kubectl get pods -l app=order-processor
```

#### Task 3.3: KEDA TriggerAuthentication and ScaledObject

KEDA needs to connect to Azure Service Bus to check whether there are messages in
the queue. For this, we need to store the connection string as a
Kubernetes Secret:

```bash
# Create the secret with the real connection string
kubectl create secret generic servicebus-secret \
  --from-literal=connectionString="$SB_CONNECTION"
```

We also need a so-called `TriggerAuthentication`:
it tells KEDA how to connect to the trigger source. In this
case, this works via the secret we just created.

**File: `keda-servicebus-auth.yaml`**

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: azure-servicebus-auth
spec:
  secretTargetRef:
    - parameter: connection
      name: servicebus-secret
      key: connectionString
```

Furthermore, we have to configure KEDA so that it scales our order processor,
which we created earlier. This is done via a so-called
`ScaledObject`. It will create a `HorizontalPodAutoscaler` for us and
adjust it according to the throughput of the message queue.

**File: `keda-servicebus-scaledobject.yaml`**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor-scaler
spec:
  scaleTargetRef:
    name: order-processor
  pollingInterval: 15
  cooldownPeriod: 300
  minReplicaCount: 0
  maxReplicaCount: 30
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 120
          policies:
            - type: Percent
              value: 25
              periodSeconds: 60
  triggers:
    - type: azure-servicebus
      metadata:
        queueName: orders-queue
        messageCount: "5"
        activationMessageCount: "1"
      authenticationRef:
        name: azure-servicebus-auth
```

Of course, we still need to apply the files:

```bash

kubectl apply -f keda-servicebus-auth.yaml
kubectl apply -f keda-servicebus-scaledobject.yaml
```

#### Task 3.4: Test the scaling

The Azure CLI does not support sending Service Bus messages directly (only
management operations). We will therefore simulate the load via the Azure portal.

- Open the Service Bus namespace in the Azure portal
- Under "Entities", select the queue `orders-queue`
- Click "Service Bus Explorer" in the left menu
- Select "Send messages"
- Enter a message and click "Send"
- Repeat this several times or use "Repeat send"

Meanwhile, observe the behavior of the deployment and the HPA.

```bash
kubectl get pods -l app=order-processor --watch
kubectl get scaledobject order-processor-scaler -o yaml
kubectl get hpa
```

**Look at:**

- How many seconds after sending the messages does the scaling begin?
- To how many pods is it scaled?
- How does the scale-down behave after all messages have been processed?
