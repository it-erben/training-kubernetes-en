# Lab 14: Challenge: Pod Probes and Lifecycle Configuration

## Preparation

- Create a YAML manifest for a pod named `web-server` that uses the image `nginx:1.29.4` and exposes container port 80.
- **Do not deploy the pod yet.**
- Create a matching Service for it

## Probe Configuration

Within the container specification, define two different health probes, both using the `httpGet` action against
the root endpoint (`/`):

1. Readiness probe: Implement a readiness probe that waits five seconds before checking the endpoint for the first
    time.
2. Liveness probe: Define a liveness probe that uses an initial delay of 10 seconds before the first check and
    then checks every 30 seconds.

## Execution and Verification

- Deploy the pod with your finished YAML manifest.
- Observe the pod's lifecycle phases during startup.
- Use `kubectl describe` to verify that the configured probes are active.
- Then deliberately introduce an error into your probes (wrong path), roll out the change, and observe what happens.
