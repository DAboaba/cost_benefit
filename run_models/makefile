TASK_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include ../config.mk

# Input(s)
task_config = $(TASK_DIR)/hand/config.yaml
task_fns = $(wildcard $(TASK_DIR)/R/*.R)
prod_roster_w_costs := $(PROJECT_DIR)/calculate_cost_of_violence/output/prod_roster_w_costs.feather
outcome_pline_config :=
covar_config :=

# Output(s)
out_dir := $(TASK_DIR)/output/
out_file := $(TASK_DIR)/output/reg_results.feather

## regression_table  : Perform and write out regression results
.PHONY : regression_table
regression_table : $(out_file)

$(out_file) : $(SRC) $(task_fns) $(task_config) $(outcome_pline_config) $(covar_config) $(prod_roster_w_costs)
		$(R_script) --vanilla $< \
														--task_fns=$(task_fns) \
														--task_config=$(task_config) \
														--outcome_pline_config=$(outcome_pline_config) \
														--covar_config=$(covar_config) \
														--prod_roster_w_costs=$(prod_roster_w_costs) \
														--out_dir=$(out_dir) \
														--out_file=$(out_file)

## clean             : Remove auto-generated files.
.PHONY : clean
clean :
	rm -r $(out_file)

## variables         : List variables
.PHONY : variables
variables :
	@echo PROJECT_DIR: $(PROJECT_DIR)
	@echo TASK_DIR: $(TASK_DIR)
	@echo SRC: $(SRC)
	@echo IN_FILES: $(prod_roster_w_costs)
	@echo out_file: $(out_file)

.PHONY : help
help : makefile
	@sed -n 's/^##//p' $<

