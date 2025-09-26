#!/bin/bash

apt-get update -y

apt-get install -y curl


export K3S_TOKEN="THIS_IS_MY_SECRET_TOKEN_FOR_IOT_PROJECT"

export INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --bind-address 192.168.56.110 --advertise-address 192.168.56.110"

echo "K3s server kuruluyor..."
curl -sfL https://get.k3s.io | sh -


echo "kubectl yapılandırması yapılıyor..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "Server kurulumu tamamlandı."