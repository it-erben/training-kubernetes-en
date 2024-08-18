# Einrichten eines EKS-Clusters

- Öffne die AWS-Konsole mit einem Account mit Administratorberechtigungen
- Starte Cloud Shell
- Führe folgendes Skript aus: 

```shell
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin
```

- Erzeuge den Cluster:
```shell
eksctl create cluster --name learn-k8s-cluster --node-type t3.small --nodes 3 --nodes-min 3 --nodes-max 5 --region eu-central-1
```

- Richte kubectl ein:
```shell
aws eks update-kubeconfig --region eu-central-1 --name learnk8s-cluster
```
