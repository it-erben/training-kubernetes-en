# Challenge 1: Pods and Services

The challenges in this course are designed to be performed as quickly as possible using all of the available documentation that you could also use during the CKAD exam.

You are permitted to use the official documentation during the exam. Bookmark these sections:

* **Pods and Pod Life Cycle:** **[Kubernetes Pods Documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)**
* **Services, Load Balancing, and Networking:** **[Kubernetes Services Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)**
* **`kubectl` Reference:** **[kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)**

## Part 1: Pod creation, configuration, and troubleshooting

| Task ID | Objective | Instructions & Key Commands |
| :--- | :--- | :--- |
| **P-1** | **Imperative Creation & Port** | Create an NGINX Pod named `web-pod-8080` using the `nginx:latest` image. Specify that the container listens on port **8080**. |
| **P-2** | **YAML Generation (Dry Run)** | Generate the full YAML definition for a Pod named `busybox-yaml` using the `busybox` image and save it to a file named **`busybox.yaml`**. **Do not create the resource.** |
| **P-3** | **Environment Variables** | Create a Pod named `app-env` using the `alpine` image. Inject an environment variable named **`APP_MODE`** with the value **`testing`** into the container. |
| **P-4** | **Multi-Container Pod (Sidecar)** | **** Modify the YAML file **`busybox.yaml`** from **P-2**. Update it to create a Pod with **two containers**: `app-main` (image: `nginx`) and `log-sidecar` (image: `busybox`). Apply the modified file. |
| **P-5** | **Interactive Shell** | Open an interactive shell session (e.g., `/bin/sh`) inside the `log-sidecar` container of the Pod created in **P-4** to inspect the `/etc` directory. |
| **P-6** | **Labels and Filtering** | Create two new NGINX Pods: `pod-blue` with label `color=blue` and `pod-red` with label `color=red`. Use a single `kubectl` command to display **only** the Pods with the label `color=blue`. |
| **P-7** | **Diagnostic Detail** | A Pod named `broken-pod` is in a **`CrashLoopBackOff`** state. Use a single command to find the **`Reason`** and **`Message`** explaining why the Pod failed to start. |

## Part 2: Services and networking

| Task ID | Objective | Instructions & Key Commands |
| :--- | :--- | :--- |
| **S-1** | **ClusterIP Service Creation** | Create an **NGINX Deployment** named `nginx-deploy` with 3 replicas and the label **`app=web`**. Then, create a **ClusterIP Service** named `nginx-svc` that targets the Deployment on port 80. |
| **S-2** | **Service IP Retrieval** | Retrieve **only** the Cluster IP address of the Service `nginx-svc` using a **JSONPath** expression. |
| **S-3** | **DNS Resolution Test** | Run an ephemeral `busybox` Pod (using `--rm -it`) and use the **`nslookup`** utility to confirm that the Service **DNS name** (`nginx-svc.default.svc.cluster.local`) resolves correctly to the Service's Cluster IP. |
| **S-4** | **NodePort Service Conversion** | Modify the existing Service `nginx-svc` **in-place** to change its type from `ClusterIP` to **`NodePort`**. The Service should expose the Pod's target port 80. |
| **S-5** | **Port-Forwarding** | Select any single Pod that is part of the `nginx-deploy` Deployment. Use **port-forwarding** to access the Pod's NGINX webpage from your local terminal on port **8080**. |
| **S-6** | **Listing Endpoints** | Use `kubectl` to list the specific **Pod IP addresses and ports** that the Service `nginx-svc` is currently forwarding traffic to. |
| **S-7** | **Headless Service (Bonus)** | Create a **Headless Service** named `headless-svc` targeting the `app=web` Pods. Use `nslookup` from a debugging Pod to observe how DNS resolution differs for a Headless Service. |