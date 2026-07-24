# Nextcloud Stage 6: Package the stack as a Helm chart

Across labs 01–05 you built a working Nextcloud stack: a MariaDB StatefulSet,
Secrets, phpMyAdmin, the Nextcloud Deployment with persistent storage, plus resource limits,
probes, an Ingress, and PodDisruptionBudgets. Every one of those manifests hardcodes
`namespace: nextcloud` and fixed resource names.

In this lab you turn that pile of manifests into a single Helm chart and install it into a
brand-new namespace. The payoff: one command installs the whole stack. The chart has no
hardcoded namespace and prefixes every name with the release name, so you can install it
anywhere, even twice, without conflicts.

> **Docs:**
>
> - [Helm charts](https://helm.sh/docs/topics/charts/)
> - [Chart template guide](https://helm.sh/docs/chart_template_guide/)
> - [Built-in objects (`.Release`, `.Values`)](https://helm.sh/docs/chart_template_guide/builtin_objects/)
>
> **Shells:** the `helm` and `kubectl` commands below are identical on Windows, macOS, and Linux.
> Where a command differs (e.g. `curl`), both a Bash and a PowerShell variant are shown.

---

## Part 0: Chart skeleton

A Helm chart is just a directory of text files. Create this structure in your working directory:

```text
nextcloud-chart/
├── Chart.yaml
├── values.yaml
└── templates/
```

`Chart.yaml` is boilerplate metadata. Use this as-is:

```yaml
apiVersion: v2
name: nextcloud-chart
description: A production-ready Helm chart for Nextcloud with MariaDB and phpMyAdmin
type: application
version: 0.1.0
appVersion: "27.1.4"
```

---

## Part 1: values.yaml

`values.yaml` holds the settings your templates read via `{{ .Values.<key> }}`. Decide what should
be configurable and give each a sensible default. At minimum, cover the images, the storage sizes,
the database credentials, and switches for the optional pieces. Here is a starting point:

```yaml
database:
  image: mariadb:11.4.2
  rootPassword: mysecretpassword
  user: nextcloud
  password: nextcloudpassword
  dbName: nextcloud
  storage: 10Gi
  # ...add resource requests/limits here

nextcloud:
  image: nextcloud:27.1.4
  dataStorage: 20Gi
  configStorage: 1Gi
  trustedDomains: "nextcloud.local localhost 127.0.0.1"
  # ...add resource requests/limits here

phpmyadmin:
  enabled: true
  image: phpmyadmin:5.2.1
  # ...add resource requests/limits here

ingress:
  enabled: true
  host: nextcloud.local
  # Set this only when the cluster requires a specific IngressClass.
  className: ""
  # Add controller-specific annotations only when required.
  annotations: {}
```

---

## Part 2: Templatize each resource

Create one file under `templates/` per component, copying in the manifest you already wrote and
applying two transformations to every resource:

1. Delete the `namespace: nextcloud` line. You choose the namespace at install time, not in the
   chart.
2. Define a name helper in `templates/_helpers.tpl`. It must preserve the suffix while truncating
   long release names to 63 characters. Use it for every resource name and reference.

   ```yaml
   {{- define "nextcloud-chart.fullname" -}}
   {{- $name := .name | trunc 63 | trimSuffix "-" -}}
   {{- $prefixLength := sub 62 (len $name) | int -}}
   {{- printf "%s-%s" (.root.Release.Name | trunc $prefixLength | trimSuffix "-") $name -}}
   {{- end -}}
   ```

Suggested files and names:

| File | Resources | Helper suffixes |
| --- | --- | --- |
| `templates/secret.yaml` | app + root Secrets | `db-app`, `db-root` |
| `templates/mariadb.yaml` | StatefulSet + Services | `db`, `db-clusterip` |
| `templates/nextcloud.yaml` | Deployment + PVCs + Service | `nextcloud`, `nextcloud-data`, `nextcloud-config` |
| `templates/phpmyadmin.yaml` | Deployment + Service | `phpmyadmin` |
| `templates/ingress.yaml` | Ingress | `nextcloud` |
| `templates/pdb.yaml` | PodDisruptionBudgets | `db-pdb`, `nextcloud-pdb` |

Watch the cross-references. When a name becomes templated, everything pointing at it must use
the same template. For example the Secret reference in the MariaDB container:

```yaml
env:
  - name: MYSQL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: "{{ include `nextcloud-chart.fullname` (dict `root` . `name` `db-app`) }}"
        key: MYSQL_PASSWORD
```

and move the image out to a value:

```yaml
image: "{{ .Values.database.image }}"
```

Do the same for these easy-to-miss references:

- the StatefulSet's `serviceName` (must equal the headless Service name),
- Nextcloud's and phpMyAdmin's `MYSQL_HOST` / `PMA_HOST` (point them at the helper-generated
  `db-clusterip` name),
- each Service `selector` and the matching pod labels,
- the Nextcloud volumes' `claimName` values,
- the Ingress backend service name and the PDB `selector` labels.

---

## Part 3: Make phpMyAdmin and the Ingress optional

phpMyAdmin is a convenience, not a production requirement, and not every cluster has an Ingress
controller. Wrap those templates so they render only when enabled. Guard the entire
`phpmyadmin.yaml` file:

```yaml
{{- if .Values.phpmyadmin.enabled }}
# ...all phpMyAdmin resources...
{{- end }}
```

Do the same in `ingress.yaml` with `{{- if .Values.ingress.enabled }} ... {{- end }}`. Render
`spec.ingressClassName` only when `ingress.className` is non-empty.
Render `metadata.annotations` from `ingress.annotations` only when it contains values.

---

## Part 4: Dry-run and lint

Render the chart locally, no cluster needed, and read the output to confirm your
placeholders were filled in:

```bash
helm template nc ./nextcloud-chart
```

Then lint it:

```bash
helm lint ./nextcloud-chart
```

Fix any errors before installing. Try toggling a switch to see the effect:

```bash
helm template nc ./nextcloud-chart --set phpmyadmin.enabled=false | grep -c "kind: Deployment"
```

> **Windows (PowerShell):**
>
> ```powershell
> (helm template nc ./nextcloud-chart --set phpmyadmin.enabled=false | Select-String "kind: Deployment").Count
> ```

You should see one fewer Deployment.

---

## Part 5: Install into a new namespace

This is the whole point. Install the chart into a namespace that does not exist yet. Helm creates
it for you:

```bash
helm install nc ./nextcloud-chart --namespace nextcloud-helm --create-namespace
```

Watch it come up:

```bash
kubectl get all,pvc,ingress -n nextcloud-helm
```

Reach Nextcloud with a port-forward:

```bash
kubectl -n nextcloud-helm port-forward svc/nc-nextcloud 8080:80
```

Then request it from a second terminal:

```bash
curl http://localhost:8080
```

> **Windows (PowerShell):**
>
> ```powershell
> curl.exe http://localhost:8080
> ```

You should get Nextcloud's HTML. (For the full Ingress path instead of a port-forward, run
`minikube addons enable ingress`, add `nextcloud.local` to your hosts file pointing at
`minikube ip`, and browse to `http://nextcloud.local/`.)

---

## Part 6: Reconfigure with an upgrade

Change configuration without touching any file. Helm re-renders and applies the difference:

```bash
helm upgrade nc ./nextcloud-chart --namespace nextcloud-helm --set phpmyadmin.enabled=false
```

Check that the phpMyAdmin Deployment is gone:

```bash
kubectl get deploy -n nextcloud-helm
```

---

## Part 7: Cleanup

```bash
helm uninstall nc --namespace nextcloud-helm
kubectl delete namespace nextcloud-helm
```

---

## Bonus

Prove the isolation. Install a second release into another namespace. Nothing collides, because
every resource carries the release name as a prefix:

```bash
helm install nc2 ./nextcloud-chart --namespace nextcloud-helm-2 --create-namespace
```

Add shared labels to `templates/_helpers.tpl` and reference them with `{{ include ... }}`.
