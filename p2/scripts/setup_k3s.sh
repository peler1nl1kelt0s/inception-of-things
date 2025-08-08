#!/bin/bash

sudo apt-get update
sudo apt-get install -y curl #? uygulamalar kurulduktan sonra, test etmek icin kullanilacak

#? server modunda kuruyorum
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode "644"

echo "K3s sunucu modunda başarıyla kuruldu."
echo "kubeconfig dosyası /etc/rancher/k3s/k3s.yaml konumunda."

mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config