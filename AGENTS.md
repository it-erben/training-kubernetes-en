# Working rules

## Voice

- Terse. Say the thing, stop. No preamble, no recap of what you just did, no
  "great question", no restating the task back.
- No filler adjectives (robust, seamless, powerful, comprehensive, production-grade).
  State briefly what the code does, not how good it is.
  Don't paraphrase what the next lines of code do. Instead
  explain WHY and HOW if that really helps understanding.
- Docs and READMEs: what it is, how to use it, what it exposes. Nothing else.
- Commit messages: conventional-commit, imperative, one line where possible.
  Get the scope right — release tooling may route on it. Breaking changes get
  `!` (`feat(api)!: …`) or a `BREAKING CHANGE:` footer. Subject line ≤ 72 chars,
  imperative mood ("add", "fix", not "added", "fixes"). Body wraps at 72.
- Prefer small, focused commits. Release tooling often derives version bumps and
  the changelog from commit subjects.
- No ticket numbers in code, commits, or docs.
- Comments explain *why*, not *what*. Code comments state intent or a constraint
  the code cannot show. Delete comments that restate the code.
- Always consider comments and docs as a whole. Never just append. Revalidate them
  in their context and update to factual state. Research in the codebase if in
  doubt. Remove stale and out-of-context references, former observations,
  depictions of situations that led to a previous change, machine names or
  addresses, and any guesses about downstream usage of this repo and its artifacts
  apart from valid and up-to-date examples.
- Reference another repository or project only when its state is the direct reason
  for the change (a dependency bump, a vendored fix, an API contract pinned to a
  published version). Context for reviewers, gratitude, or cross-linking belongs in
  the PR thread or an issue, not the commit.
- Write declarative facts. No personal pronouns ("I", "we", "you"). Don't address a
  reader: no "note that…", "as you can see…", "we decided to…", "this should help…".
- Don't narrate. No history of what was tried first, what failed, or what
  alternatives were considered.
- No filler verbs without specifics. "Clean up", "improve", "refactor" alone tell
  nothing; either name the actual change or drop the line.
- No checklists, "Summary" / "Test plan" sections, marketing phrasing, or emojis.

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

- Run the project's lint, tests, and build for everything touched.
- Run `pre-commit run --all-files` and fix everything it reports.
- Check touched manifests the way CI does:
  - `kube-linter lint <file>`
  - `kubeconform -strict -kubernetes-version 1.35.0 <file>`
  - for charts also `helm lint <chart>` and `helm template <chart>`
- The chainsaw suite does not run in CI, only locally: `tests/bootstrap.sh`
  then `chainsaw test tests`, or a subset with `--selector suite=labs` or
  `--selector suite=nextcloud`. Anyone changing a manifest that has a test
  runs it.
- Don't claim done without running the check. Evidence before assertions.
- Drop any TODO marker you added during your session and re-iterate, or let the
  user know to create a follow-up. Remove all markers and references to your own
  tasklist or historical workitem/workphase (P2, P3a, Item 1, Task A, etc.) along
  with their narrative. If something is truly left open, tell the user outside of
  the code, docs, markdown, comments, PR descriptions, commit messages, or anything
  else inside this repo and its connected pipeline.

## How this repo is laid out

Four course tracks, each with the same directory name under `labs/` and
`solutions/`:

- `docker` — thirteen labs from the Docker components to a multistage build
  for Spring Boot.
- `kubernetes` — 27 labs, the main track. The number is the order in the
  course.
- `microsoft-azure-kubernetes-service` — seven labs for the AKS course.
- `nextcloud-casestudy` — the running case study: database, phpMyAdmin,
  secrets, Nextcloud, production hardening, Helm chart, backup with RBAC.

Alongside those:

- `demos/` — what the trainer shows live, from `kubeadm` through EKS to the
  Rancher distributions. Not written as labs.
- `tests/` — chainsaw suite against a kind cluster, one directory per checked
  lab or solution. `tests/README.md` covers install and invocation.
- `docs/superpowers/` — plans and specs for larger reworks.

A lab directory and its counterpart under `solutions/` carry the same name. A
new lab needs both, plus a directory under `tests/` wherever it is
meaningfully checkable.

## Traps in this repo

- **This repo and `gfu/kubernetes` are the same course in two languages.**
  This one started as the English translation; the German repo has since
  merged changes back from here. Anything structural — a new lab, a renamed
  directory, a changed manifest — belongs in both. Only the prose differs.
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
