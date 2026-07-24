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

```bash
helm install web1 ./my-nginx-chart-v2 --namespace demo-a --create-namespace
helm install web2 ./my-nginx-chart-v2 --namespace demo-b --create-namespace
kubectl get deploy -n demo-a   # web1-web
kubectl get deploy -n demo-b   # web2-web
```

Cleanup:

```bash
helm uninstall web1 --namespace demo-a
helm uninstall web2 --namespace demo-b
kubectl delete namespace demo-a demo-b
```
