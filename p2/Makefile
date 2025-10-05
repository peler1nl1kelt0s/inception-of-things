# Makefile for Inception-of-Things - Part 2

GREEN   = \033[32;1m
YELLOW  = \033[33;1m
BLUE    = \033[34;1m
CYAN    = \033[36;1m
MAGENTA = \033[35;1m
RED     = \033[31;1m
RESET   = \033[0m

.PHONY: all up deploy clean test help

all: up deploy

up:
	@echo "$(BLUE)🚀 Vagrant sanal makinesi başlatiliyor...$(RESET)"
	@vagrant up

# uygulama dagitma
deploy:
	@echo "$(GREEN)🌐 Kubernetes uygulamalari dağıtılıyor...$(RESET)"
	@vagrant ssh -c "kubectl apply -f /vagrant/configs/app1.yaml"
	@vagrant ssh -c "kubectl apply -f /vagrant/configs/app2.yaml"
	@vagrant ssh -c "kubectl apply -f /vagrant/configs/app3.yaml"
	@vagrant ssh -c "kubectl apply -f /vagrant/configs/ingress.yaml"

# uygulamalari ve vm`i sil
clean:
	@echo "$(RED)🧹 Kubernetes kaynaklari siliniyor...$(RESET)"
	@vagrant ssh -c "kubectl delete -f /vagrant/configs/app1.yaml" || true
	@vagrant ssh -c "kubectl delete -f /vagrant/configs/app2.yaml" || true
	@vagrant ssh -c "kubectl delete -f /vagrant/configs/app3.yaml" || true
	@vagrant ssh -c "kubectl delete -f /vagrant/configs/ingress.yaml" || true
	@echo "$(RED)🗑️  Sanal makine siliniyor...$(RESET)"
	@vagrant destroy -f
	@rm -rf .vagrant

# curl ile uygulama kontrolu
test:
	@echo "$(MAGENTA)🔍 Uygulamalar test ediliyor...$(RESET)"
	@echo "$(CYAN)--> 🌐 app1.com$(RESET)"
	@curl -H "Host: app1.com" 192.168.56.110
	@echo ""
	@echo "$(CYAN)--> 🌐 app2.com$(RESET)"
	@curl -H "Host: app2.com" 192.168.56.110
	@echo ""
	@echo "$(CYAN)--> 🌐 Varsayilan (app3)$(RESET)"
	@curl 192.168.56.110

kill-kvm: # çakışma problemi oluyor arada. bu sorunu çözüyor.
	sudo rmmod kvm_amd
	sudo rmmod kvm

help:
	@echo "$(GREEN)📘 Kullanilabilir Makefile Komutlari:$(RESET)"
	@echo "  $(YELLOW)▶ make up     $(RESET) - $(CYAN)Vagrant ortamini ve K3s kümesini başlatir.$(RESET)"
	@echo "  $(YELLOW)▶ make deploy $(RESET) - $(CYAN)Uygulamalari Kubernetes üzerine deploy eder.$(RESET)"
	@echo "  $(YELLOW)▶ make clean  $(RESET) - $(CYAN)Tüm VM'leri ve Kubernetes kaynaklarini siler.$(RESET)"
	@echo "  $(YELLOW)▶ make test   $(RESET) - $(CYAN)Uygulama endpoint'lerini test eder.$(RESET)"
	@echo "  $(YELLOW)▶ make help   $(RESET) - $(CYAN)Bu yardim menüsünü gösterir.$(RESET)"

