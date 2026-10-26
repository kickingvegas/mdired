##
# Copyright 2026 Charles Y. Choi
#

TIMESTAMP := $(shell /bin/date "+%Y%m%d_%H%M%S")
INSTALL_DIR=$(HOME)/bin
EXEC_NAME=foo

.PHONY: all install uninstall

all:
	echo "Hi There."

$(INSTALL_DIR):
	mkdir $(INSTALL_DIR)

install: $(INSTALL_DIR)
	cp -f $(EXEC_NAME).py $(INSTALL_DIR)/$(EXEC_NAME)
	chmod uog+x $(INSTALL_DIR)/$(EXEC_NAME)

uninstall:
	rm $(INSTALL_DIR)/$(EXEC_NAME)
