CLUSTER_NAME = iot-cluster
KUBECONFIG_EXPORT = export KUBECONFIG=$(shell k3d kubeconfig write $(CLUSTER_NAME))

GREEN = \033[32m
YELLOW = \033[33m
BLUE = \033[34m
RED = \033[31m
RESET = \033[0m

.PHONY: all up down clean re help install-deps cluster setup argocd-password argocd-ui deploy-argo-app

all: up

up: cluster setup deploy-argo-app
	@echo "$(GREEN)✅ Kurulum ve uygulama tanımı tamamlandı!$(RESET)"
	@echo "$(YELLOW)Argo CD şimdi GitHub deponuzdaki uygulamayı senkronize ediyor.$(RESET)"
	@echo "$(BLUE)Durumu takip etmek için 'make argocd-ui' komutunu kullanabilirsiniz.$(RESET)"

install-deps:
	@echo "$(YELLOW)--> Gerekli bağımlılıklar scripts/install.sh ile kuruluyor...$(RESET)"
	@echo "$(YELLOW)Bu işlem için sudo parolanız istenebilir.$(RESET)"
	@sudo bash scripts/install.sh

cluster: install-deps
	@echo "$(YELLOW)--> K3d cluster'ı '$(CLUSTER_NAME)' oluşturuluyor...$(RESET)"
	@if ! k3d cluster get $(CLUSTER_NAME) > /dev/null 2>&1; then \
		k3d cluster create $(CLUSTER_NAME) --agents 1 && \
		echo "$(GREEN)Cluster başarıyla oluşturuldu.$(RESET)"; \
	else \
		echo "$(BLUE)Cluster '$(CLUSTER_NAME)' zaten mevcut. Bu adım atlanıyor.$(RESET)"; \
	fi

setup:
	@echo "$(YELLOW)--> Gerekli Kubernetes kaynakları oluşturuluyor...$(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl create namespace argocd || echo "$(BLUE)Namespace 'argocd' zaten mevcut.$(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl create namespace dev || echo "$(BLUE)Namespace 'dev' zaten mevcut.$(RESET)"
	@echo "$(YELLOW)--> Argo CD kuruluyor...$(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "$(YELLOW)--> Argo CD pod'larının hazır olması bekleniyor...$(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s
	@echo "$(GREEN)Argo CD başarıyla kuruldu ve hazır.$(RESET)"

deploy-argo-app:
	@echo "$(YELLOW)--> Argo CD uygulaması 'playground-app' cluster'a uygulanıyor...$(RESET)"
	@sleep 10 # Argo CD servislerinin tam olarak kendine gelmesi için kısa bir bekleme
	@$(KUBECONFIG_EXPORT) && kubectl apply -f confs/application.yaml
	@echo "$(GREEN)Argo CD uygulaması başarıyla tanımlandı.$(RESET)"

clean:
	@echo "$(RED)--> K3d cluster'ı '$(CLUSTER_NAME)' siliniyor...$(RESET)"
	@k3d cluster delete $(CLUSTER_NAME)
	@rm -rf kubectl
	@echo "$(GREEN)Temizlik tamamlandı.$(RESET)"

down: clean

re: clean all

argocd-password:
	@echo "$(YELLOW)Argo CD başlangıç parolası alınıyor...$(RESET)"
	@echo "$(GREEN)Parola: $(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argocd-ui:
	@echo "$(YELLOW)Argo CD arayüzü için port-forward başlatılıyor...$(RESET)"
	@echo "$(GREEN)Tarayıcınızda $(BLUE)https://localhost:8080$(RESET) adresini açın. Çıkmak için CTRL+C'ye basın.$(RESET)"
	@$(KUBECONFIG_EXPORT) && kubectl port-forward -n argocd svc/argocd-server 8080:443