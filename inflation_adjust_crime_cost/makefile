TASK_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include ../config.mk

# Input(s)
task_config = $(TASK_DIR)/hand/config.yaml
task_fns = $(wildcard $(TASK_DIR)/R/*.R)
cost_table_rate_adjusted := $(PROJECT_DIR)/download_and_clean_crime_costs/output/cost_table.csv
cpi_table := $(TASK_DIR)/hand/cpi/all_items_us_base_2015.csv


# Output(s)
out_dir := $(TASK_DIR)/output/
out_file := $(TASK_DIR)/output/cost_table_inflation_adjusted.feather

## inflation_adjusted_cost_table : Inflation adjust existing cost table.
.PHONY : inflation_adjusted_cost_table
inflation_adjusted_cost_table : $(out_file)

$(out_file) : $(SRC) $(task_fns) $(TESTS) $(cost_table_rate_adjusted) $(cpi_table) $(task_config)
		mkdir -p $(out_dir)
		$(R_script) --vanilla $< \
														--task_fns=$(task_fns) \
														--task_config=$(task_config) \
														--cpi_table=$(cpi_table) \
														--cost_table_rate_adjusted=$(cost_table_rate_adjusted) \
														--out_dir=$(out_dir) \
														--out_file=$(out_file)

## clean                         : Remove auto-generated files.
.PHONY : clean
clean :
	rm -r $(out_file)

## variables                     : List variables
.PHONY : variables
variables :
	@echo PROJECT_DIR: $(PROJECT_DIR)
	@echo TASK_DIR: $(TASK_DIR)
	@echo SRC: $(SRC)
	@echo IN_FILES: $(cost_table) $(cpi_table)
	@echo out_file: $(out_file)

.PHONY : help
help : makefile
	@sed -n 's/^##//p' $<
