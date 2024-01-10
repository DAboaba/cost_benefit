# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(here, yaml, rvest, magrittr, dplyr, snakecase, stringr, tidyr, readr)

# Path to the current file, relative to the project root ----
here::i_am("download_and_clean_crime_costs/src/download_and_clean_crime_costs.R")

# Load general and/or task specific functions ----
source(here("R", "project_functions.R"))

# Check for existence of and/or create task output directory ----
task_output_dir <- here("download_and_clean_crime_costs/output"); check_create_dir(task_output_dir)

# Read in config file specifying unique decisions made for this task ----
task_config <- read_yaml(here("download_and_clean_crime_costs", "hand", "config.yaml"))

# Scrape cost of crime table ----
cost_table <- read_html(task_config$cost_table_data_link) %>%
    html_table() %>%
    first()

new_col_names <- c("violence_type", # create name for first column
                   to_snake_case(colnames(cost_table)[-1])) %>% # clean other column names
    str_replace_all("_costs", "") %>%
    paste0(c("", rep("_cost", 5)))

colnames(cost_table) <- new_col_names

# Clean cost table ----
replace_list <- list(NA, 0, 0, 0, 0, 0); names(replace_list) <- new_col_names

cost_table %<>%
    mutate(across(victim_cost:wtp_estimate_cost, ~ str_remove_all(.x, "(\\$|\\,|\\.)")),
           across(victim_cost:wtp_estimate_cost,
                  ~ if_else(str_detect(.x, "million"),
                            paste0(str_remove_all(.x, " million"), "00000"),
                            .x)),
           across(victim_cost:wtp_estimate_cost, as.numeric),
           violence_type = if_else(
               violence_type == "Other offenses (prostitution, loitering, false statements, etc.)",
               "Other",
               violence_type),
           violence_type = str_to_lower(violence_type)) %>%
    replace_na(replace_list) %>%
    mutate(bottom_up_cost = total_cost,
           total_cost = NULL,
           bottom_up_x_victim_cost = bottom_up_cost - victim_cost,
           bottom_up_x_cj_cost = bottom_up_cost - cj_cost,
           bottom_up_x_offender_productivity_cost = bottom_up_cost - offender_productivity_cost,
           bottom_up_x_cj_x_offender_productivity_cost = victim_cost,
           wtp_estimate_x_cj_x_offender_productivity_cost = wtp_estimate_cost - (cj_cost + offender_productivity_cost))

# Convert cost table into long format ----
cost_table %<>%
    pivot_longer(victim_cost:wtp_estimate_x_cj_x_offender_productivity_cost,
                 names_to = "estimate_type", values_to = "cost")

# Write out cost table ----
write_csv(cost_table, here(task_output_dir, "cost_table.csv"))
