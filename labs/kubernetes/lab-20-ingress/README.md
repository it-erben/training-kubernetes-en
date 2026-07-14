# Lab 20: Ingress on Minikube

This lab demonstrates how to use an Ingress to route HTTP traffic to different Services based on hostnames and
paths. The Ingress is the classic layer-7 entry point into the cluster: a single endpoint with any number of
Services behind it.

## Learning Goals

After this lab you will be able to:

- enable the Ingress addon in Minikube and check the Ingress controller,
- create an Ingress that routes by **host**,
- split an Ingress across multiple Services by **path** (fanout),
- test external access via tunnel or `minikube ip`,
- recognize and fix typical errors (`Connection reset`, wrong `curl`).

## Prerequisites

Enable the Ingress addon in Minikube:

```bash
minikube addons enable ingress
```

Check that the controller is running before you continue:

```bash
kubectl get pods -n ingress-nginx
```

The pod `ingress-nginx-controller-...` must be `Running` and `READY 1/1`.

## 1. Start the Application

**`01-deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-demo
  labels:
    app: nginx-ingress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-ingress
  template:
    metadata:
      labels:
        app: nginx-ingress
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
                command: ["/bin/sh", "-c", "echo \"Hello from $(hostname)\" > /usr/share/nginx/html/index.html"]
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

> **Note:** Each pod writes its own hostname into the `index.html` on startup. This way you can see
> directly during testing which of the two pods answered your request – handy for observing load balancing.

**`02-service.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-svc
spec:
  selector:
    app: nginx-ingress
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

**`03-ingress.yaml`:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    # This instructs the default NGINX controller (important for Minikube)
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-ingress-svc
            port:
              number: 80
```

Apply all YAML files in this folder:

```bash
kubectl apply -f .
```

## 2. Inspect the Ingress

Before you test, take a look at what Kubernetes made of your manifest:

```bash
kubectl get ingress
kubectl describe ingress nginx-ingress
```

Pay attention to two things:

- The `ADDRESS` column must show an IP after a short while. If it stays empty, the controller is not ready yet.
- Under `Rules` in the `describe` output you can see the mapping `Host → Path → Service:Port`. This is exactly the
  rule the controller evaluates on every request.

## 3. Test Access

Since we defined a hostname (`nginx.example.com`), we have to make sure it resolves to the IP of the
Ingress controller.

### Method A: Minikube Tunnel (Recommended for Mac/Windows)

Start the tunnel in a separate terminal. It ensures that Services of type LoadBalancer (which the Ingress
controller uses) get an IP, and it routes traffic.

```bash
minikube tunnel
```

Then add the entry to your `/etc/hosts` (sudo required) so that `nginx.example.com` points to `127.0.0.1`,
OR test directly with curl:

```bash
curl --resolve nginx.example.com:80:127.0.0.1 http://nginx.example.com
```

> **Windows (PowerShell):** `curl` is an alias for `Invoke-WebRequest` and does not know `--resolve`.
> Use `curl.exe` instead. On macOS/Linux, `curl` works directly.
>
> ```powershell
> curl.exe --resolve nginx.example.com:80:127.0.0.1 http://nginx.example.com
> ```

Repeat the request several times: sometimes `nginx-ingress-demo-...-abcde` answers, sometimes another pod – that
is the Service's load balancing.

### Method B: Minikube IP (Linux)

```bash
echo "$(minikube ip) nginx.example.com" | sudo tee -a /etc/hosts
curl http://nginx.example.com
```

### Troubleshooting

- **`curl: (56) Connection was reset`** – the tunnel is not running or not running as admin.
  Start `minikube tunnel` as administrator in a separate terminal.
- **`Invoke-WebRequest: ... --resolve` (PowerShell)** – `curl` is just an alias.
  Use `curl.exe` instead of `curl`.
- **`ADDRESS` in `kubectl get ingress` stays empty** – the controller is not ready yet.
  Check `kubectl get pods -n ingress-nginx`.
- **`404 Not Found` from the NGINX controller** – the Host header does not match the `host:` rule.
  `--resolve` sets the host correctly.

As a robust alternative to the tunnel (especially on Windows with the Docker driver), you can reach the controller
via port-forward:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
curl.exe --resolve nginx.example.com:8080:127.0.0.1 http://nginx.example.com:8080
```

## 4. Task: Path-Based Routing (Fanout)

A single Ingress can distribute traffic to different Services based on the **path**. This is the typical
fanout pattern: `example.com/shop` goes to Service A, `example.com/blog` to Service B.

Your task:

1. Create a **second** Deployment plus Service (e.g. `nginx-blog` / `nginx-blog-svc`). Use `nginx:1.29.4` again
   and write a recognizable text into the `index.html` via `postStart` (e.g. `Hello from the BLOG`).
2. Extend `03-ingress.yaml` so that two paths exist under the same host `nginx.example.com`:
   - `/shop` → existing `nginx-ingress-svc`
   - `/blog` → new `nginx-blog-svc`
3. Apply everything and test both paths:

   ```bash
   curl --resolve nginx.example.com:80:127.0.0.1 http://nginx.example.com/shop
   curl --resolve nginx.example.com:80:127.0.0.1 http://nginx.example.com/blog
   ```

**Tip:** The `rules` block can contain multiple `paths` entries. With the annotation
`nginx.ingress.kubernetes.io/rewrite-target: /`, the path prefix is stripped before forwarding to the backend
service – otherwise the NGINX in the container would receive the URL `/shop` and return a 404.

### Solution Sketch for the Ingress

Only look after trying it yourself:

```yaml
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.example.com
    http:
      paths:
      - path: /shop
        pathType: Prefix
        backend:
          service:
            name: nginx-ingress-svc
            port:
              number: 80
      - path: /blog
        pathType: Prefix
        backend:
          service:
            name: nginx-blog-svc
            port:
              number: 80
```

## 5. Cleanup

```bash
kubectl delete -f .
```

You can leave the Ingress addon running or disable it again with `minikube addons disable ingress`.
