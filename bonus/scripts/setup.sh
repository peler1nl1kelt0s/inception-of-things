#!/bin/bash
set -e

# --- Adım 0: DNS Sorununu Düzeltme ---
# VM içindeki DNS çözümleme sorunlarını engellemek için Google DNS'i ayarla
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo -e "${GREEN}DNS sunucusu 8.8.8.8 olarak ayarlandı.${NC}"

# --- Adım 1: Gerekli Araçları Kurma ---
echo -e "\n${CYAN}### Adım 1: Gerekli Araçları Kurma ###${NC}"
# Kurulum betiğini çalıştırılabilir yap
chmod +x /vagrant/scripts/install_tools.sh
# Betiği çalıştır
/vagrant/scripts/install_tools.sh

# --- Adım 2 ve sonrası: Vagrant Kullanıcısı Olarak Devam Etme ---
# k3d ve docker komutları 'vagrant' kullanıcısı (docker grubunda) tarafından çalıştırılmalıdır.
echo -e "\n${CYAN}>>> Kuruluma 'vagrant' kullanıcısı olarak devam ediliyor...${NC}"
sudo -u vagrant -i <<'EOF'
set -e

# Değişkenleri bu shell bloğu içine tekrar tanımla
KUBE_NAMESPACE_ARGOCD="argocd"
KUBE_NAMESPACE_DEV="dev"
KUBE_NAMESPACE_GITLAB="gitlab"
PROJECT_NAME="iot-project-app"
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\n${CYAN}### Adım 2: K3d Kümesini Oluşturma ###${NC}"
k3d cluster create iot-cluster --api-port 6443 -p "8080:80@loadbalancer" -p "8888:30080@loadbalancer" --agents 1

echo -e "\n${CYAN}### Adım 3: Gerekli Namespace'leri Oluşturma ###${NC}"
kubectl create namespace ${KUBE_NAMESPACE_ARGOCD} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${KUBE_NAMESPACE_DEV} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${KUBE_NAMESPACE_GITLAB} --dry-run=client -o yaml | kubectl apply -f -

echo -e "\n${CYAN}### Adım 4: Argo CD Kurulumu ###${NC}"
kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Zamanlama (race condition) hatasını önlemek için kısa bir bekleme ekle
echo -e "${YELLOW}Kubernetes kaynaklarının oluşturulması için 15 saniye bekleniyor...${NC}"
sleep 15

echo -e "${YELLOW}Argo CD sunucusunun başlaması bekleniyor...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${KUBE_NAMESPACE_ARGOCD} --timeout=180s

echo -e "\n${CYAN}### Adım 5: GitLab Kurulumu (Bu adım 20-30 dakika sürebilir) ###${NC}"
# Doğru Helm deposu URL'sini kullan (-mirsaddan not aşağıdaki link .io)
helm repo add gitlab https://charts.gitlab.io/ 
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace ${KUBE_NAMESPACE_GITLAB} \
  -f /vagrant/configs/gitlab-values.yaml \
  --timeout 30m \
  --wait

echo -e "\n${CYAN}### Adım 6: GitLab Projesini Otomatik Oluşturma ve Kodu PUSH'lama ###${NC}"
# Şifreyi al
GITLAB_PASSWORD=$(kubectl get secret -n ${KUBE_NAMESPACE_GITLAB} gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d)
# GitLab Toolbox pod'unu bul
TOOLBOX_POD=$(kubectl get pods -n ${KUBE_NAMESPACE_GITLAB} -lapp=toolbox -o name)

# Projeyi, modern ve tüm doğrulamaları yapan 'Projects::CreateService' ile oluştur
echo "GitLab projesi '${PROJECT_NAME}' oluşturuluyor..."
kubectl exec -n ${KUBE_NAMESPACE_GITLAB} ${TOOLBOX_POD} -- gitlab-rails runner - <<'RUBY_SCRIPT'
user = User.find_by(username: 'root')
params = {
  name: 'iot-project-app',
  path: 'iot-project-app',
  namespace_id: user.namespace.id,
  visibility_level: Gitlab::VisibilityLevel::PUBLIC
}
# Proje zaten varsa hata verme, yoksa oluştur
project = Project.find_by_full_path("root/iot-project-app")
if project.nil?
  Projects::CreateService.new(user, params).execute
  puts "Proje 'iot-project-app' başarıyla oluşturuldu."
else
  puts "Proje 'iot-project-app' zaten mevcut."
end
RUBY_SCRIPT

# --- ESAD NOT: sleep 200 yerine kubectl wait ile podlarin kurulmasi bekleniliyor
echo -e "${YELLOW}GitLab webservice pod'larının hazır olması bekleniyor...${NC}"
# GitLab'in webservice deployment'ı tamamen hazır olana kadar bekle (timeout 5 dakika)
kubectl wait --for=condition=Available deployment -lapp=webservice -n ${KUBE_NAMESPACE_GITLAB} --timeout=300s

echo -e "${YELLOW}GitLab Gitaly pod'larının hazır olması bekleniyor (Git deposu servisi)...${NC}"
# Gitaly (Git işlemlerini yöneten servis) hazır olana kadar bekle
kubectl wait --for=condition=Ready pod -lapp=gitaly -n ${KUBE_NAMESPACE_GITLAB} --timeout=300s

echo -e "${GREEN}GitLab servisleri hazır. Klonlama işlemine başlanıyor.${NC}"
# -----------------------------

# Kodu push'lamak için geçici bir klon oluştur
echo "Uygulama kodları GitLab'e gönderiliyor..."
cd /tmp
# Eğer klasör varsa temizle
rm -rf ${PROJECT_NAME}
# ADRESİ localhost:8080 OLARAK DEĞİŞTİRİN - portları değiştirdim (güncelleme)
git clone http://localhost:8080/root/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
# Eski dosyaları silip yenilerini kopyala
rm -f README.md
cp /vagrant/configs/deployment.yaml .
cp /vagrant/configs/service.yaml .
# Kodu push'la
git config --global user.email "admin@example.com"
git config --global user.name "Administrator"
git add .
git commit -m "Initial application manifests"
git push http://root:${GITLAB_PASSWORD}@localhost:8080/root/${PROJECT_NAME}.git

echo -e "\n${CYAN}### Adım 7: Argo CD Uygulamasını Dağıtma ###${NC}"
kubectl apply -f /vagrant/configs/application.yaml

EOF

echo -e "\n${GREEN}#############################################################${NC}"
echo -e "${GREEN}### KURULUM BAŞARIYLA TAMAMLANDI! ###${NC}"
echo -e "Arayüzlere erişim için Host (ana) makinenizdeki port yönlendirmelerini kullanın:"
echo -e "\n${YELLOW}Argo CD Arayüzü:${NC} http://localhost:8080"
echo -e "${YELLOW}GitLab Arayüzü:${NC}  http://localhost:10080"
echo -e "${YELLOW}Uygulama:${NC}         http://localhost:8888"
echo -e "\nŞifreleri almak için VM'e 'vagrant ssh' ile bağlanıp aşağıdaki komutları çalıştırabilirsiniz:"
echo -e "  ${CYAN}Argo CD şifresi:${NC} kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo -e "  ${CYAN}GitLab root şifresi:${NC} kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d"
echo -e "${GREEN}#############################################################${NC}"