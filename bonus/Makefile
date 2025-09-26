CLUSTER_NAME := iot-cluster
HOST_PORT := 8888
NODE_PORT := 30080
KUBE_NAMESPACE_ARGOCD := argocd
KUBE_NAMESPACE_DEV := dev
KUBE_NAMESPACE_GITLAB := gitlab

GREEN=\033[0;32m
YELLOW=\033[0;33m
NC=\033[0m

.PHONY: launch all install up clean argocd-install argocd-password argocd-ui app-deploy help

launch: all
	@echo -e "\n${GREEN}[SUCCESS] Kurulum tamamlandı. Son adımlara geçiliyor...${NC}"
	@$(MAKE) argocd-password
	@$(MAKE) argocd-ui

help:
	@echo -e "${GREEN}Kullanılabilir komutlar:${NC}"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2}'

all: app-deploy

install:
	@echo -e "\n${GREEN}[INFO] Gerekli araçlar kuruluyor...${NC}"
	@chmod +x scripts/install_tools.sh
	@./scripts/install_tools.sh
	@echo -e "\n${YELLOW}[WARN] Docker yetkileri için yeni bir terminal açın veya 'newgrp docker' komutunu çalıştırın.${NC}"

up:
	@echo -e "\n${GREEN}[INFO] 🚀 K3d kümesi (${CLUSTER_NAME}) oluşturuluyor...${NC}"
	@k3d cluster create ${CLUSTER_NAME} -p "${HOST_PORT}:${NODE_PORT}@agent:0" --agents 1
	@echo -e "${GREEN}[SUCCESS] Küme başarıyla oluşturuldu.${NC}"

clean:
	@echo -e "\n${YELLOW}[INFO] 🧹 K3d kümesi (${CLUSTER_NAME}) siliniyor...${NC}"
	@k3d cluster delete ${CLUSTER_NAME}
	@echo -e "${GREEN}[SUCCESS] Küme başarıyla silindi.${NC}"

argocd-install: up
	@echo -e "\n${GREEN}[INFO] Gerekli namespace'ler oluşturuluyor: ${KUBE_NAMESPACE_ARGOCD}, ${KUBE_NAMESPACE_DEV}${NC}"
	@kubectl create namespace ${KUBE_NAMESPACE_ARGOCD} >/dev/null 2>&1 || echo "Namespace ${KUBE_NAMESPACE_ARGOCD} zaten mevcut."
	@kubectl create namespace ${KUBE_NAMESPACE_DEV} >/dev/null 2>&1 || echo "Namespace ${KUBE_NAMESPACE_DEV} zaten mevcut."
	@kubectl create namespace ${KUBE_NAMESPACE_GITLAB} >/dev/null 2>&1 || echo "Namespace ${KUBE_NAMESPACE_GITLAB} zaten mevcut."
	@echo -e "\n${GREEN}[INFO] Argo CD kuruluyor...${NC}"
	@kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo -e "${GREEN}[SUCCESS] Argo CD kurulumu için kaynaklar uygulandı. Pod'ların hazır olması biraz zaman alabilir.${NC}"
	@echo -e "${YELLOW}[INFO] Argo CD sunucusunun başlaması bekleniyor... (Bu işlem 1-2 dakika sürebilir)${NC}"
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${KUBE_NAMESPACE_ARGOCD} --timeout=120s

argocd-password:
	@echo -e "\n${GREEN}===============================================================${NC}"
	@echo -e "${GREEN}[INFO] 🔑 Argo CD Admin Şifresi:${NC}"
	@kubectl -n ${KUBE_NAMESPACE_ARGOCD} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo

argocd-ui:
	@echo -e "\n${GREEN}[INFO] 🌐 Argo CD arayüzü için port yönlendirme başlatılıyor...${NC}"
	@echo -e "Tarayıcınızdan ${YELLOW}https://localhost:8080${NC} adresine gidin."
	@echo -e "Kullanıcı adı: ${YELLOW}admin${NC}"
	@echo -e "Bu terminali açık bıraktığınız sürece arayüze erişebilirsiniz."
	@kubectl port-forward svc/argocd-server -n ${KUBE_NAMESPACE_ARGOCD} 8080:443

app-deploy: argocd-install
	@echo -e "\n${GREEN}[INFO] Uygulama Argo CD'ye tanıtılıyor...${NC}"
	@kubectl apply -f applications/application.yaml
	@echo -e "${GREEN}[SUCCESS] Uygulama başarıyla dağıtıldı. Senkronizasyon için Argo CD arayüzünü kontrol edin.${NC}"