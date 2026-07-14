# Lab 22: Helm: Installing and Managing Prometheus

This exercise walks you through using **Helm**, the Kubernetes package manager, to install the open-source monitoring
solution **Prometheus** via the `kube-prometheus-stack` chart.

## Setup and Repository Management

1. **Add the repository:** Search [Artifact Hub](https://artifacthub.io/) for the
   `kube-prometheus-stack` chart. It comes with a one-line installation guide.
2. At the end of the installation, the output tells you how to retrieve the default Grafana password.
   Run those commands in a Bash shell (on Windows e.g. Git Bash).
3. Access Grafana via `minikube service kube-prometheus-stack-grafana`
