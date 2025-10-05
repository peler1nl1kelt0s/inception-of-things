#!/bin/bash

apt-get update -y

apt-get install -y curl

export INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --bind-address 192.168.56.110 --advertise-address 192.168.56.110"

echo "K3s server kuruluyor..."
curl -sfL https://get.k3s.io | sh -


echo "kubectl yapılandırması yapılıyor..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/agent-token.env
sudo cp /var/lib/rancher/k3s/server/token /vagrant/ca.crt

echo "alias k='sudo kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml'" >> /home/vagrant/.bashrc
echo "source /home/vagrant/.bashrc" >> /home/vagrant/.profile

echo "Server kurulumu tamamlandı."