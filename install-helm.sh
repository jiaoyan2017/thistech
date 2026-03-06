#! /bin/bash

HELM_VERSION=v4.1.1

echo "Install helm ..."
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz
chmod +x ./linux-amd64/helm
cp ./linux-amd64/helm /usr/local/bin/
helm version

