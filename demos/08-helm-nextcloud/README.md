# Demo: Complex Nextcloud stack as a Helm chart

This demo shows how to bundle a more complex application consisting of multiple microservices (Nextcloud, database,
admin tool) into a single Helm chart.

It is based on the result of the exercise `assignments/kubernetes/lab-13-casestudy-nextcloud`.

## Chart structure

The chart `nextcloud-chart` contains templates for:

1. **Database (MariaDB):** A StatefulSet for database persistence.
2. **Nextcloud:** The actual application as a Deployment.
3. **PhpMyAdmin:** An optional admin interface (can be enabled via `values.yaml`).
4. **Secrets:** Central management of credentials.
5. **Services:** Networking between the components.

Highlights:

- **Release names:** All resources use `{{ .Release.Name }}` as a prefix to avoid naming conflicts when the chart is
  installed multiple times.
- **Conditional installation:** PhpMyAdmin can be switched on or off via `phpmyadmin.enabled`.
- **Central configuration:** Passwords and images are maintained centrally in `values.yaml`.

## Usage

### 1. Check the chart (dry run)

```bash
helm template my-nc ./nextcloud-chart
```

### 2. Install

Install the stack into a new namespace:

```bash
kubectl create namespace nc-demo
helm install my-nc ./nextcloud-chart --namespace nc-demo
```

### 3. Change the configuration (upgrade)

Disable PhpMyAdmin and change the Nextcloud service type to ClusterIP:

```bash
helm upgrade my-nc ./nextcloud-chart --namespace nc-demo \
  --set phpmyadmin.enabled=false \
  --set nextcloud.service.type=ClusterIP
```

### 4. Uninstall

```bash
helm uninstall my-nc --namespace nc-demo
kubectl delete namespace nc-demo
```
