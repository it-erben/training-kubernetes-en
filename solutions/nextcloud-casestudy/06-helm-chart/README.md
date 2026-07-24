# Solution: Nextcloud packaged as a Helm chart

The `nextcloud-chart/` directory templatizes the production-ready stack from lab 05. Its name helper
keeps every resource name within Kubernetes' 63-character limit, and no template hardcodes a
namespace. `ingress.className` and `ingress.annotations` are optional and have no cluster-specific
defaults.

`phpmyadmin.yaml` and `ingress.yaml` comment their guards as `# {{- if ... }}`. The lab teaches the
bare `{{- if ... }}` form; the leading `#` here keeps the raw template a valid YAML document so the
repo's yamllint and kube-linter jobs can parse the file. The engine trims the whitespace after the
`#` and the guard fires as normal, leaving only an inert comment line in the rendered output.

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
