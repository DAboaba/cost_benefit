# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(argparse, purrr, stringr, magrittr, glue, here)

check_create_dir <- function(dir_path) {
    if (!dir.exists(dir_path)) {
        dir.create(dir_path)
    }
}

parse_make_args <- function(arg_names = c(), inter_active = interactive()) {
    if (!inter_active) {# Read command line arguments automagically ----
        parser <- ArgumentParser()
        map(.x = arg_names, .f = ~ parser$add_argument(str_c('--', .x)))
        cl_args <- parser$parse_args()

    } else {# Parse command line arguments from makefile ----
        # get task directory for current script and set working directory to correct path
        task_dir <- gsub("src(.*)?", "", rstudioapi::getActiveDocumentContext()$path, "/")

        # Set working directory ----
        setwd(task_dir)

        # get version of R that project was written in from makefile
        config_r_version <- str_extract_all(str_subset(readLines("../config.mk"), "R_script"), pattern = "[:digit:]") %>%
            unlist() %>%
            paste0(collapse = ".")
        # get version of R currently being used
        current_r_version <- paste(sessionInfo()$R.version$major, sessionInfo()$R.version$minor, sep = '.')
        if(current_r_version != config_r_version) { stop("R version 3.6.3 required")}

        # read makefile
        makefile <- readLines('makefile')

        # find lines where args are defined
        argsline <- makefile[grepl(paste(paste0('^', arg_names), collapse = '|'), makefile)]

        # seperate arg name from arg definition
        arg_list <- list(sapply(strsplit(argsline,'( )?=( )?|( )?:=( )?'), '[[',1), sapply(strsplit(argsline, '= '), '[[',2))
        # since working directory has been set above, replace within project and task file paths with relative file paths
        cl_args <- as.list(gsub('\\$\\(PROJECT_DIR\\)\\/', glue(here(), "/"), arg_list[[2]]))
        cl_args <- as.list(gsub('\\$\\(TASK_DIR\\)\\/', '', cl_args))
        names(cl_args) = arg_list[[1]]

        # if there are function paths defined in the makefile replace with relative file paths
        if(!is.null(cl_args$task_fns)){
            cl_args$task_fns <- paste0("R/", list.files("R/"))
        }

        # Check for and possibly create output dir ----
        check_create_dir(cl_args$out_dir)
    }

    message("Command Line Arguments:")
    print(cl_args)
    cl_args
}
