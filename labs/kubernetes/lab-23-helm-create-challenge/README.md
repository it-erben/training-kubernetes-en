# Lab 23: Challenge: Create a Helm Chart from Scratch

In this challenge you will create your own Helm chart from scratch.

The goal is to package a Deployment for a web server (NGINX) and a matching Service. Certain values should be
configurable via the `values.yaml`.

---

## Preparation: Folder Structure

A Helm chart is basically just a directory structure with text files. Create the following folder structure
in your working directory:

```text
my-nginx-chart/
└── templates/
```

---

## Task 1: Metadata (Chart.yaml)

Every Helm chart needs a `Chart.yaml` with metadata about the chart. Create the file
`my-nginx-chart/Chart.yaml` with the following content:

```yaml
apiVersion: v2
name: my-nginx
description: A simple Nginx Helm chart
type: application
version: 0.1.0
appVersion: "1.16.0"
```

---

## Task 2: Configuration (values.yaml)

The `values.yaml` defines the default values our templates will use. Create a file
`my-nginx-chart/values.yaml` with the following content:

```yaml
# Define the number of replicas here
replicaCount: 2

service:
  # Define the type here (ClusterIP or NodePort)
  type: ClusterIP
  port: 80
```

This makes the following settings configurable:

1. **Replica count:** The number of pods should be configurable (default: `2`).
2. **Service type:** The type of the Kubernetes Service should be configurable (e.g. `ClusterIP` or
    `NodePort`; default: `ClusterIP`).

---

## Task 3: Deployment Template

Now for the Deployment template. Create the file `my-nginx-chart/templates/deployment.yaml`.

**Requirements:**

- Use a standard Kubernetes Deployment for `nginx`.
- Replace the hard-coded `replicas` with the value from your `values.yaml`. The syntax is
  `{{ .Values.replicaCount }}`.

Your file could look something like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.29.4
        ports:
          - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 20
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

---

## Task 4: Service Template

Create the file `my-nginx-chart/templates/service.yaml`.

**Requirements:**

- Create a Service that points to the Deployment.
- The `type` of the Service (e.g. `ClusterIP` or `NodePort`) must be loaded dynamically from the values
  (`{{ .Values.service.type }}`).

Here is an example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: {{ .Values.service.type }}
```

---

## Task 5: Test and Install

1. **Validation (dry run):** Look at what Helm would generate without installing anything. This helps you
    catch syntax errors.

    ```bash
    helm template ./my-nginx-chart
    ```

    Check the output to make sure your placeholders were replaced with the values from `values.yaml`.

2. **Installation:** Install the chart into your cluster.

    ```bash
    helm install my-webserver ./my-nginx-chart
    ```

3. **Test the configurability:** Now run an upgrade that overrides values (e.g. 3 replicas and
    NodePort) without touching the files:

    ```bash
    helm upgrade my-webserver ./my-nginx-chart --set replicaCount=3 --set service.type=NodePort
    ```

4. **Verification:** Use `kubectl get all` to check whether 3 pods are now running and the Service is of type NodePort.

---

## Bonus Task

Also make the NGINX image tag configurable as a Helm value.
