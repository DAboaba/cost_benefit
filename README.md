# Benefit-Cost

To run the pipeline:

Clone the repo:

1. `cd desired_directory`
2. `git clone` the SSH url

To run the code on your local machine:

1. Set your working directory to the root of the project folder
	- In Rstudio console: `setwd("../benefit-cost")`

2. Confirm your working directory is at the root of the project directory
	- In Rstudio console: `getwd()`

3. Singular task(s)
	- Manually
		- In Rstudio console, `setwd("task-name"); source("src/task-name.r")`
		
4. Alternatively, you can run the desired task as a local job by
 - Opening the local jobs pane (`Tools` -> `Jobs` -> `Start Local Job`) after opening the task's script
	- Selecting the task directory as the working directory
	- Clicking `start`

The order to run tasks in is as described in the makefile i.e.

1. `download_and_clean_crime_costs`
2. `inflation_adjust_crime_cost`
3. `calculate_cost_of_violence`
4. `run_models`

The other tasks do not need to be rerun
