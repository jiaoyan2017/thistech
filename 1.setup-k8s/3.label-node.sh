#! /bin/bash

nodes=$(kubectl get nodes | grep -v NAME | grep -v control-plane | grep none | awk '{print $1}')

for node in ${nodes}
do
  kubectl label node ${node} node-role.kubernetes.io/node=
done
