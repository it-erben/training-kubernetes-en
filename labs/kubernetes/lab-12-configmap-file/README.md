# Lab 12: Delivering Configuration Files with ConfigMaps

Storing small, static files in ConfigMaps and handing them to pods is a pretty common pattern. In this
example we use a ConfigMap to serve a start page for an NGINX pod. In the real world, this might be
a page that a readiness probe hits.

## Creating the ConfigMap

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

Save it to a file and apply it with kubectl. Now create a YAML file with a pod that mounts the above
ConfigMap as a volume and makes it available as the NGINX start page. Use this mount as a template:

```yaml
volumeMounts:
  - name: nginx-index-volume
    mountPath: /usr/share/nginx/html/index.html
    subPath: index.html
```

## Test: For Minikube

Finally, create a NodePort service named "nginx-service" that forwards to the pod. Use the following command
to open a tunnel to the service and check that the HTML page shows up:

```yaml
minikube service nginx-service
```

## Test: For EKS and AKS

Create a service of type LoadBalancer named "nginx-service" that forwards to the pod above via labels:

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

**Important**: Make sure the label selector matches the pod's labels!
Then you can look up the external IP of the LoadBalancer with:

```bash
kubectl get svc nginx-service
```

It can take a little while for the external IP to be provisioned.
