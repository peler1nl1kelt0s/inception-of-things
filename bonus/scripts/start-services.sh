#!/bin/bash
# Inception-of-Things - Servis Başlatma Scripti

set -e

# --- Renkler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Servisler başlatılıyor...${NC}"

# Önceki port forwarding işlemlerini temizle
echo -e "${YELLOW}Önceki port forwarding işlemleri temizleniyor...${NC}"
pkill -f "kubectl port-forward" || true
sleep 3

# Ağ bağlantılarının hazır olmasını bekle
echo -e "${YELLOW}Ağ bağlantıları kontrol ediliyor...${NC}"
sleep 5

# GitLab port forwarding başlat
echo -e "${YELLOW}GitLab port forwarding başlatılıyor (8080:8080)...${NC}"
nohup kubectl port-forward -n gitlab svc/gitlab-webservice-default 8080:8080 --address 0.0.0.0 > /tmp/gitlab-portforward.log 2>&1 &

# ArgoCD port forwarding başlat
echo -e "${YELLOW}ArgoCD port forwarding başlatılıyor (8081:80)...${NC}"
nohup kubectl port-forward -n argocd svc/argocd-server 8081:80 --address 0.0.0.0 > /tmp/argocd-portforward.log 2>&1 &

# Başlaması için biraz bekle
sleep 10

# Port forwarding işlemlerinin çalıştığını kontrol et
echo -e "${YELLOW}Port forwarding durumu kontrol ediliyor...${NC}"
if pgrep -f "kubectl port-forward" > /dev/null; then
    echo -e "${GREEN}✓ Port forwarding işlemleri başlatıldı${NC}"
else
    echo -e "${RED}❌ Port forwarding işlemleri başlatılamadı${NC}"
    echo -e "${YELLOW}Loglar kontrol ediliyor...${NC}"
    tail -n 20 /tmp/gitlab-portforward.log || true
    tail -n 20 /tmp/argocd-portforward.log || true
    exit 1
fi

# Port forwarding durumunu göster
echo -e "${GREEN}✓ Servisler başlatıldı.${NC}"
echo -e "${CYAN}Port Forwarding Durumu:${NC}"
echo -e "  ${YELLOW}GitLab:${NC}   http://localhost:8080"
echo -e "  ${YELLOW}ArgoCD:${NC}  http://localhost:8081"
echo -e "  ${YELLOW}Uygulama:${NC} http://localhost:8888"

# Çalışan işlemleri göster
echo -e "${CYAN}Çalışan Port Forwarding İşlemleri:${NC}"
ps aux | grep "kubectl port-forward" | grep -v grep

# Host makineden erişim testi (VM içinden localhost testi)
echo -e "${YELLOW}Yerel erişim testi yapılıyor...${NC}"
curl -s --connect-timeout 10 http://localhost:8080 > /dev/null && echo -e "${GREEN}✓ GitLab erişilebilir${NC}" || echo -e "${YELLOW}⚠ GitLab henüz hazır olmayabilir${NC}"
curl -s --connect-timeout 10 http://localhost:8081 > /dev/null && echo -e "${GREEN}✓ ArgoCD erişilebilir${NC}" || echo -e "${YELLOW}⚠ ArgoCD henüz hazır olmayabilir${NC}"