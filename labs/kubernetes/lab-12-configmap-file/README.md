# Lab 12: Delivering Configuration Files with ConfigMaps

Storing small, static files in ConfigMaps and handing them to pods is a pretty common pattern. In this
example we use a ConfigMap to serve a start page for an NGINX pod. In the real world, this might be
a page that a readiness probe hits.

This is a build-it-yourself lab: you get the ConfigMap for free, but you write the pod YAML. The
walkthrough below takes you through it piece by piece. A full solution is at the very bottom if you
get stuck.

## Step 1: Create the ConfigMap

The ConfigMap with the HTML page looks like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-index-config
data:
  index.html: |
    <html>
    <head>
        <title>Welcome to NGINX</title>
    </head>
    <body>
        <h1>Hello World!</h1>
        <p>This is a custom start page for the NGINX server.</p>
    </body>
    </html>
```

Save it to a file (for example `configmap.yaml`) and apply it:

```bash
kubectl apply -f configmap.yaml
```

Note two things you'll refer back to later:

- The ConfigMap is named `nginx-index-config` (`metadata.name`).
- It has one key, `index.html`, under `data`. That key name becomes a filename when we mount it.

## Step 2: Build the pod

Now write a pod YAML (for example `pod.yaml`) for an NGINX pod that serves the `index.html` from the
ConfigMap as its start page. The pod is made of four pieces. Build them up in this order.

### a) The pod and its label

Start with the skeleton. The important part beyond the usual `metadata.name` is the **label** — the
service you create in step 3 will use it to find this pod, so it has to be there:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx        # the service will select on this label
spec:
  containers:
    # ... container goes here (part b) ...
  volumes:
    # ... volume goes here (part d) ...
```

### b) The NGINX container

Inside `spec.containers`, add a single container running NGINX and exposing port 80:

```yaml
- name: nginx
  image: nginx:1.29.4
  ports:
    - containerPort: 80
```

### c) Mounting the file (`volumeMounts`)

Still inside the container, add a `volumeMounts` entry. This is the piece you were given as a template:

```yaml
volumeMounts:
  - name: nginx-index-volume
    mountPath: /usr/share/nginx/html/index.html
    subPath: index.html
```

What each line does:

- `mountPath` is the exact file NGINX serves as its start page.
- `subPath: index.html` says "mount **only** the `index.html` key as a single file." Without `subPath`,
  Kubernetes would replace the **whole** `/usr/share/nginx/html` directory with the ConfigMap contents,
  wiping out everything else NGINX ships there. `subPath` keeps the rest of the directory intact.
- `name: nginx-index-volume` is a reference — it points at a volume you still have to declare. That's part d.

### d) Declaring the volume (`volumes`)

`volumeMounts` only *references* a volume by name; you also have to *declare* that volume at the pod
level under `spec.volumes`. This is the block that connects everything to the ConfigMap:

```yaml
volumes:
  - name: nginx-index-volume        # must match volumeMounts[].name in part c
    configMap:
      name: nginx-index-config      # must match the ConfigMap's metadata.name from step 1
```

The two name-matches are where this lab most often goes wrong, so check them carefully:

1. `volumes[].name` (`nginx-index-volume`) must be **identical** to the `name` under `volumeMounts` in
   part c. That's the wire connecting the container's mount to the pod's volume.
2. `configMap.name` (`nginx-index-config`) must be **identical** to the ConfigMap's `metadata.name` from
   step 1. That's what fills the volume with your `index.html`.

Put parts a–d together into one `pod.yaml` and apply it:

```bash
kubectl apply -f pod.yaml
```

Check that the pod comes up:

```bash
kubectl get pod nginx-pod
```

Once it's `Running`, move on to exposing it.

## Step 3: Expose the pod with a service

### For Minikube

Create a NodePort service named `nginx-service` that forwards to the pod. Then open a tunnel to it and
check that the HTML page shows up:

```bash
minikube service nginx-service
```

### For EKS and AKS

Create a service of type LoadBalancer named `nginx-service` that forwards to the pod via labels:

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
  type: LoadBalancer
```

**Important**: the selector (`app: nginx`) must match the label you put on the pod in part a. If the
page never loads, a mismatched selector is the first thing to check.

Then look up the external IP of the LoadBalancer:

```bash
kubectl get svc nginx-service
```

It can take a little while for the external IP to be provisioned.

## Cleaning up

```bash
kubectl delete pod nginx-pod
kubectl delete service nginx-service
kubectl delete configmap nginx-index-config
```

## Full solution

Try to assemble the pod yourself first. If you're stuck, here's a complete `pod.yaml` to compare against.

**`pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.29.4
      ports:
        - containerPort: 80
      volumeMounts:
        - name: nginx-index-volume
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
  volumes:
    - name: nginx-index-volume
      configMap:
        name: nginx-index-config
```

### Bonus

- The intro mentioned readiness probes. As an extra challenge, add a `readinessProbe` that does an
  `httpGet` on `/` (port 80) so Kubernetes only marks the pod ready once the page actually serves.
- [https://kubernetes.io/docs/concepts/configuration/configmap/](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [https://kubernetes.io/docs/concepts/storage/volumes/#configmap](https://kubernetes.io/docs/concepts/storage/volumes/#configmap)
