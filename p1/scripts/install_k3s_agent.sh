#!/bin/bash

apt-get update -y

apt-get install -y curl


export K3S_URL="https://192.168.56.110:6443"
export K3S_TOKEN="THIS_IS_MY_SECRET_TOKEN_FOR_IOT_PROJECT"

export INSTALL_K3S_EXEC="agent --node-ip 192.168.56.111"

echo "K3s agent kuruluyor..."

sleep 10
curl -sfL https://get.k3s.io | sh -

echo "Agent kurulumu tamamlandı."