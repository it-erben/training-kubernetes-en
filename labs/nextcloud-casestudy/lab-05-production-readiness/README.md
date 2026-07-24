# Making MariaDB and Nextcloud production-ready

A few pieces are still missing before MariaDB and Nextcloud are fit for production.
Let's add them to wrap up this case study.

## Requests and limits

> **Docs:** [Resource Requests & Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

Every pod in a Kubernetes cluster should define resource requests and limits.

> Note (Minikube): the values below are production-scale. The whole stack requests
> roughly 2.5 CPU and 6.5Gi of memory, which does not fit a default Minikube VM.
> Start Minikube with more headroom first, or the pods stay `Pending` with
> `FailedScheduling`:
>
> ```shell
> minikube start --cpus 4 --memory 8192
> ```
>
> On a small machine, scale the requests below down instead.

Set the following for MariaDB:

```yaml
resources:
  requests:
    cpu: "1000m"
    memory: "4Gi"
  limits:
    cpu: "1000m"
    memory: "4Gi"
```

For Nextcloud, set the following values:

```yaml
resources:
  requests:
    cpu: "1000m"
    memory: "2Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
```

## Readiness probes

> **Docs:**
>
> - [Liveness, Readiness & Startup Probes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/)
> - [Configuring probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

Pods should define a readiness probe for self-healing. For MariaDB, the simplest readiness
probe looks like this:

```yaml
readinessProbe:
  tcpSocket:
    port: 3306
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 1
```

For Nextcloud, the following probe makes sense:

```yaml
readinessProbe:
  httpGet:
    path: /status.php
    port: http
  periodSeconds: 10
  timeoutSeconds: 2
  failureThreshold: 1
```

Add a `livenessProbe` on the same `/status.php` endpoint too. Give it a higher
`failureThreshold` than the readiness probe so a slow-but-alive pod is dropped
from the Service before it gets restarted. Use `tcpSocket` on port 3306 for
MariaDB and `httpGet /status.php` for Nextcloud.

## Ingress

> **Docs:**
>
> - [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
> - [Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

In production, a service usually also needs an Ingress or
a Gateway. Here, only Nextcloud needs one.

> Note (Minikube): Before applying, enable the NGINX ingress controller addon:
>
> ```shell
> minikube addons enable ingress
> ```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nextcloud
  namespace: nextcloud
  annotations:
    # Reasonable defaults for typical Nextcloud use; students can tune:
    nginx.ingress.kubernetes.io/proxy-body-size: "2g"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  rules:
    - host: nextcloud.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nextcloud
                port:
                  number: 80
```

## PodDisruptionBudget

> **Docs:**
>
> - [PodDisruptionBudget](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
> - [Configuring a PDB](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)

During Deployment rollouts and node drains alike, neither Nextcloud nor
MariaDB should drop below their minimum number of available pods.
`unhealthyPodEvictionPolicy: AlwaysAllow` still lets a broken pod be evicted:
with a single replica and `minAvailable: 1`, an unhealthy pod would otherwise
block every node drain.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nextcloud-pdb
  namespace: nextcloud
spec:
  minAvailable: 1
  unhealthyPodEvictionPolicy: AlwaysAllow
  selector:
    matchLabels:
      app: nextcloud

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nextcloud-db-pdb
  namespace: nextcloud
spec:
  minAvailable: 1
  unhealthyPodEvictionPolicy: AlwaysAllow
  selector:
    matchLabels:
      app: nextcloud-db
```
