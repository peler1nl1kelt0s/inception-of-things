#!/bin/bash
# setup.sh - v11.2

set -e
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

# --- Root kontrolü ve vagrant kullanıcısına geçiş ---
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}Root olarak çalışıyorsunuz, vagrant kullanıcısına geçiliyor...${NC}"
    echo "nameserver 8.8.8.8" | tee /etc/resolv.conf > /dev/null
    chmod +x /vagrant/scripts/install_tools.sh && /vagrant/scripts/install_tools.sh
    exec su - vagrant -c "bash $0"
    exit 0
fi

echo -e "${CYAN}>>> Kuruluma 'vagrant' kullanıcısı olarak devam ediliyor...${NC}"

KUBE_NAMESPACE_ARGOCD="argocd"
KUBE_NAMESPACE_DEV="dev"
KUBE_NAMESPACE_GITLAB="gitlab"

# --- Adım 2: K3d Kümesini Oluşturma ve kubectl Yetkilerini Ayarlama ---
echo -e "\n${CYAN}### Adım 2: K3d Kümesini Oluşturma ve kubectl Yetkilerini Ayarlama ###${NC}"
if ! k3d cluster get iot-cluster > /dev/null 2>&1; then
  echo "K3d kümesi 'iot-cluster' oluşturuluyor..."
  k3d cluster create iot-cluster --api-port 6443 -p "8080:80@loadbalancer" -p "8888:30080@loadbalancer" --agents 1 --k3s-arg "--disable=traefik@server:0"
else
  echo -e "${YELLOW}K3d kümesi 'iot-cluster' zaten mevcut.${NC}"
fi

echo -e "${CYAN}>>> 'vagrant' kullanıcısı için kubectl erişimi yapılandırılıyor...${NC}"
mkdir -p "${HOME}/.kube"
k3d kubeconfig get iot-cluster > "${HOME}/.kube/config"
sudo chown -R "$(id -u)":"$(id -g)" "${HOME}/.kube"
chmod 600 "${HOME}/.kube/config"

echo -e "${YELLOW}>>> kubectl erişimi test ediliyor...${NC}"
if kubectl get nodes &> /dev/null; then echo -e "${GREEN}✓ kubectl erişim testi başarılı!${NC}"; else echo -e "${RED}HATA: kubectl erişemiyor!${NC}"; exit 1; fi
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# --- Adım 3: Gerekli Namespace'leri Oluşturma ---
echo -e "\n${CYAN}### Adım 3: Gerekli Namespace'leri Oluşturma ###${NC}"
for ns in ${KUBE_NAMESPACE_ARGOCD} ${KUBE_NAMESPACE_DEV} ${KUBE_NAMESPACE_GITLAB}; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# --- Adım 4: Argo CD Kurulumu ---
echo -e "\n${CYAN}### Adım 4: Argo CD Kurulumu ###${NC}"
kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo -e "${YELLOW}Argo CD servislerinin başlaması bekleniyor...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${KUBE_NAMESPACE_ARGOCD} --timeout=300s

# --- Adım 5: GitLab Kurulumu ---
echo -e "\n${CYAN}### Adım 5: GitLab Kurulumu ###${NC}"
helm repo add gitlab https://charts.gitlab.io/ > /dev/null 2>&1 || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace ${KUBE_NAMESPACE_GITLAB} \
  -f /vagrant/configs/gitlab-values.yaml \
  --timeout 45m --wait

# --- Adım 6: GitLab Podlarının Başlaması ve Root Şifre ---
echo -e "\n${CYAN}### Adım 6: GitLab Podlarının Başlaması Bekleniyor ###${NC}"
kubectl wait --for=condition=Available deployment -l app=webservice -n ${KUBE_NAMESPACE_GITLAB} --timeout=300s

GITLAB_PASSWORD=$(kubectl get secret -n ${KUBE_NAMESPACE_GITLAB} gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d)
GITLAB_HOST="gitlab.local"
if ! grep -q "${GITLAB_HOST}" /etc/hosts; then
  echo "127.0.0.1 ${GITLAB_HOST}" | sudo tee -a /etc/hosts > /dev/null
fi

echo -e "\n${GREEN}#############################################################${NC}"
echo -e "${GREEN}###           KURULUM BAŞARIYLA TAMAMLANDI!              ###${NC}"
echo -e "${GREEN}#############################################################${NC}"
echo -e "\n${CYAN}Arayüzlere erişim için Host (ana) makinenizdeki port yönlendirmelerini kullanın:${NC}"
echo -e "  ${YELLOW}Argo CD Arayüzü:${NC}  http://localhost:8080"
echo -e "  ${YELLOW}GitLab Arayüzü:${NC}   http://${GITLAB_HOST}:8080"
echo -e "  ${YELLOW}Uygulama:${NC}          http://localhost:8888"
echo -e "\n${CYAN}GitLab Root Şifresi:${NC} ${GITLAB_PASSWORD}"
