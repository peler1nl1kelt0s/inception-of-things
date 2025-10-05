.PHONY: all up halt destroy status ssh-server ssh-worker reprovision clean

all: up

up:
	@echo ">>> Sanal makineler başlatılıyor ve ayarlanıyor..."
	@vagrant up

halt:
	@echo ">>> Sanal makineler durduruluyor..."
	@vagrant halt

destroy:
	@echo ">>> Sanal makineler siliniyor..."
	@vagrant destroy -f
	@rm -rf .vagrant agent-token.env ca.crt

status:
	@echo ">>> Sanal makinelerin durumu kontrol ediliyor..."
	@vagrant status

ssh-server:
	@echo ">>> Server makinesine (mdiragaS) bağlanılıyor..."
	@vagrant ssh mdiragaS

ssh-worker:
	@echo ">>> Worker makinesine (mdiragaSW) bağlanılıyor..."
	@vagrant ssh mdiragaSW

reprovision:
	@echo ">>> Kurulum betikleri yeniden çalıştırılıyor..."
	@vagrant provision

kill-kvm: # çakışma problemi oluyor arada. bu sorunu çözüyor.
	sudo rmmod kvm_amd
	sudo rmmod kvm

clean: destroy