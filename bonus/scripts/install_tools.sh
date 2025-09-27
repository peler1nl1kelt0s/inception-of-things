#!/bin/bash
set -e
echo ">>>> Sistem güncelleniyor..."
sudo apt-get update -y
echo ">>>> Gerekli paketler kuruluyor..."
sudo apt-get install -y curl apt-transport-https ca-certificates software-properties-common git

echo ">>>> Docker kuruluyor..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker vagrant

echo ">>>> kubectl kuruluyor..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

echo ">>>> k3d kuruluyor..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo ">>>> Helm kuruluyor..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

echo -e "\n\033[0;32m>>>> Tüm temel araçların kurulumu tamamlandı!\033[0m"