#! /bin/bash

# Reference: https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/
# calico.yaml is from https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

# https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
# yamls downloaded from: 
https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml
https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/custom-resources.yaml

kubectl apply -f ../resources/tigera-operator.yaml
kubectl apply -f ../resources/calico_v3.31.3_custom-resources.yaml
