#!/bin/bash
# setup.sh dosyasının son ve düzeltilmiş hali

# Herhangi bir komut başarısız olursa betiği anında sonlandır
set -e

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Adım 0: DNS Sorununu Düzeltme ---
# VM içindeki DNS çözümleme sorunlarını engellemek için Google DNS'i ayarla
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo -e "${GREEN}DNS sunucusu 8.8.8.8 olarak ayarlandı.${NC}"

# --- Adım 1: Gerekli Araçları Kurma ---
echo -e "\n${CYAN}### Adım 1: Gerekli Araçları Kurma ###${NC}"
chmod +x /vagrant/scripts/install_tools.sh
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
if ! k3d cluster get iot-cluster > /dev/null 2>&1; then
  echo "K3d kümesi 'iot-cluster' oluşturuluyor..."
  k3d cluster create iot-cluster --api-port 6443 -p "8080:80@loadbalancer" -p "8888:30080@loadbalancer" --agents 1
else
  echo -e "${YELLOW}K3d kümesi 'iot-cluster' zaten mevcut.${NC}"
fi

echo -e "\n${CYAN}### Adım 3: Gerekli Namespace'leri Oluşturma ###${NC}"
kubectl create namespace ${KUBE_NAMESPACE_ARGOCD} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${KUBE_NAMESPACE_DEV} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${KUBE_NAMESPACE_GITLAB} --dry-run=client -o yaml | kubectl apply -f -

echo -e "\n${CYAN}### Adım 4: Argo CD Kurulumu ###${NC}"
kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${YELLOW}Kubernetes kaynaklarının oluşturulması için 15 saniye bekleniyor...${NC}"
sleep 15

echo -e "${YELLOW}Argo CD sunucusunun başlaması bekleniyor...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${KUBE_NAMESPACE_ARGOCD} --timeout=300s

echo -e "\n${CYAN}### Adım 5: GitLab Kurulumu (Bu adım 20-30 dakika sürebilir) ###${NC}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace ${KUBE_NAMESPACE_GITLAB} \
  -f /vagrant/configs/gitlab-values.yaml \
  --timeout 45m \
  --wait

echo -e "\n${CYAN}### Adım 6: GitLab Projesini Otomatik Oluşturma ve Kodu PUSH'lama ###${NC}"
GITLAB_PASSWORD=$(kubectl get secret -n ${KUBE_NAMESPACE_GITLAB} gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d)
TOOLBOX_POD=$(kubectl get pods -n ${KUBE_NAMESPACE_GITLAB} -lapp=toolbox -o name)

echo "GitLab projesi '${PROJECT_NAME}' oluşturuluyor..."
kubectl exec -n ${KUBE_NAMESPACE_GITLAB} ${TOOLBOX_POD} -- gitlab-rails runner - <<'RUBY_SCRIPT'
user = User.find_by(username: 'root')
params = {
  name: 'iot-project-app',
  path: 'iot-project-app',
  namespace_id: user.namespace.id,
  visibility_level: Gitlab::VisibilityLevel::PUBLIC
}
project = Project.find_by_full_path("root/iot-project-app")
if project.nil?
  Projects::CreateService.new(user, params).execute
  puts "Proje 'iot-project-app' başarıyla oluşturuldu."
else
  puts "Proje 'iot-project-app' zaten mevcut."
end
RUBY_SCRIPT

echo -e "${YELLOW}GitLab webservice pod'larının hazır olması bekleniyor...${NC}"
kubectl wait --for=condition=Available deployment -lapp=webservice -n ${KUBE_NAMESPACE_GITLAB} --timeout=300s

echo -e "${YELLOW}GitLab Gitaly pod'larının hazır olması bekleniyor (Git deposu servisi)...${NC}"
kubectl wait --for=condition=Ready pod -lapp=gitaly -n ${KUBE_NAMESPACE_GITLAB} --timeout=300s
echo -e "${GREEN}GitLab servisleri hazır.${NC}"

GITLAB_HOST="gitlab.local"
if ! grep -q "${GITLAB_HOST}" /etc/hosts; then
  echo "127.0.0.1 ${GITLAB_HOST}" | sudo tee -a /etc/hosts
  echo -e "${YELLOW}${GITLAB_HOST} adresi /etc/hosts dosyasına eklendi.${NC}"
fi

echo "Uygulama kodları GitLab'e gönderiliyor..."
cd /tmp
rm -rf ${PROJECT_NAME}

CLONE_URL="http://${GITLAB_HOST}:8080/root/${PROJECT_NAME}.git"
PUSH_URL="http://root:${GITLAB_PASSWORD}@${GITLAB_HOST}:8080/root/${PROJECT_NAME}.git"

echo -e "${YELLOW}Git deposunun arka planda oluşturulması bekleniyor...${NC}"
for i in {1..15}; do
  if git ls-remote --exit-code ${CLONE_URL} > /dev/null 2>&1; then
    echo -e "${GREEN}Depo erişilebilir durumda! Klonlama işlemine başlanıyor.${NC}"
    git clone ${CLONE_URL}
    cd ${PROJECT_NAME}
    break
  else
    echo "Depo henüz hazır değil. Deneme ${i}/15. 10 saniye sonra tekrar denenecek."
    sleep 10
  fi

  if [ "$i" -eq 15 ]; then
    echo -e "\nHATA: Depo 2.5 dakika içinde erişilebilir hale gelmedi. Kurulum durduruluyor."
    exit 1
  fi
done

rm -f README.md
cp /vagrant/configs/deployment.yaml .
cp /vagrant/configs/service.yaml .

echo "Değişiklikler GitLab deposuna gönderiliyor..."
git config --global user.email "admin@example.com"
git config --global user.name "Administrator"
git add .
git commit -m "Initial application manifests"
git push ${PUSH_URL}

echo -e "\n${CYAN}### Adım 7: Argo CD Uygulamasını Dağıtma ###${NC}"
kubectl apply -f /vagrant/configs/application.yaml

EOF

echo -e "\n${GREEN}#############################################################${NC}"
echo -e "${GREEN}### KURULUM BAŞARIYLA TAMAMLANDI! ###${NC}"
echo -e "Arayüzlere erişim için Host (ana) makinenizdeki port yönlendirmelerini kullanın:"
echo -e "\n${YELLOW}Argo CD Arayüzü:${NC} http://localhost:8080"
echo -e "${YELLOW}GitLab Arayüzü:${NC}  http://gitlab.local:8080"
echo -e "${YELLOW}Uygulama:${NC}         http://localhost:8888"
echo -e "\n${CYAN}ÖNEMLİ NOT:${NC} GitLab arayüzüne tarayıcıdan erişmek için, ana bilgisayarınızın"
echo -e "(Windows, Mac veya Linux) 'hosts' dosyasına şu satırı eklemeniz gerekir:"
echo -e "${GREEN}127.0.0.1 gitlab.local${NC}"
echo -e "\nŞifreleri almak için VM'e 'vagrant ssh' ile bağlanıp aşağıdaki komutları çalıştırabilirsiniz:"
echo -e "  ${CYAN}Argo CD şifresi:${NC} kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo -e "  ${CYAN}GitLab root şifresi:${NC} kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d"
echo -e "${GREEN}#############################################################${NC}"