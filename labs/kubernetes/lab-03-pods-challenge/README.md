# Lab 03: Challenge: Pods

## Part 1: Pod creation, configuration, and troubleshooting

1. Create a new namespace and call it `ckad`.
   > The easiest way is the command `kubectl create namespace ckad`.
2. In the `ckad` namespace, create a pod named `nginx` that uses the image `nginx:1.29` and exposes container port
   **80**.
3. Then retrieve the details (`describe`) of the pod, including its IP address.
4. Create a temporary pod with the image `busybox:1.37` to run a `wget` command inside it. This
   `wget` call should target the endpoint of the `nginx` container. Confirm success by seeing the HTML response body
   appear in the terminal.
5. Display the logs of the `nginx` container.
6. Delete the pod. Create a new pod and use the following environment variables for your container:
   - `DB_URL=postgresql://mydb:5432`
   - `DB_USERNAME=admin`
7. Open an interactive shell inside the `nginx` container and run `ls -l` to inspect the current directory contents.
   Also display the environment variables with `printenv`. Then exit the shell.
   > To open a shell in a pod, you can use the command `kubectl exec -it nginx -- /bin/sh`.

## Part 2: YAML specifications

1. Write a YAML manifest in a file for a pod named `loop` that uses the image `busybox:1.37`. The
   pod's container should run the following command immediately after starting:
   `for i in $(seq 10); do echo "Welcome $i times"; done`.
   > You can generate a template for a new pod with the command
   > `kubectl run nginx --image=busybox:1.37 --dry-run=client -o yaml`.
2. Create the pod using this YAML manifest.
3. Determine the current status of the `loop` pod.
4. Delete the `loop` pod and recreate it in a modified form by changing its command in the YAML. The new command should
   be an endless loop that prints the current date on each iteration.
   > In the shell you can run the `date` command to get the current date. You can create an endless loop
   > with `while true; do date; sleep 1; done`.
5. Inspect the events and the status of the `loop` pod.
