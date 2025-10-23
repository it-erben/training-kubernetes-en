# Delivering Configuration Files with ConfigMaps

It is common practice to store compact and static files within **ConfigMaps** and make them available to Pods. In this example, we'll use a ConfigMap to deliver a custom starting page for an NGINX Pod. In reality, this could be a page that a readiness check monitors.

## Create the ConfigMap

The ConfigMap containing the HTML page looks like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-index-config
data:
  index.html: |
    <html>
    <head>
        <title>Willkommen bei NGINX</title>
    </head>
    <body>
        <h1>Hallo, Welt!</h1>
        <p>Dies ist eine benutzerdefinierte Startseite für den NGINX-Server.</p>
    </body>
    </html>
```

**Save this YAML** content to a file and **apply it** using `kubectl`.

**Next, create a YAML file for a Pod** that mounts the ConfigMap above as a Volume, making it available as the NGINX starting page. Use the following mount configuration as a template:

```yaml
volumeMounts:
  - name: nginx-index-volume
    mountPath: /usr/share/nginx/html/index.html
    subPath: index.html
```

Finally, **create a NodePort Service** named **`nginx-service`** that forwards traffic to the Pod.

Use the following command to open a tunnel to the Service and test whether the HTML page appears:

```yaml
minikube service nginx-service
```
