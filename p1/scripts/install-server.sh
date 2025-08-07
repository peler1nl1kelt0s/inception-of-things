#!/usr/bin/env bash
set -e

BLUE='\033[1;34m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${BLUE}[SERVER] Paket listesi güncelleniyor ve bağımlılıklar kuruluyor...${NC}"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y curl apt-transport-https ca-certificates > /dev/null 2>&1

echo -e "${BLUE}[SERVER] kubectl kuruluyor...${NC}"
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo -e "${BLUE}[SERVER] K3s (controller modunda) kuruluyor...${NC}"
export INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 \
  --bind-address=192.168.56.110 \
  --advertise-address=192.168.56.110 \
  --node-ip=192.168.56.110"
curl -sfL https://get.k8s.io | sh -s - > /dev/null 2>&1

echo -e "${BLUE}[SERVER] Worker node için token kaydediliyor...${NC}"
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/agent-token.env

echo -e "${GREEN}[SERVER] Kurulum tamamlandı. 'k' alias'ı ile kubectl kullanabilirsiniz.${NC}"
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
