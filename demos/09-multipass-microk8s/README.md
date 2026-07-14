# Setup: Kubernetes on macOS with Multipass & MicroK8s

This demo shows how to quickly set up an isolated Kubernetes cluster on your Mac without using Docker Desktop. We use
**Canonical Multipass** (to create an Ubuntu VM) and **MicroK8s** (as a lightweight Kubernetes distribution).

We also set up **MetalLB** so that services of type `LoadBalancer` get an external IP address.

## Prerequisites

Install Multipass via Homebrew (if not already installed):

```bash
brew install --cask multipass
```

## Step 1: Create the VM

Create an Ubuntu VM with enough resources (4 CPUs, 8GB RAM, 40GB disk):

```bash
multipass launch --name k8s-demo --cpus 4 --memory 8G --disk 40G
```

Check that the VM is running and **note the IP address** — you'll need it later:

```bash
multipass list
# Example output:
# Name       State    IPv4             Image
# k8s-demo   Running  192.168.64.2     Ubuntu 22.04 LTS
```

## Step 2: Install MicroK8s

Open a shell in the VM:

```bash
multipass shell k8s-demo
```

Run the following commands **inside the VM** to install MicroK8s:

```bash
# 1. Install MicroK8s
sudo snap install microk8s --classic

# 2. Set permissions for the current user (so we don't need sudo every time)
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube

# 3. Reload the group (or log out and back in)
newgrp microk8s

# 4. Check the status
microk8s status --wait-ready
```

Set up an alias for `kubectl` (optional, but recommended):

```bash
alias kubectl='microk8s kubectl'
```

## Step 3: Enable addons & MetalLB

To use `LoadBalancer` services (and not just NodePort), we need MetalLB.

1. Enable DNS and MetalLB:

    ```bash
    microk8s enable dns metallb
    ```

2. You will now be asked for an **IP address range**.
    - Look at your VM's IP (see step 1, e.g. `192.168.64.2`).
    - Choose a range from the same subnet that is _not_ assigned by DHCP.
    - Example: If your VM has `192.168.64.2`, use the range: `192.168.64.200-192.168.64.210`

## Step 4: Deploy the test application

We use the prepared file `test-app.yaml` (nginx Deployment + Service).

The file lives on your Mac, so we first need to get it into the VM or create it there. **Option A (transfer the
file):** On your Mac (in a new terminal):

```bash
# Adjust the path if you are in a different directory
multipass transfer demos/09-multipass-microk8s/test-app.yaml k8s-demo:
```

**Option B (copy & paste):** Create the file directly in the VM with `nano test-app.yaml`.

**Apply the deployment (in the VM):**

```bash
microk8s kubectl apply -f test-app.yaml
```

## Step 5: Test

Give the pods a moment to start, then check the service:

```bash
microk8s kubectl get svc nginx-service
```

You should now see an **EXTERNAL-IP** (e.g. `192.168.64.200`) coming from the range you configured for MetalLB.

**Access from your Mac:** Open your browser on the Mac and enter the external IP: `http://192.168.64.200`. You should
see the "Welcome to nginx!" page.

## Cleanup

When you are done, you can stop or delete the VM:

```bash
# Stop
multipass stop k8s-demo

# Delete (everything gone!)
multipass delete k8s-demo
multipass purge
```
