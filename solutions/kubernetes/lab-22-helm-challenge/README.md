# Solution: Helm kube-prometheus-stack

- Add the repo: `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- Update the repos: `helm repo update`
- Find the version: `helm search repo prometheus-community/kube-prometheus-stack`
- Install (default namespace or your own): `helm install monitoring prometheus-community/kube-prometheus-stack`
- List the installed releases: `helm list -A`
- Locate the service: `kubectl get svc -A | grep prometheus-operated`
- Port-forward: `kubectl port-forward svc/prometheus-operated 8080:9090`
- Open the dashboard: `http://localhost:8080`
- Clean up: stop `kubectl port-forward`, then `helm uninstall monitoring`
