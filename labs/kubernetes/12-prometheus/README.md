# Metrics and Dashboards with Prometheus

In this example, we will install **Prometheus** into a Minikube cluster. First, we'll create a dedicated Namespace for Prometheus where all its related workloads will be installed.

-----

## Step 1: Set up Prometheus

Create a new Namespace for monitoring:

```shell
kubectl create namespace monitoring
```

Download the Prometheus configuration files:

```shell
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus/manifests
```

Install the **Custom Resource Definitions (CRDs)** for Prometheus:

```shell
kubectl apply --server-side -f setup/
```

Install the Prometheus Operator resources:

```shell
kubectl apply -f .
```

**Note:** This step may take a few minutes. You can monitor the status of the Deployments:

```shell
kubectl get deploy -n monitoring
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
blackbox-exporter     1/1     1            1           42m
grafana               1/1     1            1           42m
kube-state-metrics    1/1     1            1           42m
prometheus-adapter    2/2     2            2           42m
prometheus-operator   1/1     1            1           42m
```

Prometheus and **Grafana** are fully set up once all Pods are **`READY`**.

-----

## Step 2: Query Prometheus with Grafana

Once Prometheus and the Prometheus Operator are configured, Grafana is already installed as part of the Prometheus stack.

To make the Grafana service accessible, set up a **Port-Forward**:

```shell
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Open your web browser and navigate to **`http://localhost:3000`**.

The default login credentials are:
**Username: `admin`**
**Password: `admin`**

Next, search for the dashboard named "**Nodes**" in the search bar and open it.

The dashboard will populate with metrics over time. The source of these metrics is **Prometheus**, not the Kubernetes Metrics Server.

The Prometheus **Scraper** periodically queries the **Kubelet** on the Nodes for current metrics and stores them in its database. These are the data we can now visualize in Grafana.
