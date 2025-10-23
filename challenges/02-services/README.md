# Challenge: Services

This task requires creating a basic application deployment, exposing it via a Service, and then testing access, followed by updating the Service type.

---

### Step 1: Create the Deployment

1.  **Create a Pod** named **`myapp`**.
2.  Use the Docker image **`nginx:1.23.4-alpine`**.
3.  The container must expose **port 80**.

---

### Step 2: Create the Service

1.  **Create a Service** named **`myapp`** to expose the Pod.
2.  The Service type must be **`ClusterIP`**.
3.  The Service should listen on **port 80** and map it to the container's target port, **port 80**.

---

### Step 3: Scale and Test Access

1.  Create another Pod with the same specification, but different name, than in Step 1.
2.  **Create a temporary Pod** using the image **`busybox:1.36.1`**.
3.  From within this temporary Pod, **execute a `wget` command** against the ClusterIP of the **`myapp` Service** to confirm successful internal communication.

---

### Step 4: Update the Service Type

1.  **Modify the `myapp` Service** to change its type from `ClusterIP` to **`NodePort`**.
2.  This change will enable access to the application from outside the Kubernetes cluster.
