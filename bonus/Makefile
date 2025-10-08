# Makefile for the Inception-of-Things Bonus Project

all: up

up:
	@echo "Sanal makine başlatılıyor ve kurulum yapılıyor..."
	vagrant up

halt:
	@echo "Sanal makine durduruluyor..."
	vagrant halt

clean:
	@echo "Sanal makine ve tüm kaynaklar siliniyor..."
	@vagrant destroy -f
	@rm -rf .vagrant configs/.git

status:
	vagrant status

ssh:
	vagrant ssh

kill-kvm: # çakışma problemi oluyor arada. bu sorunu çözüyor.
	sudo rmmod kvm_amd
	sudo rmmod kvm

restart-ports:
	@echo "Port forwarding servisleri yeniden başlatılıyor..."
	@pkill -f "kubectl port-forward" || true
	@vagrant ssh -c "cd /vagrant && sudo bash -c './scripts/start-port-forwarding.sh'"

logs:
	@echo "=== GitLab Port Forwarding Log ==="
	@vagrant ssh -c "cat /tmp/gitlab-port-forward.log 2>/dev/null || echo 'Log bulunamadı'"
	@echo "=== ArgoCD Port Forwarding Log ==="
	@vagrant ssh -c "cat /tmp/argocd-port-forward.log 2>/dev/null || echo 'Log bulunamadı'"

k8s-status:
	@vagrant ssh -c "kubectl get pods -A"

reset-cluster:
	@vagrant ssh -c "k3d cluster delete iot-cluster && ./scripts/k3d-setup.sh"

.PHONY: all up halt clean status ssh restart-ports logs k8s-status reset-cluster