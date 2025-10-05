# Makefile for the Inception-of-Things Bonus Project

# Varsayılan komut 'make' çalıştırıldığında 'up' hedefini çağırır.
all: up

# Sanal makineyi başlatır ve kurulum betiğini çalıştırır.
up:
	@echo "Sanal makine başlatılıyor ve kurulum yapılıyor..."
	vagrant up

# Sanal makineyi durdurur.
halt:
	@echo "Sanal makine durduruluyor..."
	vagrant halt

# Sanal makineyi tamamen siler.
clean:
	@echo "Sanal makine ve tüm kaynaklar siliniyor..."
	vagrant destroy -f

# Sanal makinenin durumunu gösterir.
status:
	vagrant status
	
kill-kvm: # çakışma problemi oluyor arada. bu sorunu çözüyor.
	sudo rmmod kvm_amd
	sudo rmmod kvm

# Sanal makineye SSH ile bağlanır.
ssh:
	vagrant ssh

.PHONY: all up halt clean status ssh