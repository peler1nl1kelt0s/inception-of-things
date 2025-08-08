GREEN   = \033[32;1m
YELLOW  = \033[33;1m
BLUE    = \033[34;1m
RESET   = \033[0m

.PHONY: all up clean re status ssh-server ssh-worker help

all: up

up:
	@echo "\n$(BLUE)--> Vagrant ile sanal ortam başlatılıyor (VirtualBox provider)...$(RESET)"
	@vagrant up --provider=virtualbox
	@echo "\n$(GREEN)✅ Kurulum tamamlandı! Küme durumu için 'make status' komutunu kullanabilirsiniz.$(RESET)"

clean:
	@echo "$(YELLOW)--> Vagrant ortamı yok ediliyor...$(RESET)"
	@vagrant destroy -f
	@rm -rf .vagrant agent-token.env
	@echo "\n$(GREEN)🧹 Temizlik tamamlandı!$(RESET)"

re: clean up

status:
	@echo "$(BLUE)--> Vagrant ortam durumu kontrol ediliyor...$(RESET)"
	@vagrant status
	@echo "\n$(BLUE)--> Küme node'larının durumu kontrol ediliyor (Server üzerinden)...$(RESET)"
	@vagrant ssh musekerS -c "sudo kubectl get nodes -o wide"

ssh-server:
	@echo "$(BLUE)--> Server (musekerS) sanal makinesine bağlanılıyor...$(RESET)"
	@vagrant ssh musekerS

ssh-worker:
	@echo "$(BLUE)--> Worker (musekerSW) sanal makinesine bağlanılıyor...$(RESET)"
	@vagrant ssh musekerSW

help:
	@echo "$(GREEN)Kullanılabilir Makefile Komutları:$(RESET)"
	@echo "  $(YELLOW)make up$(RESET)          - Vagrant ortamını ve K3s kümesini başlatır."
	@echo "  $(YELLOW)make clean$(RESET)        - Tüm Vagrant sanal makinelerini siler."
	@echo "  $(YELLOW)make re$(RESET)           - Ortamı temizler ve yeniden kurar."
	@echo "  $(YELLOW)make status$(RESET)       - Vagrant ve K3s kümesinin durumunu gösterir."
	@echo "  $(YELLOW)make ssh-server$(RESET)  - Server (musekerS) sanal makinesine SSH bağlantısı yapar."
	@echo "  $(YELLOW)make ssh-worker$(RESET)  - Worker (musekerSW) sanal makinesine SSH bağlantısı yapar."
	@echo "  $(YELLOW)make help$(RESET)         - Bu yardım menüsünü gösterir."

