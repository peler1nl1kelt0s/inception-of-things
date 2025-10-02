# Makefile'ın komutları çalıştırmak için /bin/bash kullanmasını sağla.
SHELL := /bin/bash

.PHONY: all clean ssh status install-tools

# Varsayılan hedef: Gerekli araçları kontrol eder ve sanal makineyi başlatır.
all: install-tools
	@echo "Sanal makine başlatılıyor ve ortam hazırlanıyor..."
	@echo "Bu işlem donanımınıza bağlı olarak 30-40 dakika sürebilir."
	@vagrant up

# Gerekli araçların (Vagrant, VirtualBox) yüklü olup olmadığını kontrol eder.
install-tools:
	@echo "Gerekli araçlar kontrol ediliyor..."
	@if ! command -v vagrant &> /dev/null; then \
		echo "Hata: Vagrant bulunamadı. Lütfen https://www.vagrantup.com/downloads adresinden kurun."; \
		exit 1; \
	fi
	@echo "Vagrant yüklü."
	# VirtualBox kontrolü (yaygın olarak kullanıldığı için)
	@if ! command -v VBoxManage &> /dev/null; then \
		echo "Uyarı: VirtualBox bulunamadı. Vagrant için bir sanallaştırma sağlayıcınız (örn: VirtualBox, Hyper-V) olduğundan emin olun."; \
	fi


# Sanal makineyi ve tüm kaynakları siler.
clean:
	@echo "Sanal makine siliniyor..."
	@vagrant destroy -f
#	@rm -rf .vagrant

# Sanal makineye SSH ile bağlanır.
ssh:
	@echo "Sanal makineye SSH ile bağlanılıyor..."
	@vagrant ssh

# Sanal makinenin durumunu gösterir.
status:
	@echo "Sanal makine durumu kontrol ediliyor..."
	@vagrant status

