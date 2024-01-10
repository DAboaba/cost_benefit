TASK_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include ../config.mk

# Input(s)
task_config = $(TASK_DIR)/hand/config.yaml
task_fns = $(wildcard $(TASK_DIR)/R/*.R)
cost_table_inflation_adjusted := $(PROJECT_DIR)/inflation_adjust_crime_cost/output/cost_table_inflation_adjusted.feather
prod_roster :=

# Output(s)
out_dir := $(TASK_DIR)/output/
out_file := $(TASK_DIR)/output/prod_roster_w_costs.feather

## roster_with_costs : Add crime costs to rosters
.PHONY : roster_with_costs
roster_with_costs : $(out_file)

$(out_file) : $(SRC) $(task_fns) $(task_config) $(TESTS) $(cost_table_inflation_adjusted) $(prod_roster)
		mkdir -p $(out_dir)
		$(R_script) --vanilla $< \
														--task_fns=$(task_fns) \
														--task_config=$(task_config) \
														--cost_table_inflation_adjusted=$(cost_table_inflation_adjusted) \
														--prod_roster=$(prod_roster) \
														--out_dir=$(out_dir) \
														--out_file=$(out_file)

## clean             : Remove auto-generated files.
.PHONY : clean
clean :
	rm -r $(out_file)
