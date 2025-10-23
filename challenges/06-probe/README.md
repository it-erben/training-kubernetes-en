# Challenge: Pod Probes and Lifecycle Configuration

## Setup

* **Draft a YAML manifest** for a Pod named **`web-server`** that utilizes the **`nginx:1.23.0`** image and exposes container port **80**.
* ***Do not deploy the Pod yet.***

## Probe Configuration

Within the container definition, configure three distinct health probes, all using the **`httpGet`** action against the **root context endpoint (`/`)**:

1.  **Startup Probe:** Declare a **Startup Probe** using the default configuration settings.
2.  **Readiness Probe:** Implement a **Readiness Probe** that waits **five seconds** before checking the endpoint for the first time.
3.  **Liveness Probe:** Define a **Liveness Probe** that enforces an initial delay of **10 seconds** before the first check and runs subsequent checks every **30 seconds**.

## Execution and Verification

* **Deploy the Pod** using your completed YAML manifest.
* **Monitor the Pod's lifecycle phases** as it starts up.
* **Inspect the runtime details and events** to verify the successful configuration and activation of the Pod’s probes.
