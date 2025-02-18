MK_DIR := $(ROOT_DIR)/.mk-lib
-include $(MK_DIR)/variables.mk

.DEFAULT_GOAL := help

help: ##@other Show this help.
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)
