## out_of_date  : Run all out of date tasks in this pipeline
out_of_date:
		cd download_and_clean_crime_costs && make
		cd inflation_adjust_crime_cost && make

## timed_run    : Time & run make simultaneously
timed_run:
		time make

## full_run     : Print debugging info in addition to normal processing
full_run:
		make -d

## all          : Forcibly run all tasks in this pipeline
all:
		make -B

.PHONY : help
help : makefile
	@sed -n 's/^##//p' $<

