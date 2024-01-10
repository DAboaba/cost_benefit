# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for script ----
p_load(purrr, stringr, tidyr, lmtest, ivreg, sandwich, groundhog, broom, magrittr)

# TODO: Figure out a way around installing this package everytime this task is
# run
# ivpack was archived and removed from CRAN due to failing checks, to get around
# this, below we use the link to the gzipped tarball archive of ivpack version 1.2
# - obtained by going to the following link
#  https://cran.r-project.org/src/contrib/Archive/ivpack/ and rightclicking the
#  link and selecting copy link ----
install.packages("https://cran.r-project.org/src/contrib/Archive/ivpack/ivpack_1.2.tar.gz",
                 repos = NULL, type = "source")
library(ivpack)

run_itt_and_tot_models_multi_outcomes <- function(o_vars, t_var, take_var, covariates, reg_dframe, robust_se = TRUE){

    map_dfr(o_vars,
            .f = run_itt_and_tot_models,
            t_var = t_var,
            take_var = take_var,
            covariates = covariates,
            reg_dframe = reg_dframe,
            robust_se = robust_se)
}

run_itt_and_tot_models <- function(o_var, t_var, covariates, reg_dframe, take_var, robust_se = TRUE){
    overall_stats <- calc_overall_reg_statistics(reg_dframe, t_var, take_var, o_var)
    itt_result <- run_itt_regression(reg_dframe, o_var, covariates, robust_se)
    tot_result <- run_tot_regression(reg_dframe, o_var, t_var, take_var, covariates, robust_se)
    structure_reg_results(overall_stats, itt_result, tot_result, t_var, take_var)
}

calc_overall_reg_statistics <- function(reg_dframe, t_var, take_var, o_var){
    obs <- reg_dframe %>% filter(!is.na(.data[[o_var]])) %>% nrow()

    itt_means <- reg_dframe %>%
        group_by(.data[[t_var]]) %>%
        summarise(mean = mean(.data[[o_var]], na.rm = TRUE))

    # code from Nathan
    a <- reg_dframe %>% filter(if_all(c(.data[[t_var]], .data[[take_var]]), ~ . == 1)) %>% pull(o_var) %>% mean(na.rm = T)
    b <- reg_dframe %>% filter(.data[[t_var]] == 1) %>% pull(take_var) %>% mean(na.rm = T)
    c <- reg_dframe %>% mutate(control = if_else(treatment == 1, 0, 1)) %>%
        filter(if_all(c(.data[["control"]], .data[[take_var]]), ~ . == 1)) %>% pull(o_var) %>% mean(na.rm = T)
    d <- reg_dframe %>% mutate(control = if_else(treatment == 1, 0, 1)) %>%
        filter(control == 1) %>% pull(take_var) %>% mean(na.rm = T)

    if (is.na(a)) a <- 0; if (is.na(b)) b <- 0; if (is.na(c)) c <- 0; if (is.na(d)) d <- 0

    tibble(Outcome = o_var, Model_n = obs,
           Control_mean = filter(itt_means, .data[[t_var]] == 0) %>% pull(mean),
           Treatment_mean = filter(itt_means,.data[[t_var]] == 1) %>% pull(mean),
           preCCM = (a*b - c*d) / (b-d))
}

run_itt_regression <- function(reg_dframe, o_var, covariates, robust_se = TRUE){
    correct_o_var <- paste0("`", o_var, "`")
    model <- reformulate(response = correct_o_var, covariates) %>%
        lm(data = reg_dframe)

    if(robust_se) model %<>% coeftest(vcov = vcovHC(., "HC1"))

    model %>% tidy()
}

run_tot_regression <- function(reg_dframe, o_var, t_var, take_var, covariates,
                               robust_se = TRUE){
    correct_o_var <- paste0("`", o_var, "`")
    covariates %<>% glue_collapse(" + ") %>% str_remove("treatment \\+ ")
    formula_spec <- paste(correct_o_var, "~",
                          take_var, " + ", covariates, "|",
                          t_var, " + ", covariates)

    model <- ivreg(formula_spec, data = reg_dframe)

    if(robust_se) model %<>% robust.se()
    model %>% tidy()
}

structure_reg_results <- function(overall_stats,
                                  itt_reg_results_table,
                                  tot_reg_results_table,
                                  t_var,
                                  take_var){
    overall_stats %>%
        bind_cols(format_reg_results(itt_reg_results_table, t_var, "itt"),
                  format_reg_results(tot_reg_results_table, take_var, "tot")) %>%
        mutate(CCM = preCCM - TOT_Beta) %>%
        relocate(CCM, .after = preCCM)
}

format_reg_results <- function(reg_results_table, t_var, estimate_type){
    reg_results_table %>%
        select(term, Beta = estimate, `(SE)` = std.error, pval = p.value) %>%
        filter(term == t_var) %>%
        select(-term) %>%
        rename_with( ~ paste0(str_to_upper(estimate_type), "_", .x))
}
