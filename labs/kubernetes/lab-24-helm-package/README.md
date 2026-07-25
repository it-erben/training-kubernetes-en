# Lab 24: Helm: Helpers, Conditionals, and Reusable Charts

In Lab 23 you built a chart that drops single values into blanks, like `{{ .Values.replicaCount }}`. That
works fine for one small app with a fixed name. But as soon as a chart gets bigger, two problems show up:

- **Name collisions:** Your chart always uses the deployment name `nginx-deployment`. Install the
  chart once and it's fine. Install it a *second* time and both copies try to claim the exact same name.
  Kubernetes won't allow it.
- **The same name is written out over and over.** A real app writes its name in lots of places (the
  Deployment, its labels, its selector, its Service...). If all of those have to say the *same* thing and
  you're copy-pasting by hand, one typo and things quietly stop finding each other.

This lab teaches the three Helm tools that fix both problems:

1. **Named template helpers:** a little reusable snippet you write once and call by name.
2. **Passing data into a helper with `dict`:** how to hand your helper the couple of things it needs to
   do its job.
3. **Conditionals** (`if`): an on/off switch that lets you include or skip a whole piece of the chart.

**What you'll end up with:** the same nginx chart from Lab 23, but upgraded so that every resource name
automatically starts with the release name (no more collisions), that naming rule lives in *one* place
you can reuse, and the Service can be switched off with a single flag.

> **Docs:**
>
> - [Named templates (`define` / `include`)](https://helm.sh/docs/chart_template_guide/named_templates/)
> - [Built-in objects (`.Release`, `.Values`)](https://helm.sh/docs/chart_template_guide/builtin_objects/)
> - [Flow control (`if` / `else`)](https://helm.sh/docs/chart_template_guide/control_structures/)
>
> **Shells:** the `helm` and `kubectl` commands below are the same on Windows, macOS, and Linux.
> Where a command has to differ, both a Bash and a PowerShell version are shown.

---

## Part 0: Start from your Lab 23 chart

This lab builds directly on the chart you already made. Copy it into a new folder first, so your original
stays safe and you have something to fall back to:

```bash
cp -r my-nginx-chart my-nginx-chart-v2
cd my-nginx-chart-v2
```

```powershell
Copy-Item -Recurse my-nginx-chart my-nginx-chart-v2
cd my-nginx-chart-v2
```

From here on, everything happens inside `my-nginx-chart-v2`.

---

## Part 1: See how Helm's own charts do it

Before you write a helper of your own, it helps to see one that already exists. Helm can generate a
complete example chart for you, so let's make one just to look at (you'll throw it away in a minute):

```bash
helm create scaffold
```

Open `scaffold/templates/_helpers.tpl`. Any file whose name starts with an underscore (`_`) is special:
Helm does **not** turn it into Kubernetes YAML. Instead it's a scratchpad of reusable snippets that the
other template files borrow from. Two snippets in there are worth noticing:

- **`scaffold.fullname`** - builds a resource name by sticking the release name on the front and then
  shortening the result so it fits inside Kubernetes' 63-character name limit.
- **`scaffold.labels`** - hands back a block of labels that every resource in the chart shares.

Now open `scaffold/templates/deployment.yaml`. Notice it never types out a name directly. Instead it says
`{{ include "scaffold.fullname" . }}`, which means "run that snippet and paste the result here." That is
exactly the pattern you're about to add to your own chart.

You've seen what you needed, so delete the example:

```bash
rm -rf scaffold
```

```powershell
Remove-Item -Recurse -Force scaffold
```

---

## Part 2: Write your own name helper

Create a new file `templates/_helpers.tpl` and put one snippet in it. A quick vocabulary note before the
code: `define` is how you *create* a snippet and give it a name, and `include` (coming in Part 3) is how
you later *run* it. The key piece is `.Release.Name`, which is whatever name you typed in
`helm install <name>`. By putting it on the front of every name, each install automatically gets its own
unique set of names.

```yaml
{{- define "my-nginx.fullname" -}}
{{- $name := .name | trunc 63 | trimSuffix "-" -}}
{{- $prefixLength := sub 62 (len $name) | int -}}
{{- printf "%s-%s" (.root.Release.Name | trunc $prefixLength | trimSuffix "-") $name -}}
{{- end -}}
```

Here's what it's doing, in plain English:

- You give the helper a short word (a "suffix") like `web`.
- Kubernetes refuses any name longer than 63 characters. So the helper first trims that short word down if
  needed, figures out how many characters are left over, and trims the release name to fit in the leftover
  space. This way the final name can never blow past the limit.
- Finally it glues the two together as `<release>-<suffix>`. (The `trimSuffix "-"` bits are just tidiness:
  if a trim happens to end on a dash, they shave it off so you don't get an ugly `something--web`.)

So if your release is named `nc` and you pass in `web`, you get `nc-web`, and it's guaranteed to be a
legal Kubernetes name every time.

One difference from the ready-made scaffold helper you looked at in Part 1: this one takes a **suffix** you
pass in. That's on purpose. A bigger chart names lots of things (`web`, `db`, `cache`, and so on), and each
needs its own name that still shares the same release prefix. Passing in the suffix lets one helper name
all of them.

---

## Part 3: Plug the helper into the Deployment

`include` runs a snippet, but there's a catch: it only accepts **one** thing handed to it. And your helper
needs *two* pieces of information: the overall chart context (so it can reach `.Release.Name`) and the
suffix word. The trick is to wrap both into a single `dict` (a small map of key/value pairs), so from
`include`'s point of view you're still passing one thing:

```yaml
{{ include "my-nginx.fullname" (dict "root" . "name" "web") }}
```

Reading that: `"root" .` stuffs the whole chart context in under the key `root` (which is why the helper
reaches for `.root.Release.Name`), and `"name" "web"` is your suffix (which the helper reads as `.name`).

Now rewrite `templates/deployment.yaml` so that every spot that used to hardcode the name calls the helper
instead. This part matters: the name, the pod labels, and the selector all have to come out as the **exact
same** string. If they don't match, the Deployment literally can't find the pods it just created (the
selector is how a Deployment says "these pods are mine").

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

Now render the chart (that just fills in the templates and prints the result, nothing gets installed yet)
and check that the names came out as `<release>-web`:

```bash
helm template nc . | grep -E "name:|app:"
```

```powershell
helm template nc . | Select-String "name:|app:"
```

---

## Part 4: Make the Service optional

Not every install actually wants a Service. Instead of deleting the file when you don't need it, wrap the
whole thing in an `{{- if }}` guard. When the switch is `false`, Helm simply leaves out everything between
the opening `if` and the closing `end`, as if the file weren't there at all.

First, add the switch to `values.yaml`:

```yaml
service:
  enabled: true
  type: ClusterIP
  port: 80
```

Then rewrite `templates/service.yaml` so it's wrapped in the guard and uses the *same* name helper as the
Deployment (so the Service's selector matches the pods):

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

Now prove the switch does what you think. Turned on you should get exactly one Service; turned off, none.
These commands just count how many times `kind: Service` shows up in the rendered output:

```bash
helm template nc . | grep -c "kind: Service"
helm template nc . --set service.enabled=false | grep -c "kind: Service"
```

```powershell
(helm template nc . | Select-String "kind: Service").Count
(helm template nc . --set service.enabled=false | Select-String "kind: Service").Count
```

Before installing anything for real, run Helm's built-in checker to catch obvious mistakes:

```bash
helm lint .
```

---

## Part 5: Prove it actually solves the collision problem

This is the payoff, the whole reason you added release-name prefixing. Install the *same* chart twice and
watch them run side by side. Each release goes into its own namespace to keep things tidy:

```bash
helm install web1 . --namespace demo-a --create-namespace
helm install web2 . --namespace demo-b --create-namespace
kubectl get deploy -n demo-a
kubectl get deploy -n demo-b
```

The first one comes out named `web1-web`, the second `web2-web`. Same chart, zero conflict, because the
release name is now baked right into every resource name. Back in Lab 23, this would have been an
immediate clash.

---

## Part 6: Clean up

Tear down what you created so you don't leave stray resources lying around:

```bash
helm uninstall web1 --namespace demo-a
helm uninstall web2 --namespace demo-b
kubectl delete namespace demo-a demo-b
```

---

## Where this leads

You now know every Helm building block that the Nextcloud case-study chart is made of: a `fullname` helper,
passing data in with `dict`, prefixing names with the release name, and `{{- if }}` on/off switches. That
bigger chart isn't any harder conceptually. It's these same four ideas applied to six components at once,
just with more moving parts to keep lined up.
