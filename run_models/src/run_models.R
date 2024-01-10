# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Path to the current file, relative to the project root ----
here::i_am("run_models/src/run_models.R")

# Load necessary packages for script ----
p_load(yaml, here, arrow, magrittr, dplyr, glue, argparse, stringr)

# Load general functions ----
source(here("R", "project_functions.R"))

# Parse command line arguments ----
cl_args <- parse_make_args(c("task_fns", # path to task functions
                             "task_config", # path to task config
                             "outcome_pline_config", # path to config w/ treatment and takeup indicators
                             "covar_config", # path to covariate config
                             "prod_roster_w_costs", # path to roster from production pipeline with costs
                             "out_dir", # path to output directory
                             "out_file" # path to regression table
))

# Load general and/or task specific functions and test them ----
source(cl_args$task_fns)

# Read in config file specifying unique decisions made for this task ----
task_config <- read_yaml(cl_args$task_config)
covar_config <- read_yaml(cl_args$covar_config)
outcome_pline_config <- read_yaml(cl_args$outcome_pline_config)

# Specify name of input files ----
prod_roster_w_costs <- read_feather(file.path(cl_args$prod_roster_w_costs))

# Create new cost columns and add total costs ----
prod_roster_w_costs_w_xtra_cols <- prod_roster_w_costs %>%
    rowwise() %>%
    # add total costs
    mutate(post_20_cj_cost_total_2017_all_a_plus_post_20_cj_cost_total_2017_all_v =
               sum(c_across(all_of(task_config$more_inclusive_post_20_cj_cost_total_2017_components))),
           post_20_offender_productivity_cost_total_2017_all_a_plus_post_20_offender_productivity_cost_total_2017_all_v =
               sum(c_across(all_of(task_config$more_inclusive_post_20_offender_productivity_cost_total_2017_components))),
           less_inclusive_cost_total = sum(c_across(all_of(task_config$less_inclusive_cost_total_components))),
           more_inclusive_cost_total = sum(c_across(all_of(task_config$more_inclusive_cost_total_components)))) %>%
    ungroup()

covariates <- c(outcome_pline_config["treatment_var"],
                c(covar_config$covariate_sets$blocks$add,

                  reg_results <- run_itt_and_tot_models_multi_outcomes(
                      task_config$outcomes,
                      t_var = outcome_pline_config$treatment_var,
                      take_var = paste0(outcome_pline_config$takeup_var, "_post_20"),
                      covariates = covariates,
                      prod_roster_w_costs_w_xtra_cols)

                  # Write out roster with costs of violence ----
                  write_feather(reg_results, file.path(cl_args$out_file))
                  write_feather(reg_results, file.path(str_c(
                      # remove the .feather extension from the output file name
                      str_remove(cl_args$out_file, ".feather"),
                      "_",
                      # replace all symbols and spaces from Sys.time() with '_'
                      str_replace_all(Sys.time(), pattern = "-| |:", "_"),
                      # add the .feather extension back to the output file name
                      ".feather")))
