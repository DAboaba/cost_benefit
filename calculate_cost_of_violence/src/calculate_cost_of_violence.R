# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(here, yaml, arrow, magrittr, stringr, dplyr, tidyr)

# Path to the current file, relative to the project root ----
here::i_am("calculate_cost_of_violence/src/calculate_cost_of_violence.R")

# Load general functions ----
source(here("R", "project_functions.R"))

# Parse command line arguments ----
cl_args <- parse_make_args(c("task_fns", # path to task functions
                             "task_config", # path to task config
                             "cost_table_inflation_adjusted", # path to inflation-adjusted cost table
                             "prod_roster", # path to roster from production pipeline
                             "out_dir", # path to output directory
                             "out_file" # path to roster with costs
))

# Load general and/or task specific functions and test them ----
source(cl_args$task_fns)

# Read in config file specifying unique decisions made for this task ----
task_config <- read_yaml(cl_args$task_config)

# Read in and widen adjusted cost table ----
cost_table_inf_adj <- read_feather(file.path(cl_args$cost_table_inflation_adjusted)) %>%
    mutate(estimate_type = str_remove_all(estimate_type, "_cost")) %>%
    # dropping columns that are redundant with the _2007 cols
    select(-c(cost:clearance_rate_scaled_down_cost)) %>%
    pivot_wider(names_from = estimate_type,
                names_glue = "{estimate_type}_{.value}",
                values_from = cost_2007:clearance_rate_scaled_down_cost_2021)

# Select cost year(s) ----
cost_table_inf_adj_specified_years <- cost_table_inf_adj %>%
    select(violence_type, ends_with(task_config$cost_year))

# Read in production roster ----
prod_roster <- read_feather(file.path(cl_args$prod_roster))

# Calculate different costs of different types of arrests for different windows ----
prod_roster_w_all_a_event_costs <- calculate_cost_of_multiple_violence_measures(
    prod_roster,
    task_config$a_all_events_roster_features_to_use,
    cost_table_inf_adj_specified_years,
    task_config$window_cuts,
    task_config$violence_cost_totals,
    task_config$cost_year,
    events_type = "all",
    feature_type = "a")

# Calculate different costs of different types of victimizations for different windows ----
prod_roster_w_all_v_event_costs <- calculate_cost_of_multiple_violence_measures(
    prod_roster,
    task_config$v_all_events_roster_features_to_use,
    cost_table_inf_adj_specified_years,
    task_config$window_cuts,
    task_config$violence_cost_totals,
    task_config$cost_year,
    events_type = "all",
    feature_type = "v")

prod_roster_w_costs <- bind_cols(prod_roster,
                                 prod_roster_w_all_a_event_costs,
                                 prod_roster_w_all_v_event_costs)

# Write out roster with costs of violence ----
write_feather(prod_roster_w_costs, file.path(cl_args$out_file))

