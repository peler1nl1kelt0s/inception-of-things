#!/bin/bash
set -e

CLUSTER_NAME=${1:-inception}

echo "############################################################"
echo "#               Gerekli Paketler Kuruluyor                 #"
echo "############################################################"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg

echo "############################################################"
echo "#                   Docker Kuruluyor                       #"
echo "############################################################"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "############################################################"
echo "#                  kubectl Kuruluyor                       #"
echo "############################################################"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "############################################################"
echo "#                    k3d Kuruluyor                         #"
echo "############################################################"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "############################################################"
echo "#           '${CLUSTER_NAME}' adında k3d Cluster Oluşturuluyor         #"
echo "############################################################"
k3d cluster create ${CLUSTER_NAME}