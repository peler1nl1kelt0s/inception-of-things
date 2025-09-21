.PHONY: all install deploy delete help

K3D_CLUSTER_NAME = iot
ARGOCD_NAMESPACE = argocd
APP_NAMESPACE = dev

all: install deploy
	@echo "\n############################################################"
	@echo "#           Kurulum ve Dağıtım Tamamlandı!               #"
	@echo "# Argo CD arayüzüne erişmek için yeni bir terminalde şunu çalıştırın:"
	@echo "# kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443"
	@echo "# 'admin' kullanıcısı ve aşağıdaki şifre ile giriş yapın:"
	@echo "# kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"
	@echo "############################################################"


install:
	@chmod +x scripts/install.sh
	@./scripts/install.sh $(K3D_CLUSTER_NAME)
	@echo "\n############################################################"
	@echo "#                   Argo CD Kuruluyor                      #"
	@echo "############################################################"
	@kubectl create namespace $(ARGOCD_NAMESPACE) || echo "Namespace '$(ARGOCD_NAMESPACE)' zaten mevcut."
	@kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "\nArgo CD'nin podlarının ayağa kalkması bekleniyor..."
	@kubectl wait --for=condition=ready pod --all -n $(ARGOCD_NAMESPACE) --timeout=5m

deploy:
	@echo "\n############################################################"
	@echo "#           Uygulama Argo CD'ye Dağıtılıyor              #"
	@echo "############################################################"
	@kubectl apply -f apps/playground-app.yaml
	@echo "\nUygulamanın 'Healthy' ve 'Synced' olması bekleniyor..."
	@echo "Durumu Argo CD arayüzünden takip edebilirsiniz."

delete:
	@echo "\n############################################################"
	@echo "#               Tüm Kurulum Siliniyor                    #"
	@echo "############################################################"
	@k3d cluster delete $(K3D_CLUSTER_NAME)

help:
	@echo "Kullanım:"
	@echo "  make          - Tüm kurulumu (araçlar, cluster, Argo CD, uygulama) yapar."
	@echo "  make install  - Sadece araçları, cluster'ı ve Argo CD'yi kurar."
	@echo "  make deploy   - Sadece uygulamayı Argo CD'ye dağıtır."
	@echo "  make delete   - K3d cluster'ını tamamen siler."