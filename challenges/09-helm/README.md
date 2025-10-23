# Helm: Installing and Managing Prometheus

This exercise will guide you through using **Helm**, the Kubernetes package manager, to install the open-source monitoring solution **Prometheus** using the `kube-prometheus-stack` chart.

## Setup and Repository Management

1.  **Add the Repository:** Search for the `kube-prometheus-stack` chart on [Artifact Hub](https://artifacthub.io/) to find its repository URL. Then, **add the Helm chart repository** to your local Helm configuration, naming it **`prometheus-community`**.
2.  **Update Repositories:** **Update your local Helm chart index** to retrieve the latest information from all known repositories.
3.  **Identify Chart Version:** **List all available charts and their versions** from your configured repositories, and **identify the latest chart version** for **`kube-prometheus-stack`**.

---

## Installation and Verification

1.  **Install the Chart:** **Install the `kube-prometheus-stack` Helm chart** into your Kubernetes cluster.
    * *Note: The chart typically creates many resources, including Prometheus and Grafana.*
2.  **List Installed Charts:** **List the installed Helm charts** to confirm the installation was successful.
3.  **Locate the Service:** **List the Service** named **`prometheus-operated`** created by the Helm chart. This object is typically found in the default namespace or the namespace created by the chart.

---

## Access and Cleanup

1.  **Access the Dashboard:**
    * Use the **`kubectl port-forward`** command to **forward your local port $8080$ to port $9090$** of the **`prometheus-operated` Service**.
    * Open your browser and navigate to **`http://localhost:8080`** to access the Prometheus dashboard.
2.  **Uninstall:** **Stop the port forwarding** session and **uninstall the Helm chart** to clean up all deployed Prometheus resources.
