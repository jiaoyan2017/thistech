#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
nocolor="\033[0;m"
#user="core"
user="root"

shift $((OPTIND-1))

if [[ $# -lt 3 ]]; then
  echo "Usage: $(basename $0) <pem file path> <master-ip> <worker-ip> ..."
  exit
fi

# ssh in and exit in order to get the authenticity prompts all done up-front
function auth_prompt {
  local pem=$1
  shift
  while [[ $# -gt 0 ]]; do
    local host=$1
    shift
    ssh -t -i ${pem} ${user}@${host} "exit"
  done
}
auth_prompt "$@"

pem=$1
masterip=$2
shift 2

if [ ! -f $pem ]; then
  echo "File not found: $pem. Expecting private key file."
  exit
else
  openssl rsa -noout -text -in $pem > /dev/null 2> /dev/null
  if [ $? != 0 ]; then
     echo "File $pem is not a private key."
     exit
  fi
fi

function setup_worker {
join_cmd=$(kubeadm token create --print-join-command)
cat << EOF
  echo "control-plane ip: ${masterip}"
  echo "worker ip: ${worker_ip}"

echo "installing kube worker..."
# mv -f /home/core/0.common.sh /root/0.common.sh
# Comment above line because user runs this script as root.
/root/0.common.sh
sleep 5
${join_cmd} --ignore-preflight-errors all
EOF

}
# TODO verify master alive, if not throw error

while [[ $# > 0 ]]; do
  worker_ip=$1
  echo "worker_ip=${worker_ip}"
  shift
  sudo scp -i ${pem} /root/thistech/0.common/0.common.sh ${user}@${worker_ip}:~
  MYCOMMAND=$(setup_worker | base64 -w 0)
  ssh -t -i ${pem} ${user}@${worker_ip} "echo $MYCOMMAND | base64 -d | bash"
done
