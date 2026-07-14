# Cluster setup with kubeadm

```bash
REGION=eu-central-1
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

aws ec2 create-security-group \
  --group-name kubeadm-demo-sg \
  --description "Security group for kubeadm demo cluster" \
  --vpc-id $VPC_ID \
  --region $REGION

MY_IP=$(curl https://ipinfo.io/ip)

SG_ID=$(aws ec2 describe-security-groups \
  --group-names kubeadm-demo-sg \
  --region $REGION \
  --query "SecurityGroups[0].GroupId" --output text)

# SSH from your IP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 22 \
  --cidr $MY_IP/32 --region $REGION

# All traffic within the SG (node-to-node)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol -1 --port -1 \
  --source-group $SG_ID --region $REGION


AMI_ID="ami-0cf5b48e0c60471d0"

INSTANCE_TYPE=t3.medium

KEY_NAME=alexander.erben

# Control-plane
aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=kubeadm-cp}]' \
  --count 1

# 2 worker nodes
aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=kubeadm-worker}]' \
  --count 2

aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=kubeadm-*" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value|[0],PublicIpAddress]" \
  --output table

```

---

| DescribeInstances | +-----------------+---------------+ | kubeadm-worker | 3.75.227.42 | | kubeadm-worker |
3.79.245.83 | | kubeadm-cp | 3.71.189.25 | +-----------------+---------------+

ssh -i ubuntu@3.79.245.83

```bash
sudo apt-get update
sudo apt-get upgrade -y

sudo swapoff -a

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

# Use systemd cgroup driver (matches kubelet defaults)
#sudo sed -i 's/^$begin:math:text$\\s\*SystemdCgroup\\s\*\=\\s\*$end:math:text$false/\1true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes apt repo
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key |
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#sudo systemctl stop containerd
#sudo mkdir -p /etc/containerd
#sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.bak.$(date +%s) 2>/dev/null || true
#containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
#sudo systemctl start containerd
#sudo systemctl status containerd
#sudo ctr plugins ls | grep cri

```

```bash
sudo kubeadm join 172.31.30.98:6443 --token fs5s1f.zttvyymvxe36tjx8 \
 --discovery-token-ca-cert-hash sha256:ca0a289df7ca49ad0ef39f971ebea65f6ce975bb295701d2c580518cac681805
```
