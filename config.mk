PROJECT_DIR := $(shell git rev-parse --show-toplevel)
SRC = $(wildcard $(TASK_DIR)/src/*.R)
RMD = $(wildcard $(TASK_DIR)/src/*.Rmd)
PROJECT_FNS := ../R/project_functions.R
TESTS = $(wildcard $(TASK_DIR)/tests/testthat/*.R)
R_script = /usr/local/bin/Rscript
