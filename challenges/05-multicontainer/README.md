# Challenge: Multi-Container Pods

## Task 1: Init Containers

* **Create a YAML manifest** for a Pod named **`complex-pod`**.
    * The **main application container**, named **`app`**, should use the image **`nginx:1.25.1`** and expose container port **`80`**.
    * Modify the manifest to include an **init container**, named **`setup`**, that uses the image **`busybox:1.36.1`**.
    * The init container must execute the command: **`wget -O- google.com`**.
* **Create the Pod** using this YAML manifest.
* **Retrieve the logs** from the **`setup`** init container. The output of the **`wget`** command should be visible.
* **Open an interactive shell** into the **`app`** main application container and execute the **`ls`** command.
* **Exit** the container shell.
* **Force-delete** the Pod.

---

## Task 2: Sidecar Containers and Volume Sharing

* **Create a YAML manifest** for a Pod named **`data-exchange`**.
    * The **main application container**, named **`main-app`**, should use the image **`busybox:1.36.1`**.
    * The container must run a command that operates in an **infinite loop**, writing a new file every **30 seconds** into the directory **`/var/app/data`**.
    * The filename should follow the pattern **`{counter++}-data.txt`**, where a counter starts at **`1`** and increments with each file created.
* **Modify the YAML manifest** to add a **sidecar container**, named **`sidecar`**.
    * The sidecar must use the image **`busybox:1.36.1`**.
    * It must run a command that operates in an **infinite loop**, counting the number of files created by the `main-app` container in the shared directory every **60 seconds** and printing the count to **standard output**.
* **Define an `emptyDir` Volume** within the Pod.
* **Mount this Volume** for **both containers** at the path **`/var/app/data`**.
* **Create the Pod**.
* **Continuously stream the logs** (tail the logs) of the **`sidecar`** container.
* **Delete the Pod**.
