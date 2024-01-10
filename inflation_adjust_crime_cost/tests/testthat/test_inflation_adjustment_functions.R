# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(testthat)

base_cpi_path <- file.path(
    here(),
    "inflation_adjust_crime_cost",
    "hand/cpi/all_items_us_base_2015.csv")

stock_cost_table_path <- file.path(
    here(),
    "download_and_clean_crime_costs",
    "download_output/cost_table.csv")

test_that("create_inflation_adjusted_col creates a single new column with correct length",{
    expect_identical(
        create_inflation_adjusted_col(read_csv(stock_cost_table_path),
                                      col_name = "cost",
                                      desired_year = "2020",
                                      base_year = "2020",
                                      base_cpi_path) %>%
            pull(cost_2020) %>%
            length(),
        nrow(read_csv(stock_cost_table_path)))
    expect_equal(
        create_inflation_adjusted_col(read_csv(stock_cost_table_path),
                                      col_name = "cost",
                                      desired_year = "2021",
                                      base_year = "2020",
                                      base_cpi_path) %>% ncol(),
        1)
})

test_that("calculate_cpi_ratio is dividing desired year cpi by base year cpi",{
    expect_equal(round(calculate_cpi_ratio(2014, 2015, base_cpi_path),6), 1.001186)
})

test_that("calculate_cpi_ratio is 1 when base and desired year are identical",{
    expect_identical(calculate_cpi_ratio(2021, 2021, base_cpi_path),1)
})

test_that("obtain_cpi result is numeric and correct",{
    expect_equal(obtain_cpi(2015, base_cpi_path), 100)
    expect_type(obtain_cpi(2016, base_cpi_path), "double")
})
