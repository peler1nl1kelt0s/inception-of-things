#!/usr/bin/env bash

# Renk kodları
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[SERVER] Paket listesi güncelleniyor ve bağımlılıklar kuruluyor...${NC}"
sudo apt-get update
if [ $? -ne 0 ]; then
  echo -e "${RED}[HATA] apt-get update başarısız oldu.${NC}"
  exit 1
fi

sudo apt-get install -y curl apt-transport-https ca-certificates
if [ $? -ne 0 ]; then
  echo -e "${RED}[HATA] Gerekli paketler kurulamadı.${NC}"
  exit 1
fi

echo -e "${BLUE}[SERVER] kubectl kuruluyor...${NC}"
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
if [ $? -ne 0 ]; then
  echo -e "${RED}[HATA] kubectl indirilemedi.${NC}"
  exit 1
fi

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo -e "${BLUE}[SERVER] K3s (controller modunda) kuruluyor...${NC}"
curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server \
    --write-kubeconfig-mode=644 \
    --bind-address=192.168.56.110 \
    --advertise-address=192.168.56.110 \
    --node-ip=192.168.56.110 \
    --flannel-iface=enp0s8 \
    --tls-san=192.168.56.110" sh -

if [ $? -ne 0 ]; then
  echo -e "${RED}[HATA] K3s kurulumu başarısız oldu.${NC}"
  exit 1
fi

echo -e "${BLUE}[SERVER] Worker node için token kaydediliyor...${NC}"
# Token dosyasının oluşmasını bekle (maksimum 30 saniye bekle)
for i in {1..15}; do
  if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    break
  fi
  echo "[INFO] Token dosyası bekleniyor..."
  sleep 2
done

if [ ! -f /var/lib/rancher/k3s/server/node-token ]; then
  echo -e "${RED}[HATA] node-token dosyası bulunamadı.${NC}"
  exit 1
fi

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/agent-token.env
sudo cp /var/lib/rancher/k3s/server/token /vagrant/ca.crt
echo -e "${GREEN}[SERVER] Kurulum tamamlandı. 'k' alias'ı ile kubectl kullanabilirsiniz.${NC}"
echo "alias k='sudo kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml'" >> /home/vagrant/.bashrc
echo "source /home/vagrant/.bashrc" >> /home/vagrant/.profile

