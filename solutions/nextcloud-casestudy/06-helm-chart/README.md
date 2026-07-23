# Solution: Nextcloud packaged as a Helm chart

The `nextcloud-chart/` directory templatizes the production-ready stack from lab 05. Every resource
name is prefixed with `{{ .Release.Name }}` and no template hardcodes a namespace, so the chart can
be installed into any namespace — any number of times — without collisions.

## Inspect and lint

```bash
helm lint ./nextcloud-chart
helm template nc ./nextcloud-chart
```

## Install into a fresh namespace

```bash
helm install nc ./nextcloud-chart --namespace nextcloud-helm --create-namespace
kubectl get all,pvc,ingress -n nextcloud-helm
```

Reach Nextcloud via port-forward:

```bash
kubectl -n nextcloud-helm port-forward svc/nc-nextcloud 8080:80
```

Then open <http://localhost:8080>.

## Reconfigure without editing files

```bash
helm upgrade nc ./nextcloud-chart --namespace nextcloud-helm --set phpmyadmin.enabled=false
```

## Prove isolation (optional)

```bash
helm install nc2 ./nextcloud-chart --namespace nextcloud-helm-2 --create-namespace
```

Both releases run the same chart with `Release.Name`-prefixed resources, so nothing collides.

## Cleanup

```bash
helm uninstall nc --namespace nextcloud-helm
kubectl delete namespace nextcloud-helm
```
