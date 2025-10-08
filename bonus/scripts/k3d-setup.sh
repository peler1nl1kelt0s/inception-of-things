#!/bin/bash

set -e

echo "K3D cluster kurulumu başlatılıyor..."

# Eski cluster varsa sil
k3d cluster delete iot-cluster || true

# Yeni cluster oluştur
k3d cluster create iot-cluster \
    --api-port 6443 \
    -p "80:80@loadbalancer" \
    -p "443:443@loadbalancer" \
    -p "8888:30080@loadbalancer" \
    --agents 2 \
    --wait

# Kubeconfig'i ayarla
mkdir -p /home/vagrant/.kube
k3d kubeconfig get iot-cluster > /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Namespace'leri oluştur
kubectl create namespace dev || true
kubectl create namespace gitlab || true
kubectl create namespace argocd || true

echo "K3D cluster kurulumu tamamlandı."