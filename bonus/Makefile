# bonus/Makefile

.PHONY: all setup clean ssh help

all: setup ## (VARSAYILAN) Vagrant VM'ini başlatır ve içindeki tüm altyapıyı kurar.

setup:  ## Vagrant VM'ini oluşturur ve içindeki setup.sh betiğini çalıştırır (ÇOK UZUN SÜRER).
	@echo ">>> Vagrant sanal makinesi kuruluyor ve tüm altyapı hazırlanıyor..."
	@echo ">>> Bu işlem 30-45 dakika sürebilir. Lütfen sabırlı olun."
	@vagrant up --provision

clean: ## Vagrant sanal makinesini tamamen yok eder.
	@echo ">>> Vagrant sanal makinesi yok ediliyor..."
	@vagrant destroy -f
	@rm -rf .vagrant

re: clean setup

argocd-deploy:
	@bash scripts/argocd_deployment.sh

ssh: ## Çalışan sanal makineye SSH bağlantısı yapar.
	@echo ">>> Sanal makineye bağlanılıyor..."
	@vagrant ssh

kill-kvm: # çakışma problemi oluyor arada. bu sorunu çözüyor.
	sudo rmmod kvm_amd
	sudo rmmod kvm

help: ## Bu yardım mesajını gösterir.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2}'