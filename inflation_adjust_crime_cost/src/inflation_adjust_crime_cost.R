# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(here, yaml, readr, feather, purrr, tidyr)

# Path to the current file, relative to the project root ----
here::i_am("inflation_adjust_crime_cost/src/inflation_adjust_crime_cost.R")

# Load general functions ----
source(here("R", "project_functions.R"))

# Parse command line arguments ----
cl_args <- parse_make_args(c("task_fns", # path to task functions
                             "task_config", # path to task config
                             "cpi_table", # path to cpi table
                             "cost_table_rate_adjusted", # path to rate-adjusted cost table
                             "out_dir", # path to output directory
                             "out_file" # path to inflation adjusted cost table
))

# Load task specific functions and test them ----
source(cl_args$task_fns)

# Read in config file specifying unique decisions made for this task ----
task_config <- read_yaml(cl_args$task_config)

# Read in cost table ----
cost_table <- read_csv(file.path(cl_args$cost_table))

# Read in cpi table ----
cpi_table <- read_csv(file.path(cl_args$cpi_table))

# Create inflation adjusted columns for a set of different years from different cost columns ----
desired_years <- task_config$cost_year_start:task_config$cost_year_end
cost_columns <- str_subset(colnames(cost_table), pattern = "type", negate = TRUE)
tibble_desired_years_col_names <- expand_grid(desired_year = desired_years, col_name = cost_columns)
cost_table_inf_adj <- bind_cols(cost_table,
                                pmap_dfc(tibble_desired_years_col_names,
                                         .f = create_inflation_adjusted_col,
                                         dframe = cost_table,
                                         base_year = task_config$base_year,
                                         cpi_table = cpi_table))

# Write out cost table ----
write_feather(cost_table_inf_adj, file.path(cl_args$out_file))
