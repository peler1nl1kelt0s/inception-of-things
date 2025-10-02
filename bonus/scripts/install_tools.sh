#!/bin/bash
# Bu betik, Vagrant sanal makinesi için gerekli olan tüm temel
# geliştirme araçlarını (Docker, kubectl, k3d, Helm) kurar.

# Herhangi bir komut başarısız olursa betiği anında sonlandır
set -e

# Renk kodları ve yardımcı fonksiyon
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Başlıkları formatlı yazdırmak için bir fonksiyon
print_header() {
    echo -e "\n${YELLOW}### ${1} ###${NC}"
}

# --- Sistem Hazırlığı ---
print_header "Sistem Hazırlanıyor"

# apt-get komutlarının etkileşimli soru sormasını engelle
export DEBIAN_FRONTEND=noninteractive

echo ">>>> Paket listesi güncelleniyor..."
sudo apt-get update -y

echo ">>>> Temel bağımlılıklar kuruluyor..."
sudo apt-get install -y curl apt-transport-https ca-certificates software-properties-common git

# --- Docker Kurulumu ---
print_header "Docker Kurulumu"

if ! command -v docker &> /dev/null; then
    echo ">>>> Docker bulunamadı, kurulum başlıyor..."
    # Gerekli keyring dizinini oluştur
    sudo install -m 0755 -d /etc/apt/keyrings

    # Docker'ın GPG anahtarını indir ve doğru yere kaydet
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Docker deposunu APT kaynaklarına ekle
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # APT deposunu güncelle ve Docker'ı kur
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 'vagrant' kullanıcısını docker grubuna ekle
    sudo usermod -aG docker vagrant
    echo -e "${GREEN}Docker başarıyla kuruldu.${NC}"
else
    echo -e "${GREEN}Docker zaten kurulu.${NC}"
fi


# --- kubectl Kurulumu ---
print_header "kubectl Kurulumu"

if ! command -v kubectl &> /dev/null; then
    echo ">>>> kubectl bulunamadı, kurulum başlıyor..."
    KUBECTL_STABLE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_STABLE_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}kubectl başarıyla kuruldu.${NC}"
else
    echo -e "${GREEN}kubectl zaten kurulu.${NC}"
fi


# --- k3d Kurulumu ---
print_header "k3d Kurulumu"

if ! command -v k3d &> /dev/null; then
    echo ">>>> k3d bulunamadı, kurulum başlıyor..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo -e "${GREEN}k3d başarıyla kuruldu.${NC}"
else
    echo -e "${GREEN}k3d zaten kurulu.${NC}"
fi


# --- Helm Kurulumu ---
print_header "Helm Kurulumu"

if ! command -v helm &> /dev/null; then
    echo ">>>> Helm bulunamadı, kurulum başlıyor..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm ./get_helm.sh
    echo -e "${GREEN}Helm başarıyla kuruldu.${NC}"
else
    echo -e "${GREEN}Helm zaten kurulu.${NC}"
fi


echo -e "\n${GREEN}################################################"
echo -e "### TÜM TEMEL ARAÇLARIN KURULUMU TAMAMLANDI ###"
echo -e "################################################${NC}"