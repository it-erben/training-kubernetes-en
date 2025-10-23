## 1. Deployment and Rollout Management

This challenge focuses on creating a Deployment, performing a rolling update, managing history, and scaling.

1.  **Create the Initial Deployment:**
    * **Create a Deployment** named **`nginx`** with **3 replicas**.
    * The Pods must use the image **`nginx:1.23.0`** and the container name **`nginx`**.
    * The Deployment must use the label **`tier=backend`**.
    * The Pod template must use the label **`app=v1`**.
2.  **Verify Initial State:**
    * **List the Deployment** and confirm that **3 replicas** are running and ready.
3.  **Perform Rolling Update (Image Change):**
    * **Update the container image** in the Deployment to **`nginx:1.23.4`**.
4.  **Verify Rollout and History:**
    * **Confirm** that the image change has been successfully rolled out to all replicas.
    * **Assign the change cause** "Pick up patch version" to the latest revision.
5.  **Scale the Deployment:**
    * **Scale the Deployment** to **5 replicas**.
6.  **Revert to Previous Revision:**
    * **Inspect the Deployment rollout history.**
    * **Revert the Deployment** to **revision 1**.
7.  **Final Verification:**
    * **Ensure** that the Pods are now running the original image: **`nginx:1.23.0`**.

---

## 2. Resource Requests and HorizontalPodAutoscaler (HPA) Configuration

This challenge focuses on configuring resource requests and setting up an HPA based on multiple metrics.

1.  **Create the Deployment with Resource Constraints:**
    * **Create a Deployment** named **`nginx`** with **1 replica**.
    * Configure the Pod template to use the container image **`nginx:1.23.4`**.
    * Set the **CPU resource request** to **$0.5$** (or `500m`).
    * Set both the **memory resource request and limit** to **$500\text{Mi}$**.
2.  **Create the HorizontalPodAutoscaler (HPA):**
    * **Create an HPA** named **`nginx-hpa`** targeting the `nginx` Deployment.
    * Set the scaling range to a **minimum of 3** and a **maximum of 8 replicas**.
    * The HPA should scale based on two metrics:
        * Average **CPU Utilization** of **$75\%$**.
        * Average **Memory Utilization** of **$60\%$**.
3.  **Inspect and Predict:**
    * **Inspect the created HPA object.**
    * **Identify the currently utilized resources** (which may show as "unknown" until the Metrics Server runs).
    * Given the `minReplicas` setting, **how many replicas** are you immediately expected to exist (even before any load is applied)?
