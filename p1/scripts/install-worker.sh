#!/usr/bin/env bash
set -e

# Renk kodları
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${CYAN}[WORKER] Paket listesi güncelleniyor ve bağımlılıklar kuruluyor...${NC}"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y curl > /dev/null 2>&1

echo -e "${CYAN}[WORKER] Server'dan gelen node token bekleniyor...${NC}"
while [ ! -f /vagrant/agent-token.env ]; do
  sleep 2
done
echo -e "${CYAN}[WORKER] Token bulundu!${NC}"

echo -e "${CYAN}[WORKER] K3s (agent modunda) kuruluyor ve cluster'a katılıyor...${NC}"
export K3S_URL="https://192.168.56.110:6443"
export K3S_TOKEN=$(cat /vagrant/agent-token.env)
export INSTALL_K3S_EXEC="--node-ip=192.168.56.111"
curl -sfL https://get.k8s.io | sh -s - > /dev/null 2>&1

echo -e "${GREEN}[WORKER] Kurulum tamamlandı ve cluster'a başarıyla katıldı.${NC}"
