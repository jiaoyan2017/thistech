#! /bin/bash

POD_NETWORK="192.168.0.0/16"

# Get IP of this host as the master IP
priv_ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1 | head -n 1)
# Init master
/usr/bin/kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v1.35.0 --apiserver-advertise-address=$priv_ip  --pod-network-cidr=${POD_NETWORK} --ignore-preflight-errors all | tee -a deploy.log

echo "Please exit root user to do the following steps."
