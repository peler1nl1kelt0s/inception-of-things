#!/bin/bash

apt-get update -y

apt-get install -y curl


export K3S_URL="https://192.168.56.110:6443"
export K3S_TOKEN=$(cat /vagrant/agent-token.env)

export INSTALL_K3S_EXEC="agent --node-ip 192.168.56.111"

echo "K3s agent kuruluyor..."

sleep 10
curl -sfL https://get.k3s.io | sh -

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "alias k='sudo kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml'" >> /home/vagrant/.bashrc
echo "source /home/vagrant/.bashrc" >> /home/vagrant/.profile 
echo "Agent kurulumu tamamlandı."