TASK_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include ../config.mk

# Output(s)
OUT_FILE = $(OUT_DIR)/cost_table.feather

## cost_table : Download, clean, and save cost table.
.PHONY : cost_table
cost_table : $(OUT_FILE)

$(OUT_FILE) : $(SRC) $(PROJECT_FNS) $(TASK_CONFIG)
	$(R_script) --vanilla $<

## variables  : List variables
.PHONY : variables
variables :
	@echo PROJECT_DIR: $(PROJECT_DIR)
	@echo TASK_DIR: $(TASK_DIR)
	@echo SRC: $(SRC)
	@echo OUT_FILE: $(OUT_FILE)

.PHONY : help
help : makefile
	@sed -n 's/^##//p' $<
