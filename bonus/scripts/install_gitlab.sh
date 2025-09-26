#!/bin/bash

# Herhangi bir komut başarısız olursa betiği sonlandır
set -e

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
KUBE_NAMESPACE_GITLAB="gitlab"

echo -e "\n${GREEN}[INFO] GitLab Helm deposu ekleniyor...${NC}"
helm repo add gitlab https://charts.gitlab.io/ >/dev/null 2>&1
helm repo update

echo -e "\n${YELLOW}[INFO] Helm ile GitLab kurulumu başlatılıyor...${NC}"
echo -e "${YELLOW}Bu işlem 15-25 dakika sürebilir, lütfen sabırlı olun (terasta hava al😌) ${NC}"

helm install gitlab gitlab/gitlab \
  --namespace ${KUBE_NAMESPACE_GITLAB} \
  -f bonus/configs/gitlab-values.yaml \
  --timeout 20m \
  --wait

echo -e "\n${GREEN}[SUCCESS] GitLab kurulumu başarıyla tamamlandı.${NC}"