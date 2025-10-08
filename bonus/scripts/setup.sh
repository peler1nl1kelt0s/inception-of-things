#!/bin/bash
# Inception-of-Things - Ana Kurulum Scripti

set -e

# --- Renkler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Scriptlerin bulunduğu dizin - VAGRANT İÇİN DÜZELTME
SCRIPT_DIR="/vagrant/scripts"
BASE_DIR="/vagrant"

echo -e "${CYAN}Inception-of-Things Bonus Kurulumu Başlatılıyor...${NC}"

# Önce mevcut dizini ve dosyaları kontrol et
echo -e "${YELLOW}Mevcut dizin: $(pwd)${NC}"
echo -e "${YELLOW}Dizin içeriği:$(ls -la)${NC}"

# Script'leri çalıştırılabilir yap
echo -e "${YELLOW}Script dosyalarına çalıştırma izni veriliyor...${NC}"
if [ -d "$SCRIPT_DIR" ]; then
    find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    echo -e "${GREEN}✓ Scriptlere çalıştırma izni verildi${NC}"
else
    echo -e "${RED}❌ Hata: $SCRIPT_DIR dizini bulunamadı!${NC}"
    exit 1
fi

# Configs klasörünü kontrol et
if [ ! -d "$BASE_DIR/configs" ]; then
    echo -e "${RED}❌ Hata: configs klasörü bulunamadı!${NC}"
    echo -e "${YELLOW}BASE_DIR içeriği:$(ls -la "$BASE_DIR/")${NC}"
    exit 1
fi

# Her bir script için dosya varlığını kontrol et
check_script() {
    local script="$1"
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        echo -e "${RED}❌ Hata: $script bulunamadı!${NC}"
        echo -e "${YELLOW}Aranan yol: $SCRIPT_DIR/$script${NC}"
        echo -e "${YELLOW}Mevcut scriptler:$(ls -la "$SCRIPT_DIR/")${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $script bulundu${NC}"
}

# Adım 1: Araçları kur
echo -e "\n${CYAN}### Adım 1: Araçlar Kuruluyor ###${NC}"
check_script "install-tools.sh"
cd "$SCRIPT_DIR" && ./install-tools.sh

# Adım 2: K3D cluster oluştur
echo -e "\n${CYAN}### Adım 2: K3D Cluster Oluşturuluyor ###${NC}"
check_script "k3d-setup.sh"
cd "$SCRIPT_DIR" && ./k3d-setup.sh

# Adım 3: GitLab kur
echo -e "\n${CYAN}### Adım 3: GitLab Kuruluyor ###${NC}"
check_script "gitlab-setup.sh"
cd "$SCRIPT_DIR" && ./gitlab-setup.sh

# Adım 4: ArgoCD kur
echo -e "\n${CYAN}### Adım 4: ArgoCD Kuruluyor ###${NC}"
check_script "argocd-setup.sh"
cd "$SCRIPT_DIR" && ./argocd-setup.sh

# Adım 5: Servisleri başlat
echo -e "\n${CYAN}### Adım 5: Servisler Başlatılıyor ###${NC}"
check_script "start-services.sh"
cd "$SCRIPT_DIR" && ./start-services.sh

# Adım 6: Projeyi yapılandır (GitLab hazır olana kadar bekle)
echo -e "\n${CYAN}### Adım 6: Proje Yapılandırılıyor ###${NC}"
check_script "configure-project.sh"

echo -e "${YELLOW}GitLab'ın hazır olması bekleniyor...${NC}"

# GitLab'ın hazır olmasını bekle (maksimum 15 deneme)
MAX_RETRIES=15
RETRY_COUNT=0
until curl -s -f "http://localhost:8080" > /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${RED}❌ Hata: GitLab zaman aşımına uğradı!${NC}"
        echo -e "${YELLOW}Son durum kontrolü:${NC}"
        kubectl get pods -n gitlab
        exit 1
    fi
    echo "GitLab henüz hazır değil, 30 saniye bekleniyor... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 30
done

cd "$SCRIPT_DIR" && ./configure-project.sh

# Kurulum tamamlandı
echo -e "\n${GREEN}#############################################################${NC}"
echo -e "${GREEN}###           KURULUM BAŞARIYLA TAMAMLANDI!              ###${NC}"
echo -e "${GREEN}#############################################################${NC}"

# Şifreleri göster
echo -e "\n${CYAN}Erişim Bilgileri:${NC}"
echo -e "  ${YELLOW}GitLab:${NC}   http://localhost:8080"
GITLAB_PASSWORD=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode || echo "Henüz hazır değil")
echo -e "    Kullanıcı: ${GREEN}root${NC}"
echo -e "    Şifre: ${GREEN}$GITLAB_PASSWORD${NC}"

echo -e "\n  ${YELLOW}ArgoCD:${NC}  http://localhost:8081"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode || echo "Henüz hazır değil")
echo -e "    Kullanıcı: ${GREEN}admin${NC}"
echo -e "    Şifre: ${GREEN}$ARGOCD_PASSWORD${NC}"

echo -e "\n  ${YELLOW}Uygulama:${NC} http://localhost:8888"

echo -e "\n${YELLOW}Not:${NC} Tüm servislerin tamamen hazır olması birkaç dakika sürebilir."
echo -e "${YELLOW}Port forwarding arka planda çalışıyor.${NC}"

# Servis durumlarını göster
echo -e "\n${CYAN}Servis Durumları:${NC}"
kubectl get pods -A