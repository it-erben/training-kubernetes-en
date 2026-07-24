# Lab 24: Helm: Helpers, Conditionals, and Reusable Charts

In Lab 23 you built a chart that swaps single values into blanks (`{{ .Values.replicaCount }}`). That is
enough for one component with a fixed name, but real charts hit two walls the moment they grow:

- **Names collide.** Your chart hardcodes `nginx-deployment`. Install it twice and the second install
  fights the first over the same name.
- **Repetition.** Once names are generated, a dozen places have to generate the *same* name the same way.

This lab teaches the three Helm building blocks that solve this: **named template helpers**, **passing
data into a helper with `dict`**, and **conditionals** to switch resources on and off. These are exactly
the pieces the Nextcloud case-study chart uses, so this lab is the on-ramp to it.

**Goal of this exercise:** grow the nginx chart from Lab 23 so every resource name is prefixed with the
release name (no collisions), the prefixing lives in one reusable helper, and the Service can be toggled
off with a single flag.

> **Docs:**
>
> - [Named templates (`define` / `include`)](https://helm.sh/docs/chart_template_guide/named_templates/)
> - [Built-in objects (`.Release`, `.Values`)](https://helm.sh/docs/chart_template_guide/builtin_objects/)
> - [Flow control (`if` / `else`)](https://helm.sh/docs/chart_template_guide/control_structures/)
>
> **Shells:** the `helm` and `kubectl` commands below are identical on Windows, macOS, and Linux.
> Where a command differs, both a Bash and a PowerShell variant are shown.

---

## Part 0: Start from your Lab 23 chart

This lab evolves the chart you already built. Copy it into a fresh folder so you keep the original:

```bash
cp -r my-nginx-chart my-nginx-chart-v2
cd my-nginx-chart-v2
```

```powershell
Copy-Item -Recurse my-nginx-chart my-nginx-chart-v2
cd my-nginx-chart-v2
```

Everything below happens inside `my-nginx-chart-v2`. Don't have the Lab 23 chart handy? Copy the
starting point from `solutions/kubernetes/lab-23-helm-create-challenge/my-nginx-chart`.

---

## Part 1: See how real charts do it

Before writing helpers yourself, look at the ones Helm generates. Scaffold a brand-new chart next to
your work (it is temporary, you delete it at the end of this part):

```bash
helm create scaffold
```

Open `scaffold/templates/_helpers.tpl`. Files beginning with `_` are not rendered into Kubernetes
manifests; they hold reusable snippets that other templates pull in. Two of them matter here:

- **`scaffold.fullname`** builds a resource name by combining the release name with the chart name,
  trimmed to Kubernetes' 63-character limit (it has a couple of override branches you can ignore).
- **`scaffold.labels`** returns a block of labels every resource shares.

Now open `scaffold/templates/deployment.yaml` and notice it never writes a literal name. It calls
`{{ include "scaffold.fullname" . }}` instead. That is the pattern you are about to add to your own chart.

Delete the scaffold, you only needed to read it:

```bash
rm -rf scaffold
```

```powershell
Remove-Item -Recurse -Force scaffold
```

---

## Part 2: Write a name helper

A **named template** is a snippet you write once and call by name from anywhere, like a small function.
Create `templates/_helpers.tpl` and define one. `define` gives the snippet its name; `include` (next
part) runs it. `.Release.Name` is the name from `helm install <name>`, so putting it in front guarantees
every install gets its own set of names.

```yaml
{{- define "my-nginx.fullname" -}}
{{- $name := .name | trunc 63 | trimSuffix "-" -}}
{{- $prefixLength := sub 62 (len $name) | int -}}
{{- printf "%s-%s" (.root.Release.Name | trunc $prefixLength | trimSuffix "-") $name -}}
{{- end -}}
```

Reading it line by line:

- You hand the helper a short suffix like `web`.
- Kubernetes rejects names longer than 63 characters, so the helper trims the suffix to fit, then works
  out how much room is left for the release-name prefix (63, minus 1 for the joining dash, minus the
  suffix length) and trims the release name to that.
- It glues them together as `<release>-<suffix>`. The `trimSuffix "-"` calls only avoid an ugly trailing
  dash if a trim lands on one.

Call it with `web` in a release named `nc` and you get `nc-web`, always a legal name.

Unlike the scaffold's helper, this one takes a **suffix** argument, because a growing chart names many
things (`web`, `db`, `cache`, ...) and each needs its own name off the same release prefix.

---

## Part 3: Wire the helper into the Deployment

`include` runs a named template, but it accepts only **one** argument. You need to pass two things: the
chart context (for `.Release.Name`) and the suffix. Bundle them into a `dict`, Helm's word for a small
bag of named values:

```yaml
{{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
```

Here `"root" .` hands the whole context in under the key `root` (which the helper reads as
`.root.Release.Name`), and `"name" "web"` is the suffix (`.name`).

Rewrite `templates/deployment.yaml` so every place that named the Deployment now calls the helper. The
name, the pod labels, and the selector must all resolve to the **same** string, or the Deployment won't
find its own pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
  labels:
    app: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
  template:
    metadata:
      labels:
        app: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
    spec:
      containers:
      - name: nginx
        image: nginx:1.29.4
        ports:
          - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

Render it and confirm the names came out as `<release>-web`:

```bash
helm template nc . | grep "nc-web"
```

```powershell
helm template nc . | Select-String "nc-web"
```

You should see four `nc-web` hits: the Deployment name, its `app` label, the selector, and the pod
label. The container's own `name: nginx` is left alone; only resource names take the prefix.

---

## Part 4: Make the Service optional

Not every install wants a Service. Wrap the whole file in an `{{- if }}` guard: when the value is `false`,
Helm leaves everything between the two tags out of the output entirely.

First add the switch to `values.yaml`:

```yaml
service:
  enabled: true
  type: ClusterIP
  port: 80
```

Then rewrite `templates/service.yaml`, guarded and using the same helper as the Deployment so the selector
matches:

```yaml
{{- if .Values.service.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
spec:
  selector:
    app: {{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
  ports:
    - protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: 80
  type: {{ .Values.service.type }}
{{- end }}
```

Prove the switch works. With it on you get one Service, with it off you get none:

```bash
helm template nc . | grep -c "kind: Service"
helm template nc . --set service.enabled=false | grep -c "kind: Service"
```

```powershell
(helm template nc . | Select-String "kind: Service").Count
(helm template nc . --set service.enabled=false | Select-String "kind: Service").Count
```

Lint before installing:

```bash
helm lint .
```

---

## Part 5: Prove the isolation

The whole reason for release-name prefixing: install the same chart twice into the **same** namespace
without a collision. Different namespaces would hide the problem (names are namespace-scoped), so the test
has to happen in one namespace.

First see what goes wrong without the prefix. Install your original Lab 23 chart twice:

```bash
helm install a ../my-nginx-chart --namespace demo --create-namespace
helm install b ../my-nginx-chart --namespace demo
```

The second install fails. Both releases render a Deployment with the same hardcoded name, and Helm refuses
to let release `b` grab a resource that release `a` already owns:

```text
Error: INSTALLATION FAILED: Unable to continue with install: Deployment "nginx-deployment" in namespace
"demo" exists and cannot be imported into the current release
```

Now uninstall the one that landed and install the **prefixed** chart twice into that same namespace:

```bash
helm uninstall a --namespace demo
helm install web1 . --namespace demo
helm install web2 . --namespace demo
kubectl get deploy -n demo
```

Both succeed. The Deployments are named `web1-web` and `web2-web`: same chart, same namespace, no conflict,
because the release name is baked into every resource name.

---

## Part 6: Cleanup

```bash
helm uninstall web1 web2 --namespace demo
kubectl delete namespace demo
```

---

## Where this leads

You now have every Helm building block the Nextcloud case-study chart is built from: a `fullname` helper,
names passed in with `dict`, release-name prefixing, and `{{- if }}` conditionals. That chart applies the
same four ideas to six components at once, with more cross-references to keep straight. It is bigger, not
harder.
