# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(glue, dplyr, testthat)

# Create inflation adjusted column from existing column ----
create_inflation_adjusted_col <- function(dframe,
                                          col_name,
                                          base_year,
                                          desired_year,
                                          cpi_table){

    inflation_adj_col_name <- glue({col_name}, "_", {desired_year})
    cpi_ratio <- calculate_cpi_ratio(base_year, desired_year, cpi_table)
    transmute(dframe, !!inflation_adj_col_name := .data[[col_name]] * cpi_ratio)

}

# Calculate ratio of two cpis obtained from the same csv ----
calculate_cpi_ratio <- function(base_year, desired_year, cpi_table){
    cpi_base_year <- filter(cpi_table, year == base_year) %>% pull(cpi)
    cpi_desired_year <- filter(cpi_table, year == desired_year) %>% pull(cpi)
    cpi_ratio <- cpi_desired_year/cpi_base_year
    cpi_ratio
}

#test_file("tests/testthat/test_inflation_adjustment_functions.R")
