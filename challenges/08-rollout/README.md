## 1. Deployment Update and Readiness Probe

This task focuses on rolling out an image update while ensuring application readiness and controlling the deployment pace.

1.  **Create the Initial Deployment:**
    * **Create the Deployment object** named **`grafana`** using the provided YAML manifest structure.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 6
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - image: grafana/grafana:9.5.9
        name: grafana
        ports:
        - containerPort: 3000
```
2.  **Perform Rolling Update with Safety Checks:**
    * **Update all 6 replicas** by changing the container image to **`grafana/grafana:10.1.2`**.
    * **Configure the rollout strategy** to update replicas in batches of **two at a time**.
    * **Ensure a readiness probe is defined** for the container. (The Grafana application typically becomes ready when it can respond to HTTP requests on its configured port.)

---

## 2. Blue-Green Deployment Scenario

This task focuses on performing a blue-green deployment by switching a Service's selector to redirect traffic between two separate Deployments.

1.  **Create the Blue Environment (Initial Production):**
    * **Create a Deployment** named **`nginx-blue`** with **3 replicas**.
    * The Pods must use the container image **`nginx:1.23.0`**.
    * Assign the label **`version=blue`** to the Pod template.

2.  **Expose the Blue Deployment via Service:**
    * **Create a Service** of type **`ClusterIP`** named **`nginx`**.
    * Map the incoming and outgoing ports to **$80$**.
    * **Configure the Service selector** to route traffic to Pods with the label **`version=blue`**.

3.  **Verify Initial Traffic Routing:**
    * **Run a temporary Pod** using the container image **`alpine/curl:3.14`**.
    * **Use `curl`** from within this Pod to make a request against the **`nginx` Service** to confirm traffic is reaching the blue environment.

4.  **Create the Green Environment (New Version):**
    * **Create a second Deployment** named **`nginx-green`** with **3 replicas**.
    * The Pods must use the container image **`nginx:1.23.4`**.
    * Assign the label **`version=green`** to the Pod template.

5.  **Switch Traffic (The "Cutover"):**
    * **Change the `nginx` Service's label selector** from `version=blue` to **`version=green`**. Traffic should instantly switch to the new Pods.

6.  **Clean Up the Old Environment:**
    * **Delete the Deployment** named **`nginx-blue`**.

7.  **Verify Final Traffic Routing:**
    * **Run another temporary Pod** using the container image **`alpine/curl:3.14`**.
    * **Use `curl`** to make a call against the **`nginx` Service** and confirm that the traffic is now routed to the Pods controlled by the `nginx-green` Deployment.
