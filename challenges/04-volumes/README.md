# Challenge: Volumes

## Task 1: Ephemeral Volumes

* **Create a Pod YAML manifest** with two containers, both using the **`alpine:3.12.0`** image.
* **Specify a command** for both containers that ensures they remain in a **running state indefinitely**.
* **Define an `emptyDir` Volume** within the Pod.
    * **Container 1** must mount this Volume at the path **`/etc/a`**.
    * **Container 2** must mount this Volume at the path **`/etc/b`**.
* Access **Container 1** via an **interactive shell** and create a directory named **`data`** inside its mount path.
* Navigate to the newly created directory and create a file named **`hello.txt`** containing the text **`Hello World.`**
* Exit the container shell.
* Access **Container 2** via an **interactive shell** and navigate to the directory **`/etc/b/data`**.
* **Inspect the contents** of the **`hello.txt`** file.
* Exit the container shell.

***

## Task 2: Persistent Volumes

* **Create a PersistentVolume (PV)** named **`logs-pv`**.
    * It should use **`hostPath`** pointing to **`/var/logs`**.
    * Access modes must include **`ReadWriteOnce`** and **`ReadOnlyMany`**.
    * Provision a storage capacity of **`5Gi`**.
    * Verify that the PV's status is **`Available`**.
* **Create a PersistentVolumeClaim (PVC)** named **`logs-pvc`**.
    * It must request the **`ReadWriteOnce`** access mode.
    * Request a capacity of **`2Gi`**.
    * Verify that the PVC's status is **`Bound`** (to the PV).
* **Create a Pod** running the **`nginx`** image and **mount the `logs-pvc`** at the path **`/var/log/nginx`**.
* Open an **interactive shell** to the Pod's container and create a new file named **`mynginx.log`** inside **`/var/log/nginx`**. Exit the Pod.
* **Delete the Pod** and then **re-create it** using the exact same YAML manifest.
* Open an **interactive shell** to the new Pod, navigate to **`/var/log/nginx`**, and **verify the existence** of the **`mynginx.log`** file created previously.
