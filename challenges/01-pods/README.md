# Challenge: Pods

This course's challenges are designed to be completed as quickly as possible, utilizing all documentation accessible during the **CKAD exam**.

You are authorized to use the official documentation during the exam. Please bookmark these resources:

* **Pods and Pod Life Cycle:** **[Kubernetes Pods Documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)**
* **`kubectl` Reference:** **[kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)**

***

## Part 1: Pod creation, configuration, and troubleshooting

* In the **`ckad`** namespace, create a Pod named **`nginx`** using the **`nginx:1.17.10`** image, exposing container port **80**.
* Retrieve the Pod's details, including its **IP address**.
* Using the **`busybox:1.36.1`** image, create a temporary Pod to execute a **`wget`** command inside its container. This `wget` command should target the endpoint exposed by the **`nginx`** container. Verify the successful execution by observing the **HTML response body** printed in the terminal.
* Fetch the **logs** from the `nginx` container.
* Modify the `nginx` Pod's container to include the environment variables:
    * **`DB_URL=postgresql://mydb:5432`**
    * **`DB_USERNAME=admin`**
* Open an **interactive shell** within the `nginx` container and execute **`ls -l`** to inspect the current directory's contents. Then, **exit** the container shell.

***

## Part 2: YAML specifications

* **Generate a YAML manifest** for a Pod named **`loop`** that runs the **`busybox:1.36.1`** image. The container must execute the following command: **`for i in {1..10}; do echo "Welcome $i times"; done`**.
* **Create the Pod** using this YAML manifest.
* **Determine the current status** of the `loop` Pod.
* **Edit the `loop` Pod** to change its command. The new command should run an **endless loop** that echoes the **current date** in each iteration.
* **Inspect the events** and the **status** of the `loop` Pod.
