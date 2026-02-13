#!/bin/bash

# 1. Check OS
## get the kernel version using the command 
echo "kernel version: $(uname -r)"
## Verify the MAC address and product_uuid are unique for every node
# ifconfig -a
echo "product_uuid: $(cat /sys/class/dmi/id/product_uuid)"

# 2. Update repository to use aliyun:
mv /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list<<EOF
# Ubuntu 22.04
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF
# 3. Install packages needed to use the k8s apt repository.
apt-get update
apt-get install -y apt-transport-https ca-certificates lsb-release curl gpg gnupg vim git wget

# 4. Download the public signing key for the Kubernetes package repositories. 
## If the directory /etc/apt/keyrings does not exist, it should be created before the curl command, read the note below.
## sudo mkdir -p -m 755 /etc/apt/keyrings
## In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, and it should be created before the curl command.
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 5. Update Kubernetes v1.35 sources to Aliyun.
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.35/deb/ /" | \
	tee /etc/apt/sources.list.d/kubernetes.list

# 6. Install kubelet, kubeadm, kubectl
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
## Enable the kubelet service before running kubeadm
systemctl enable --now kubelet

# 7. Installing containerd from the official binary:
## Reference: https://github.com/containerd/containerd/blob/main/docs/getting-started.md
## (0) Downloading archives
echo "Download archives ..."
wget https://github.com/containerd/containerd/releases/download/v2.2.1/containerd-2.2.1-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
wget https://github.com/opencontainers/runc/releases/download/v1.4.0/runc.amd64
wget https://github.com/opencontainers/runc/releases/download/v1.4.0/libseccomp-2.5.6.tar.gz
wget https://github.com/containernetworking/plugins/releases/download/v1.9.0/cni-plugins-linux-amd64-v1.9.0.tgz
echo " >>> Archives downloaded. <<<"
## (1) Installing containerd and Start containerd via systemd
tar Cxzvf /usr/local containerd-2.2.1-linux-amd64.tar.gz
cp containerd.service /lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd
## (2) Installing runc
## The binary is built statically and should work on any Linux distribution.
install -m 755 runc.amd64 /usr/local/sbin/runc 
## (3) Installing CNI plugins
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.9.0.tgz
echo " >>> containerd service and CNI installation finished. <<<"

# 8. Update containerd/config.toml
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
## Update "sandbox = 'registry.k8s.io/pause:3.10.1'" 
## to     "sandbox = 'registry.aliyuncs.com/google_containers/pause:3.10.1'"
sed -i '/pinned_images/{n;s/k8s\.io/aliyuncs.com\/google_containers/}' /etc/containerd/config.toml
systemctl daemon-reload
systemctl restart containerd

