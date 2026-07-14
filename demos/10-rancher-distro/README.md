# Showcase: What makes Rancher special as a distribution?

Your company works with Rancher. This ~10-minute demo shows **live** what sets the
Rancher world apart from "bare" upstream Kubernetes: two clusters compared side by side
on this laptop, no slides.

## What do we mean when we say "Rancher"?

"Rancher" is an umbrella term for three layers, and they're easy to mix up:

| Layer | What it is | Competition |
|---------|-----------|------------|
| **Rancher Manager** | Multi-cluster management platform (UI, RBAC, app catalog, Fleet GitOps, observability) — centrally manages *external* clusters (EKS, AKS, on-prem) | Platform9, Tanzu, OpenShift Console |
| **RKE2** | Hardened K8s distribution: CIS benchmark by default, FIPS build, embedded etcd HA, a single binary. Target audience: government/enterprise | kubeadm, OpenShift, Talos |
| **K3s** | Lightweight distribution, < 70 MB single binary, batteries included. Edge/IoT/dev | MicroK8s, k0s |

This demo focuses on the **distribution** level (K3s/RKE2), because you already see the
Manager every day. The real difference sits *below* the UI.

## Setup: two clusters side by side

We compare **K3s** (Rancher distribution, via `k3d` in Docker) with **vanilla Kubernetes**
(upstream kubeadm, via `kind`).

```bash
# Rancher distribution: K3s
k3d cluster create rancher-demo --servers 1 --agents 1 --wait

# Vanilla upstream Kubernetes
kind create cluster --name vanilla-demo --wait 90s
```

Both are up in ~30 seconds. K3d pulls the image `rancher/k3s`, and the node reports itself
as `v1.35.5+k3s1` — the `+k3s1` suffix gives it away.

## Difference 1: "Batteries included" vs. a bare cluster

```bash
kubectl --context k3d-rancher-demo get pods -A
kubectl --context kind-vanilla-demo  get pods -A
```

**K3s** ships out of the box with:

- **Traefik** — ingress controller, ready to use immediately
- **ServiceLB (Klipper)** — `type: LoadBalancer` works without a cloud provider
- **local-path-provisioner** — default StorageClass, PVCs work right away
- **metrics-server** — `kubectl top` just works
- **CoreDNS** — preconfigured

**Vanilla** ships with: CoreDNS, kube-proxy, etcd, CNI (kindnet) — and nothing else.
No ingress, no LoadBalancer, no metrics-server. You have to install everything yourself.

> **Key point:** Rancher distributions are *opinionated* and production-ready from the start.
> Upstream hands you a box of parts and leaves half the assembly to you.

## Difference 2: LoadBalancer without a cloud

```bash
kubectl --context k3d-rancher-demo apply -f lb-demo.yaml
kubectl --context kind-vanilla-demo  apply -f lb-demo.yaml

# After a few seconds:
kubectl --context k3d-rancher-demo get pods -n kube-system | grep svclb
```

K3s' **ServiceLB controller** automatically creates `svclb-*` pods that expose the
LoadBalancer on the node IPs — no MetalLB, no cloud integration. On vanilla,
`EXTERNAL-IP` stays `<pending>` forever; you'd need MetalLB first (see demo 09).

> Note: Inside `k3d` (everything on a single Docker host), the second svclb on
> port 80 collides with Traefik and stays `Pending` — on real K3s nodes, the service gets the
> node IP. The *mechanism* is the point: K3s spawns the svclb pod automatically, vanilla does nothing.

## Difference 3: Declarative Helm — without the `helm` CLI

This is genuinely Rancher-specific. K3s ships with a **Helm controller** and a CRD
`HelmChart`. You describe a Helm release as a Kubernetes object — the controller
installs it. No `helm install`, no Tiller, no CI step needed.

```bash
kubectl --context k3d-rancher-demo apply -f helmchart.yaml
sleep 25
kubectl --context k3d-rancher-demo get helmchart -n kube-system
kubectl --context k3d-rancher-demo get pods     -n demo
```

Result: `podinfo` is running in the `demo` namespace — installed from a single YAML manifest.
This is also how K3s/RKE2 bootstraps itself, by the way: Traefik is rolled out internally the
same way, via a `helm-install-traefik` job (visible in `get pods -A`).

```bash
kubectl --context k3d-rancher-demo get crd | grep cattle.io
# helmcharts.helm.cattle.io, helmchartconfigs.helm.cattle.io, addons.k3s.cattle.io
```

On vanilla, none of these CRDs exist — Helm stays an external CLI tool.

## Summary

| Topic | Vanilla (kubeadm/kind) | Rancher (K3s/RKE2) |
|-------|------------------------|--------------------|
| Ingress | install yourself | Traefik preinstalled |
| LoadBalancer | MetalLB or similar needed | ServiceLB built in |
| Storage | set up yourself | local-path default |
| Helm | external CLI | declarative `HelmChart` CRD |
| Hardening | manual | RKE2: CIS/FIPS by default |
| Multi-cluster | — | Rancher Manager UI + Fleet |
| Footprint | multiple components | K3s: 1 binary, < 70 MB |

**Take-away:** Other distributions deliver Kubernetes. Rancher delivers a
*ready-to-use system* — from edge (K3s) through hardened enterprise (RKE2) to
central management (Manager). That's the difference you feel in day-to-day work.

## Cleanup

```bash
k3d cluster delete rancher-demo
kind delete cluster --name vanilla-demo
```
