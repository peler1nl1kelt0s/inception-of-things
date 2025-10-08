#!/bin/bash
# Inception-of-Things - Araç Kurulum Scripti

set -e

# --- Renkler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Gerekli araçlar kuruluyor...${NC}"

# Sistem güncellemeleri
sudo apt-get update && sudo apt-get upgrade -y

# Mevcut servisleri temizle
echo -e "${YELLOW}Port çakışmasını önlemek için Apache2 kaldırılıyor...${NC}"
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl disable apache2 2>/dev/null || true
sudo apt-get purge apache2 -y 2>/dev/null || true

# Temel araçlar
sudo apt-get install -y curl wget vim git ca-certificates openssh-server apt-transport-https python3-pip

# Docker kurulumu
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker kuruluyor...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    sudo usermod -aG docker vagrant
fi

# K3d kurulumu
if ! command -v k3d &> /dev/null; then
    echo -e "${YELLOW}K3d kuruluyor...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Kubectl kurulumu
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Kubectl kuruluyor...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Helm kurulumu
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Helm kuruluyor...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Hosts ayarı
echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts

echo -e "${GREEN}✓ Tüm araçlar başarıyla kuruldu.${NC}"