#!/bin/bash

# Hata durumunda betiği sonlandır
set -e

echo "--- [1/9] Paket listesi güncelleniyor ---"
sudo apt-get update -y

echo "--- [2/9] Gerekli bağımsızlıklar (curl, git) kuruluyor ---"
sudo apt-get install -y curl git

echo "--- [3/9] Docker kuruluyor ---"
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker vagrant

echo "--- [4/9] Kubernetes araçları (kubectl, Helm, k3d, Argo CD CLI) kuruluyor ---"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && rm argocd-linux-amd64

echo "--- [5/9] K3d Kubernetes cluster oluşturuluyor ---"
k3d cluster create iot-cluster --api-port 6550 -p "8081:80@loadbalancer" -p "8443:443@loadbalancer" -p "8888:30080@loadbalancer" --servers 1 --agents 0

echo "--- kubectl için sudo'suz kullanım ayarlanıyor... ---"
mkdir -p /home/vagrant/.kube
sudo cp $(k3d kubeconfig write iot-cluster) /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
export KUBECONFIG=/home/vagrant/.kube/config
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

echo "--- [6/9] Gerekli namespace'ler oluşturuluyor (gitlab, argocd, dev) ---"
kubectl create namespace gitlab || echo "Namespace gitlab zaten var."
kubectl create namespace argocd || echo "Namespace argocd zaten var."
kubectl create namespace dev || echo "Namespace dev zaten var."

echo "--- [7/9] Argo CD kuruluyor ---"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "--- Argo CD için Ingress kuralı oluşturuluyor... ---"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
spec:
  ingressClassName: traefik
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: http
EOF

echo "--- Argo CD sunucusu Ingress için yapılandırılıyor... ---"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
data:
  server.insecure: "true"
EOF

echo "--- Argo CD pod'larının hazır olması bekleniyor... ---"
kubectl wait --for=condition=ready pod --all -n argocd --timeout=5m

echo "--- [8/9] GitLab (Helm ile) kuruluyor. Bu işlem uzun sürebilir... ---"
GITLAB_VALUES_PATH="/vagrant/configs/gitlab-values.yaml"

# NİHAİ ZAFER DÜZELTMESİ: Vagrant senkronizasyonunun bitmesini bekle ve dosyayı doğrula!
echo "--- GitLab yapılandırma dosyasının varlığı kontrol ediliyor... ---"
# Bu döngü, dosya bulunana kadar 300 saniye (5 dakika) bekleyerek "yarış durumu" sorununu çözer.
WAIT_TIME=0
MAX_WAIT=300
while [ ! -f "$GITLAB_VALUES_PATH" ]; do
  if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "HATA: Kritik GitLab yapılandırma dosyası $MAX_WAIT saniye içinde bulunamadı: $GITLAB_VALUES_PATH"
    echo "Lütfen Vagrant senkronizasyonunun çalıştığından ve dosya yolunun doğru olduğundan emin olun. Kurulum iptal ediliyor."
    exit 1
  fi
  echo "Dosya henüz bulunamadı: $GITLAB_VALUES_PATH. 10 saniye sonra tekrar denenecek..."
  sleep 10
  WAIT_TIME=$((WAIT_TIME + 10))
done
echo "✅ GitLab yapılandırma dosyası bulundu ve doğrulandı. Kuruluma devam ediliyor..."


helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  -f $GITLAB_VALUES_PATH \
  --namespace gitlab \
  --timeout 60m

echo "--- [9/9] Kurulum sonrası bilgiler oluşturuluyor ---"
cat <<EOF > /vagrant/SONRAKI_ADIMLAR.md
# KURULUM TAMAMLANDI!

Tebrikler, tüm altyapı başarıyla kuruldu. İşte sonraki adımlar:

## 1. Hosts Dosyasını Yapılandır (Zaten Yaptınız)
\`\`\`
127.0.0.1 gitlab.local argocd.local
\`\`\`

## 2. GitLab'e Erişin
- **Adres:** [https://gitlab.local:8443](https://gitlab.local:8443)
- Tarayıcınız bir güvenlik uyarısı verecektir. Bu normaldir. Güvenli olmadığını kabul edip devam edin.
- **Kullanıcı adı:** \`root\`
- **Şifre:** Sanal makineye \`make ssh\` ile bağlanıp şu komutu çalıştırın:
  \`\`\`bash
  kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d
  \`\`\`

## 3. Argo CD'ye Erişin
- **Adres:** [http://argocd.local:8081](http://argocd.local:8081)
- **Kullanıcı adı:** \`admin\`
- **Şifre:** Sanal makineye \`make ssh\` ile bağlanıp şu komutu çalıştırın:
  \`\`\`bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  \`\`\`
EOF

echo "KURULUM TAMAMLANDI! Proje klasörünüzdeki 'SONRAKI_ADIMLAR.md' dosyasını okuyun."

