# Lab 10: Challenge: Volumes

## Task 1: Ephemeral volumes

- Create a pod YAML manifest with two containers, both using the image `alpine:3.20`.
- Define a command for both containers that keeps them in the Running state indefinitely.
  > This can be done with the command `sleep infinity`.
- Create an `emptyDir` volume in the pod.
  - Container 1 must mount this volume at `/etc/a`.
  - Container 2 must mount this volume at `/etc/b`.
  > [Documentation on `emptyDir` volumes](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- Open an interactive shell into container 1 and create a directory named `data` in its mount path.
- Change into the new directory and create a file named `hello.txt` with the content `Hello World.`
- Exit the container shell.
- Open an interactive shell into container 2 and navigate to `/etc/b/data`.
- Check the contents of the file `hello.txt`.
- Exit the container shell.

## Task 2: Persistent volumes

- Create a PersistentVolume (PV) named `logs-pv`.
  - It should use `hostPath` with the path `/var/logs`.
  - The access modes must include `ReadWriteOnce` and `ReadOnlyMany`.
  - Provision `5Gi` of storage.
  - Verify that the PV status is `Available`.
- Create a PersistentVolumeClaim (PVC) named `logs-pvc`.
  - It must request the access mode `ReadWriteOnce`.
  - Request `2Gi` of capacity.
  - Verify that the PVC status is `Bound` (i.e. bound to the PV).
- Create a pod that runs the `nginx` image and mount `logs-pvc` at `/var/log/nginx`.
- Open an interactive shell into the pod's container, create a new file named
  `mynginx.log` under `/var/log/nginx`, and exit the pod.
- Delete the pod and recreate it with exactly the same YAML manifest.
- Open an interactive shell into the new pod, go to `/var/log/nginx`, and verify that the previously created file
  `mynginx.log` is still present.
