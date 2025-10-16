#!/bin/bash
# Inception-of-Things - Bonus Part - Full Automation Script with GitLab Omnibus

# --- Renkler ve Değişkenler ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

set -e # Herhangi bir komut başarısız olursa betiği durdur

# --- Genel Değişkenler ---
KUBE_NAMESPACE_ARGOCD="argocd"
KUBE_NAMESPACE_DEV="dev"
KUBE_NAMESPACE_GITLAB="gitlab"
GITLAB_URL="http://gitlab.local:8080"
GITLAB_PROJECT_NAME="iot-project-app"

# Adım 1: Gerekli araçların kurulumu
install_tools() {
    echo -e "\n${CYAN}### Adım 1: Gerekli Araçlar Kuruluyor ve Sistem Hazırlanıyor ###${NC}"
    
    # --- YENİ EKLENEN BÖLÜM: Port çakışmasını önle ---
    echo -e "${YELLOW}Port çakışmasını önlemek için Apache2 servisi durduruluyor ve kaldırılıyor...${NC}"
    sudo systemctl stop apache2 2>/dev/null || true
    sudo systemctl disable apache2 2>/dev/null || true
    sudo apt-get purge apache2 -y 2>/dev/null || true
    # ----------------------------------------------------

    sudo apt-get update && sudo apt-get install -y curl vim git ca-certificates openssh-server apt-transport-https
    
    # Docker kurulumu
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker bulunamadı, kuruluyor...${NC}"
        sudo apt-get install -y docker.io
        sudo systemctl enable --now docker
        sudo usermod -aG docker vagrant
    fi

    # K3d ve Kubectl
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Host dosyasını ayarla
    echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
    echo -e "${GREEN}✓ Araçlar başarıyla kuruldu.${NC}"
}

# Adım 2: K3d Cluster oluşturma
create_k3d_cluster() {
    echo -e "\n${CYAN}### Adım 2: K3d Cluster 'iot-cluster' Oluşturuluyor ###${NC}"
    if ! k3d cluster get iot-cluster > /dev/null 2>&1; then
        k3d cluster create iot-cluster \
            --api-port 6443 \
            -p "8888:30080@loadbalancer" \
            -p "8081:80@loadbalancer"
    else
        echo -e "${YELLOW}K3d cluster 'iot-cluster' zaten mevcut.${NC}"
    fi
    mkdir -p /home/vagrant/.kube && k3d kubeconfig get iot-cluster > /home/vagrant/.kube/config
    chown -R vagrant:vagrant /home/vagrant/.kube
    kubectl create namespace ${KUBE_NAMESPACE_DEV} 2>/dev/null || true
    echo -e "${GREEN}✓ K3d Cluster ve 'dev' namespace'i hazır.${NC}"
}

# Adım 3: GitLab Omnibus Kurulumu
install_gitlab_omnibus() {
    echo -e "\n${CYAN}### Adım 3: GitLab Omnibus Kuruluyor (Bu işlem uzun sürebilir) ###${NC}"
    
    # GitLab deposunu ekle (zaten varsa hata vermez)
    if [ ! -f /etc/apt/sources.list.d/gitlab_gitlab-ee.list ]; then
        curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
    fi
    
    # Paketi kur
    sudo apt-get install -y gitlab-ee

    echo -e "${YELLOW}GitLab yapılandırma dosyası (/etc/gitlab/gitlab.rb) oluşturuluyor...${NC}"
    
    # Yapılandırma dosyasını oluştur.
    # Bu blok, dosyanın üzerine yazar ve her seferinde temiz bir başlangıç sağlar.
    sudo bash -c "cat > /etc/gitlab/gitlab.rb" <<EOF
external_url "http://gitlab.local:8080"

puma['port'] = 9554
gitlab_workhorse['listen_network'] = "tcp"
gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
gitlab_rails['gitlab_restricted_visibility_levels'] = []
EOF

    echo -e "${GREEN}✓ Yapılandırma dosyası yazıldı.${NC}"
    echo -e "${YELLOW}GitLab yeniden yapılandırılıyor... Bu işlem birkaç dakika sürebilir.${NC}"
    
    if sudo gitlab-ctl reconfigure; then
        echo -e "${GREEN}✓ GitLab başarıyla yeniden yapılandırıldı.${NC}"
    else
        echo -e "${RED}❌ HATA: GitLab 'reconfigure' işlemi sırasında bir hata oluştu!${NC}"
        echo -e "${YELLOW}Logları kontrol edin. Kurulum durduruldu.${NC}"
        exit 1
    fi

    # GitLab'ın başlaması için kısa bir bekleme süresi
    echo -e "${YELLOW}GitLab servislerinin başlaması için 30 saniye bekleniyor...${NC}"
    sleep 30

    echo -e "${YELLOW}GitLab'in hazır olması kontrol ediliyor...${NC}"
    # GitLab hazır olana kadar bekle
    until [ "$(curl -s -o /dev/null -w "%{http_code}" http://gitlab.local:8080/users/sign_in)" == "200" ]; do
        printf '.'
        sleep 10
    done
    
    echo -e "\n${GREEN}✓ GitLab Omnibus kurulumu tamamlandı ve erişilebilir durumda.${NC}"
}
# Adım 4: Argo CD Kurulumu
install_argocd() {
    echo -e "\n${CYAN}### Adım 4: Argo CD Kuruluyor ###${NC}"
    kubectl create namespace ${KUBE_NAMESPACE_ARGOCD} 2>/dev/null || true
    kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo -e "${YELLOW}Argo CD servislerinin başlaması bekleniyor...${NC}"
    kubectl wait --for=condition=ready pod --all -n ${KUBE_NAMESPACE_ARGOCD} --timeout=300s
    
    # --- DÜZELTİLMİŞ BÖLÜM: Argo CD sunucusunu doğru şekilde yamala ---
    echo -e "${YELLOW}Argo CD sunucusu HTTP-HTTPS yönlendirmesini devre dışı bırakmak için yamalanıyor...${NC}"
    # HATALI KOMUT ŞUYDU: kubectl patch ... "path": ".../command/-" ...
    # DOĞRU KOMUT AŞAĞIDAKİDİR:
    kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

    # Argo CD Ingress'i oluştur (Port 8081'den erişim için)
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
    echo -e "${GREEN}✓ Argo CD kuruldu ve 8081 portundan erişime açıldı.${NC}"
}

# Adım 5: GitLab Projesini Otomatik Yapılandırma
configure_gitlab_project() {
    echo -e "\n${CYAN}### Adım 5: GitLab Projesi Otomatik Olarak Yapılandırılıyor ###${NC}"
    
    # GitLab'in ilk root şifresini dosyadan oku
    GITLAB_PASS=$(sudo cat /etc/gitlab/initial_root_password | grep 'Password:' | awk '{print $2}')
    
    # --- YENİ EKLENEN SATIR: Şifreyi URL uyumlu hale getir ---
    GITLAB_PASS_ENCODED=$(echo -n "$GITLAB_PASS" | python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))")

    echo -e "${YELLOW}GitLab root kullanıcısı için erişim token'ı oluşturuluyor (API için)...${NC}"
    GITLAB_TOKEN=$(sudo gitlab-rails runner "User.find(1).personal_access_tokens.where(name: 'ArgoCD Token').destroy_all; token = User.find(1).personal_access_tokens.create(scopes: ['api', 'read_repository', 'write_repository'], name: 'ArgoCD Token'); puts token.token")
    
    echo -e "${YELLOW}'${GITLAB_PROJECT_NAME}' adında yeni bir proje oluşturuluyor...${NC}"
    curl --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" -X POST "${GITLAB_URL}/api/v4/projects?name=${GITLAB_PROJECT_NAME}&visibility=public"
    
    echo -e "${YELLOW}Uygulama YAML dosyaları GitLab deposuna push ediliyor...${NC}"
    cd /vagrant/configs
    
    rm -rf .git
    
    git config --global --add safe.directory /vagrant
    git init
    git config user.name "Vagrant" && git config user.email "vagrant@example.com"
    
    # --- DEĞİŞİKLİK BURADA: URL uyumlu şifre kullanılıyor ---
    git remote add origin "http://root:${GITLAB_PASS_ENCODED}@gitlab.local:8080/root/${GITLAB_PROJECT_NAME}.git"
    
    git add application.yaml service.yaml
    git commit -m "Initial commit of iot-project application"
    
    git push -u origin master

    echo -e "${GREEN}✓ GitLab projesi başarıyla yapılandırıldı.${NC}"
}

# Adım 6: Argo CD Uygulamasını Yapılandırma
configure_argocd_app() {
    echo -e "\n${CYAN}### Adım 6: Argo CD Uygulaması Yapılandırılıyor ###${NC}"
    
    # K3d içinden host'a (Vagrant VM) erişim için IP'yi bul
    HOST_IP=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # application.yaml'daki repoURL'i dinamik olarak ayarla
    sed -i "s|repoURL:.*|repoURL: http://${HOST_IP}:8080/root/${GITLAB_PROJECT_NAME}.git|" /vagrant/configs/application.yaml
    
    echo -e "${YELLOW}Argo CD'de uygulama oluşturuluyor...${NC}"
    kubectl apply -f /vagrant/configs/application.yaml
    
    echo -e "${GREEN}✓ Argo CD uygulaması başarıyla yapılandırıldı.${NC}"
}

# --- Betiğin Ana Akışı ---
main() {
    export GITLAB_TOKEN
    install_tools
    create_k3d_cluster
    install_gitlab_omnibus
    install_argocd
    configure_gitlab_project
    configure_argocd_app

    {
        echo -e "\n${GREEN}#############################################################${NC}"
        echo -e "${GREEN}###           KURULUM BAŞARIYLA TAMAMLANDI!              ###${NC}"
        echo -e "${GREEN}#############################################################${NC}"
        echo -e "\n${CYAN}Arayüzlere Erişim Bilgileri:${NC}"
        echo -e "  ${YELLOW}GitLab Arayüzü:${NC}   ${GITLAB_URL}"
        echo -e "    Kullanıcı Adı: root"
        echo -e "    Şifre: $(sudo cat /etc/gitlab/initial_root_password | grep 'Password:' | awk '{print $2}')"
        echo -e "\n  ${YELLOW}Argo CD Arayüzü:${NC}  http://localhost:8081"
        echo -e "    Kullanıcı Adı: admin"
        echo -e "    Şifre: $(kubectl -n ${KUBE_NAMESPACE_ARGOCD} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
        echo -e "\n  ${YELLOW}Uygulama:${NC}          http://localhost:8888"
        echo -e "\n${YELLOW}Kurulum tamamlandı! Argo CD'nin uygulamayı senkronize etmesi birkaç dakika sürebilir.${NC}"
    } | tee login.txt
}

# Betiği başlat
main