#!/bin/bash

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y docker-ce

sudo usermod -aG docker ${USER}

echo "################################################################"
echo "Docker başarıyla kuruldu. Değişikliklerin etkili olması için"
echo "terminali kapatıp açın veya 'newgrp docker' komutunu çalıştırın."
echo "################################################################"


echo "kubectl kuruluyor..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
echo "kubectl başarıyla kuruldu."


echo "k3d kuruluyor..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
echo "k3d başarıyla kuruldu."

echo "Tüm kurulumlar tamamlandı!"