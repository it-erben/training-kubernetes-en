# Lab 21: Gateway API on Minikube

This lab shows how to use the new Kubernetes Gateway API. Unlike the Ingress controller, it is not
enabled in Minikube by default.

We use **NGINX Gateway Fabric** as the implementation.

## 1. Install the CRDs and the Controller

Before applying the YAML files, we need to install the Gateway API CRDs (Custom Resource Definitions) and an
implementation.

1. **Install the Gateway API CRDs:**

    ```bash
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
    ```

2. **Install NGINX Gateway Fabric:** The easiest way is via Helm (make sure Helm is installed):

    ```bash
    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway
    ```

    _Wait a moment until the pod in the `nginx-gateway` namespace is running._

## 2. Start the Application

**`01-deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-gateway-demo
  labels:
    app: nginx-gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-gateway
  template:
    metadata:
      labels:
        app: nginx-gateway
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
          lifecycle:
            postStart:
              exec:
                command: ["/bin/sh", "-c", "echo 'Hello from Gateway API' > /usr/share/nginx/html/index.html"]
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
      volumes:
        - name: html
          emptyDir: {}
```

**`02-service.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-gateway-svc
spec:
  selector:
    app: nginx-gateway
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

**`03-gateway.yaml`:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

**`04-httproute.yaml`:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - "gateway.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx-gateway-svc
      port: 80
```

Now apply the resources:

```bash
kubectl apply -f .
```

This creates:

- Deployment & Service (the app)
- Gateway (the LoadBalancer/entry point)
- HTTPRoute (the routing rule)

## 3. Test Access

The Gateway provisions a Service of type `LoadBalancer`. To reach it on Minikube, we use the
tunnel again.

1. **Start the tunnel (if not already running):**

    ```bash
    minikube tunnel
    ```

2. **Find the Gateway's IP:** Check the Gateway object (with the tunnel running, it should be
    127.0.0.1 or a Minikube IP):

    ```bash
    kubectl get gateway my-gateway
    ```

3. **Send a request** using `curl` with the expected hostname:

    ```bash
    curl --resolve gateway.example.com:80:127.0.0.1 http://gateway.example.com
    ```

    > **Windows (PowerShell):** `curl` is an alias for `Invoke-WebRequest` and does not know `--resolve`.
    > Use `curl.exe` instead. On macOS/Linux, `curl` works directly.
    >
    > ```powershell
    > curl.exe --resolve gateway.example.com:80:127.0.0.1 http://gateway.example.com
    > ```

    _(Replace 127.0.0.1 with the IP from step 2 if it differs)_

    You should see "Hello from Gateway API".
