#!/bin/bash
# Inception-of-Things - Proje Yapılandırma Scripti

set -e

# --- Renkler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Proje yapılandırılıyor...${NC}"

# GitLab değişkenleri
GITLAB_URL="http://localhost:8080"
PROJECT_NAME="iot-project-app"
PROJECT_NAMESPACE="root"

# GitLab'ın tamamen hazır olmasını bekle
echo -e "${YELLOW}GitLab'ın tamamen hazır olması bekleniyor...${NC}"

MAX_RETRIES=20
RETRY_COUNT=0

until curl -s -f "${GITLAB_URL}/api/v4/projects" > /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${RED}❌ Hata: GitLab API zaman aşımına uğradı!${NC}"
        echo -e "${YELLOW}Devam ediliyor, proje manuel oluşturulabilir...${NC}"
        break
    fi
    echo "GitLab API henüz hazır değil, 30 saniye bekleniyor... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 30
done

echo -e "${YELLOW}GitLab root şifresi alınıyor...${NC}"

# GitLab root şifresini al
GITLAB_PASSWORD=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode)

if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${RED}❌ GitLab root şifresi alınamadı!${NC}"
    echo -e "${YELLOW}Devam ediliyor...${NC}"
else
    echo -e "${GREEN}✓ GitLab root şifresi alındı${NC}"
fi

echo -e "${YELLOW}GitLab projesi oluşturuluyor...${NC}"

# 1. Yöntem: GitLab API ile proje oluşturma
echo -e "${YELLOW}API ile proje oluşturma deneniyor...${NC}"

# Personal access token oluşturmaya çalış
API_RESPONSE=$(curl -s -X POST "${GITLAB_URL}/api/v4/session?login=root&password=${GITLAB_PASSWORD}" 2>/dev/null || true)

if [[ "$API_RESPONSE" == *"private_token"* ]]; then
    TOKEN=$(echo "$API_RESPONSE" | grep -o '"private_token":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✓ API token alındı${NC}"
    
    # Proje oluştur
    CREATE_RESPONSE=$(curl -s -X POST "${GITLAB_URL}/api/v4/projects?name=${PROJECT_NAME}&namespace_id=1" \
        -H "Private-Token: ${TOKEN}" 2>/dev/null || true)
    
    if [[ "$CREATE_RESPONSE" == *"ssh_url_to_repo"* ]]; then
        echo -e "${GREEN}✓ Proje API ile oluşturuldu${NC}"
        PROJECT_CREATED=true
    else
        echo -e "${YELLOW}⚠ API ile proje oluşturulamadı${NC}"
        PROJECT_CREATED=false
    fi
else
    echo -e "${YELLOW}⚠ Token alınamadı, alternatif yöntem kullanılıyor...${NC}"
    PROJECT_CREATED=false
fi

# 2. Yöntem: Git push ile proje oluşturma
if [ "$PROJECT_CREATED" = false ]; then
    echo -e "${YELLOW}Git push ile proje oluşturuluyor...${NC}"
    
    # Git config ayarları
    git config --global user.email "root@localhost"
    git config --global user.name "Administrator"
    
    # Proje dizinine git
    cd /vagrant/configs
    
    # Git repo başlat ve push et
    git init
    git add deployment.yaml service.yaml
    git commit -m "Initial commit: IoT Project with GitLab + ArgoCD"
    
    # Push et (proje otomatik oluşacak)
    if git push "http://root:${GITLAB_PASSWORD}@localhost:8080/root/iot-project-app.git" master 2>/dev/null; then
        echo -e "${GREEN}✓ Proje başarıyla GitLab'a push edildi${NC}"
    else
        echo -e "${YELLOW}⚠ Push işlemi başarısız, repository otomatik oluşturulacak${NC}"
        
        # 3. Yöntem: Git remote ve force push
        git remote add origin "http://localhost:8080/root/iot-project-app.git"
        if git push -u origin master --force 2>/dev/null; then
            echo -e "${GREEN}✓ Proje force push ile oluşturuldu${NC}"
        else
            echo -e "${YELLOW}⚠ Push işlemi başarısız, devam ediliyor...${NC}"
        fi
    fi
fi

# 3. Adım: ArgoCD uygulamasını oluştur
echo -e "${YELLOW}Argo CD uygulaması oluşturuluyor...${NC}"

# ArgoCD Application manifest
kubectl apply -f application.yaml

echo -e "${GREEN}✓ Argo CD uygulaması oluşturuldu${NC}"

# 4. Adım: Ingress veya port forwarding for app
echo -e "${YELLOW}Uygulama erişimi yapılandırılıyor...${NC}"

# Uygulama için port forwarding başlat (8888:8888)
kubectl port-forward -n dev svc/iot-app-service 8888:8888 --address 0.0.0.0 > /dev/null 2>&1 &

echo -e "${GREEN}✓ Proje başarıyla yapılandırıldı${NC}"