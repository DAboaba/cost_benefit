# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(readr, here, stringr, dplyr, purrr, glue, testthat)

calculate_cost_of_multiple_violence_measures <- function(dframe,
                                                         roster_feature_base_names,
                                                         cost_table,
                                                         windows,
                                                         vc_names,
                                                         years,
                                                         events_type,
                                                         feature_type = NULL){

    roster_feature_to_violence_type_map <- read_csv(file.path(
        here("calculate_cost_of_violence", "hand",
             str_c("new_",
                   str_sub(feature_type, 1, 1),"_roster_feature_to_violence_type_xwalk_",
                   events_type, "_events.csv"))))

    roster_feature_names <- crossing(roster_feature_base_name = roster_feature_base_names,
                                     window = task_config$window_cuts) %>%
        mutate(roster_feature_name = str_c(roster_feature_base_name, window, sep = "_")) %>%
        pull(roster_feature_name)

    dframe_result <- dframe %>%
        bind_cols(map_dfc(.x = roster_feature_names,
                          .f = calculate_violence_measure_costs,
                          dframe = dframe,
                          cost_table = cost_table,
                          roster_feature_to_violence_type_map = roster_feature_to_violence_type_map,
                          events_type = events_type,
                          feature_type = feature_type)) %>%
        calculate_violence_cost_total_multi_window(vc_names, years, windows)

    new_cols <- setdiff(colnames(dframe_result), colnames(dframe))

    dframe_result %>%
        select(all_of(new_cols)) %>%
        rename_with(.fn = ~ paste0(., "_", events_type, "_", feature_type), .cols = everything())
}

calculate_violence_measure_costs <- function(dframe,
                                             roster_feature_name,
                                             cost_table,
                                             roster_feature_to_violence_type_map,
                                             events_type,
                                             feature_type = NULL){

    if (is.null(feature_type)){
        roster_feature_to_violence_type_map <- read_csv(file.path(here(),
                                                                  "calculate_cost_of_violence",
                                                                  paste0("hand/", "roster_feature_to_violence_type_xwalk_", events_type, "_events.csv")))


}

# remove window tag
#roster_feature_filter_name <- str_remove_all(roster_feature_name, "_([\\d]|ten|twenty|thirty|forty)")
roster_feature_filter_name <- str_remove_all(roster_feature_name, "_post_([\\d]*)")

message("Creating costs for ", roster_feature_filter_name)
spec_violence_type <- filter(roster_feature_to_violence_type_map, roster_feature == roster_feature_filter_name) %>%
    pull(violence_type)
costs <- filter(cost_table, violence_type == spec_violence_type)

result <- dframe %>%
    bind_cols(costs) %>%
    transmute(across(contains("cost"), ~ .x * .data[[roster_feature_name]])) %>%
    rename_with(.fn = ~ paste0(roster_feature_name, "_", .))

}

calculate_violence_cost_total_multi_window <- function(dframe, vc_names, years, windows){
    vc_names <- crossing(windows, vc_names) %>%
        unite(col = vc_names, sep = "_", remove = TRUE) %>%
        pull(vc_names)

    dframe %>%
        bind_cols(map2_dfc(.x = vc_names,
                           .y = years,
                           .f = calculate_violence_cost_total,
                           dframe = dframe))
}

calculate_violence_cost_total <- function(dframe, vc_name, year){
    message("Totaling ", year, " ", vc_name)
    vc_name_new <- paste0(vc_name, "_", "total", "_", year)

    dframe %>%
        rowwise() %>%
        transmute(!! vc_name_new := sum(c_across(ends_with(paste0(vc_name, "_", year)))))
}

#test_file("tests/testthat/test_cost_calculation_functions.R")
