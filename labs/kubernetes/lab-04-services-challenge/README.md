# Lab 04: Challenge: Services

In this exercise you will create a pod and expose it through a service. You will then test access and afterwards
change the service type.

---

## Step 1: Create a pod

1. Create a pod named `myapp`.
2. Use the Docker image `nginx:1.29`.
3. The container must expose **port 80**.

---

## Step 2: Create a service

1. Create a service named `myapp` that exposes the pod above.
2. The service type must be `ClusterIP`.
3. The service should listen on **port 80** and map it to the container's target port, i.e. **port 80**.

---

## Step 3: Scale and test access

1. Create another pod with an identical specification but a **different name** than in step 1.
2. Create yet another pod, this time with the image `busybox:1.37`, and attach to it directly.
    > When you create a pod with `kubectl run -it`, you are connected directly to a shell session.
3. Inside this temporary pod, run a `wget` command against the ClusterIP of the `myapp` service to confirm
    successful internal communication.

---

## Step 4: Update the service type

1. Delete the `myapp` service and recreate it with a different type: `NodePort`.
2. This enables access to the application from outside the Kubernetes cluster.
3. Use the command `minikube service myapp` to open the service. The service will automatically open in the
    browser.
