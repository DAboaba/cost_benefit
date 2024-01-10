# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

proxy_roster_path <- file.path(
    here(),
    "..",
    "build_data_pipeline",
    "combine_measures",
    "output",
    "readi_outcomes_roster_up_to_date.feather")

cost_table <- read_feather(file.path(
    here(),
    "inflation_adjust_crime_cost",
    "output",
    "cost_table_inflation_adjusted.feather")) %>%
    mutate(estimate_type = str_remove_all(estimate_type, "_cost"), cost = NULL) %>%
    pivot_wider(names_from = estimate_type,
                names_glue = "{estimate_type}_{.value}",
                values_from = cost_2007:cost_2021)
# no response if not in event type
# make sure it's doing multiplication
test_that("calculate_violence_measure_costs returns a column for each cost column",{
    expect_equal(
        calculate_violence_measure_costs(read_feather(proxy_roster_path), "a_v_bc_mvtheft_twenty", cost_table, "all") %>%
            select(contains("cost")) %>% ncol(),
        cost_table %>% select(-violence_type) %>% ncol()
    )
})

test_that("calculate_violence_cost_total_multi_window is returning results with correct dimension",{
    expect_equal(
        (calculate_violence_cost_total_multi_window(read_feather(proxy_roster_path), c("bottom_up_cost_forty", "victim_x_murder_cost_twenty"),
                                                    c("twenty", "0"), 2020) %>% ncol()) - read_feather(proxy_roster_path) %>% ncol(),
        length(c("bottom_up_cost_forty", "victim_x_murder_cost_twenty")) * length(c("twenty", "0")))
})

test_that("calculate_multiple_violence_cost_totals is returning results with correct dimension",{
    expect_equal(
        calculate_multiple_violence_cost_totals(read_feather(proxy_roster_path), c("bottom_up_cost_forty", "victim_x_murder_cost_twenty"), 2017) %>% nrow(),
        read_feather(proxy_roster_path) %>% nrow())
    expect_equal(
        calculate_multiple_violence_cost_totals(read_feather(proxy_roster_path), c("bottom_up_cost_forty", "victim_x_murder_cost_twenty"), 2017) %>% ncol(),
        length(c("bottom_up_cost_forty", "victim_x_murder_cost_twenty")))
})

test_that("calculate_violence_cost_total_multi_year is returning results with correct dimension",{
    expect_equal(
        calculate_violence_cost_total_multi_year(read_feather(proxy_roster_path), c("bottom_up_cost_forty"), c(2019,2017)) %>% nrow(),
        read_feather(proxy_roster_path) %>% nrow())
    expect_equal(
        calculate_violence_cost_total_multi_year(read_feather(proxy_roster_path), c("bottom_up_cost_forty"), c(2019,2017)) %>% ncol(),
        length(c(2019,2017)))
})

test_that("calculate_violence_cost_total is summing correct cols",{
    expect_identical(
        calculate_violence_cost_total(read_feather(proxy_roster_path), "victim_x_murder_cost_twenty", 2018) %>% pull(victim_x_murder_cost_twenty_total_2018),
        read_feather(proxy_roster_path) %>% mutate(result = sum(c_across(ends_with("victim_x_murder_cost_twenty_2018")))) %>% pull(result))
})
