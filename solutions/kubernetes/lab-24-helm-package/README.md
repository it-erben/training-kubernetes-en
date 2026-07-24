# Solution: Helm helpers, conditionals, and reusable charts

Reference solution for the evolved nginx chart. It lives in the `my-nginx-chart-v2` subfolder and adds a
`fullname` helper, `dict`-parameterized names, release-name prefixing, and an optional Service on top of
the Lab 23 chart.

## Render and lint

```bash
helm template nc ./my-nginx-chart-v2
helm lint ./my-nginx-chart-v2
```

## Prove the Service toggle

```bash
helm template nc ./my-nginx-chart-v2 | grep -c "kind: Service"                        # 1
helm template nc ./my-nginx-chart-v2 --set service.enabled=false | grep -c "kind: Service"  # 0
```

## Prove the isolation

Two releases of the prefixed chart coexist in one namespace, because every resource name carries the
release name:

```bash
helm install web1 ./my-nginx-chart-v2 --namespace demo --create-namespace
helm install web2 ./my-nginx-chart-v2 --namespace demo
kubectl get deploy -n demo   # web1-web, web2-web
```

Cleanup:

```bash
helm uninstall web1 web2 --namespace demo
kubectl delete namespace demo
```
