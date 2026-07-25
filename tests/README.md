# Lab test suite (chainsaw)

Tests for every lab and solution in this repo. The suite uses
[chainsaw](https://kyverno.github.io/chainsaw/), a declarative Kubernetes e2e
runner: it spins up a throwaway [kind](https://kind.sigs.k8s.io/) cluster and
applies the manifests for real, then checks they behave the way the lab
intends. That catches what static linting (`kubeconform`, `kube-linter`,
already in `.gitlab-ci.yml`) can't see: invalid resource quantities, admission
rejections, broken probes, Helm values that render empty.

## Run it

```bash
# one-time per machine
brew install kind kubectl helm kubeconform        # if missing
curl -sSLo chainsaw.tar.gz \
  https://github.com/kyverno/chainsaw/releases/download/v0.2.15/chainsaw_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz \
  && tar -xzf chainsaw.tar.gz chainsaw && sudo mv chainsaw /usr/local/bin/

# run the suite
tests/bootstrap.sh        # create kind cluster + metrics-server + Gateway CRDs
chainsaw test tests       # run all tests (config picked up from .chainsaw.yaml)

# subsets
chainsaw test tests --selector suite=labs        # only lab manifests
chainsaw test tests --selector suite=nextcloud   # only the nextcloud case study
chainsaw test --test-dir tests/lab-13-readiness-broken   # a single test
```

Docker must be running (kind + the Dockerfile lint tests need it).

## Layout

```text
.chainsaw.yaml             # shared config: timeouts, parallelism, cleanup
tests/
  bootstrap.sh             # provisions the kind cluster + cluster add-ons
  <case>/chainsaw-test.yaml   # one self-contained Test per lab/solution
```

Each `chainsaw-test.yaml` is a `chainsaw.kyverno.io` `Test`. Chainsaw runs every
test in its own ephemeral namespace and tidies up afterwards, so cases never
collide. The assertion style per case:

| Pattern | How it's expressed |
| --- | --- |
| workload must run | `assert` the Pod is `Running` + `Ready`, or the Deployment/STS/RS reaches its replica count |
| broken-by-design lab (lab-13) | `error` — passes only if the workload **never** becomes available |
| one-shot pod (lab-11 env) | `assert` Pod phase `Succeeded` |
| admission must deny (lab-17 PSS) | `apply` with `expect: ($error != null)` |
| Helm chart (lab-23) | `script`: `helm template` piped to `kubeconform` |
| Nextcloud stack | `script`: `kubectl apply --dry-run=server` (full server-side validation, no heavy scheduling) |
| Nextcloud backup/restore (nc-07 runtime) | `script`: schedules MariaDB, runs the CronJob and restore Job for real |
| Dockerfile (docker labs) | `script`: `docker buildx build --check` |

`suite=labs|solutions|nextcloud|docker` labels let you slice the run.

## Adding a lab

Drop a new `tests/<name>/chainsaw-test.yaml`. Copy the closest existing case;
a plain "apply and become ready" lab is about a dozen lines.

## Scope / limitations

- Nextcloud is server-dry-run-validated by default (fast, and still catches
  schema, quantity and admission errors). `nc-07-backup-rbac-runtime` is the
  exception: it schedules a MariaDB fixture and runs the backup and restore Jobs
  end to end, because an unpullable image, a PVC the non-root pod cannot write,
  a database client missing from the image and an RBAC gap all pass a dry run
  and only fail once the pod starts. Nextcloud itself is still never scheduled;
  apply those manifests by hand on a cluster with enough resources.
- Docker labs ship partial build contexts (the Spring and Python sources live
  elsewhere), so they're BuildKit-linted (`--check`) rather than built.
- Azure (AKS) labs can't run on kind, so they stay docs-only and aren't covered
  here.
- CI runs only the static checks (kubeconform, kube-linter, helm lint). This
  live suite needs a real cluster, which GitLab.com shared runners can't start,
  so run it locally or on a Docker-capable runner before merging manifest changes.
