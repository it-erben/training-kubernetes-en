# Working rules

Voice, writing and commit rules live in the user configuration
(`~/.claude/CLAUDE.md`, sections "Schreibweise in deutschen Texten" and
"Arbeitsregeln in Repos"). This file only covers what is specific to this
repository.

## Lab READMEs

Lab instructions are prose, not a spec sheet. This overrides the pronoun and
reader-address rules above: address the learner as "you".

- Open with a paragraph naming what already exists from earlier labs, what is
  missing, and what this lab adds. State the payoff in one sentence.
- Every part gets a reason before it gets a command: why the resource exists,
  what breaks without it.
- Explain unfamiliar mechanics in plain words before showing syntax. An everyday
  comparison beats a definition (`templates/` as form letters, `values.yaml` as
  the answers Helm pastes in).
- Walk dense snippets through line by line and close with what they return.
- Provide the manifests the lab is not teaching in full, and say why. Leave the
  ones it is teaching as a bulleted requirement list for the learner to write.
- Let a step fail on purpose where the failure is the lesson: show the real error
  output, then fix it.
- Pose a question at the point where the learner should stop and think.
- Terse at sentence level still applies: no filler adjectives, no marketing, no
  recap of the section above.

Existing labs are not retrofitted. This voice applies to new labs and to labs
being reworked.

## Before you finish

- Run `pre-commit run --all-files` and fix everything it reports.
- Check touched manifests the way CI does:
  - `kube-linter lint <file>`
  - `kubeconform -strict -kubernetes-version 1.35.0 <file>`
  - for charts also `helm lint <chart>` and `helm template <chart>`
- The chainsaw suite does not run in CI, only locally: `tests/bootstrap.sh`
  then `chainsaw test tests`, or a subset with `--selector suite=labs` or
  `--selector suite=nextcloud`. Anyone changing a manifest that has a test
  runs it.

## How this repo is laid out

Four course tracks, each with the same directory name under `labs/` and
`solutions/`:

- `docker`: thirteen labs from the Docker components to a multistage build
  for Spring Boot.
- `kubernetes`: 27 labs, the main track. The number is the order in the
  course.
- `microsoft-azure-kubernetes-service`: seven labs for the AKS course.
- `nextcloud-casestudy`: the running case study: database, phpMyAdmin,
  secrets, Nextcloud, production hardening, Helm chart, backup with RBAC.

Alongside those:

- `demos/`: what the trainer shows live, from `kubeadm` through EKS to the
  Rancher distributions. Not written as labs.
- `tests/`: chainsaw suite against a kind cluster, one directory per checked
  lab or solution. `tests/README.md` covers install and invocation.
- `docs/superpowers/`: plans and specs for larger reworks.

A lab directory and its counterpart under `solutions/` carry the same name. A
new lab needs both, plus a directory under `tests/` wherever it is
meaningfully checkable.

## Traps in this repo

- **This repo and `gfu/kubernetes` are the same course in two languages.**
  This one started as the English translation; the German repo has since
  merged changes back from here. Anything structural belongs in both: a new lab, a renamed
  directory, a changed manifest. Only the prose differs.
- **The chainsaw suite does not run in CI.** GitLab.com runners cannot start
  kind (`kubeadm` init fails under nested Docker). A green pipeline says the
  manifests are statically valid, not that they work.
- **`solutions/microsoft-azure-kubernetes-service` covers exactly one lab**,
  and under a different name: lab `lab-01-create-cluster` against solution
  `lab-01-cluster-setup`. Six AKS labs have no solution at all.
- **`lab-20-ingress` and `lab-21-gateway-api` have no solution**, unlike the
  other 25 Kubernetes labs.
- **`.markdownlint-cli2.yaml` ignores `slides/**/*.md`, and that directory no
  longer exists.** The ignore entry and the `pdf-publisher` component in
  `.gitlab-ci.yml` are leftovers.
- **yamllint skips `**/templates/**`** because Go templating is not valid
  YAML. Errors in chart templates surface at `helm template`, not at lint
  time.
- **`workflow.rules` prevents duplicate pipelines**, and the lint jobs are
  deliberately overridden so they also run on a direct push to `main`. A new
  check must hang off `*checks-rules`, or it only ever runs in merge requests.
- **CI runs on two platforms.** `.gitlab-ci.yml` wires up the GitLab
  components, `.github/workflows/ci.yml` calls `lint.yml` and `release.yml`
  from `it-erben/ci`. Helm, kube-linter and kubeconform are repo-local jobs
  there. No Pages, no deployment.
