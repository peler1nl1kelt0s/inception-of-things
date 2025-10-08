#!/bin/bash
# Inception-of-Things - GitLab Helm Kurulum Scripti

set -e

# --- Renkler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}GitLab Helm ile kuruluyor...${NC}"

# Değişkenler
KUBE_NAMESPACE_GITLAB="gitlab"
VALUES_FILE="/vagrant/configs/gitlab-values.yaml"

# Helm repo ekle
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Values dosyasının var olduğunu kontrol et
if [ ! -f "$VALUES_FILE" ]; then
    echo -e "${RED}❌ Hata: $VALUES_FILE dosyası bulunamadı!${NC}"
    exit 1
fi

echo -e "${YELLOW}GitLab values.yaml dosyası kullanılarak kurulum yapılıyor...${NC}"

# GitLab'i kur
helm upgrade --install gitlab gitlab/gitlab \
    -f ${VALUES_FILE} \
    --namespace ${KUBE_NAMESPACE_GITLAB} \
    --timeout 600s

echo -e "${YELLOW}GitLab pod'larının başlaması bekleniyor...${NC}"

if kubectl wait --for=condition=ready pod -l app=webservice -n ${KUBE_NAMESPACE_GITLAB} --timeout=900s; then
    echo -e "${GREEN}✓ GitLab webservice pod'u hazır.${NC}"
else
    echo -e "${RED}❌ GitLab webservice pod'u zaman aşımına uğradı${NC}"
    echo -e "${YELLOW}Pod durumu:${NC}"
    kubectl get pods -n gitlab
    exit 1
fi

# Son kontrol
if kubectl wait --for=condition=ready pod -l app=webservice -n ${KUBE_NAMESPACE_GITLAB} --timeout=30s 2>/dev/null; then
    echo -e "${GREEN}✓ GitLab pod'ları hazır.${NC}"
else
    echo -e "${YELLOW}⚠ GitLab pod'ları hala hazırlanıyor, kurulum devam ediyor...${NC}"
fi

echo -e "${GREEN}✓ GitLab başarıyla kuruldu.${NC}"
echo -e "${YELLOW}GitLab pod durumu:${NC}"
kubectl get pods -n gitlab