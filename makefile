# makefile for SV
# compiler ans simulator settings
VLOG = vlog
VSIM = vsim

#Flags
VLOG_FLAGS = -sv
VSIM_FLAGS = -c

#Source files

SRC = mc_scheduler.sv 
#top module
TOP_MOD = mc_scheduler

#target
all: compile simulate 

compile :  
	$(VLOG) $(VLOG_FLAGS ) $(SRC) 

simulate :  

	@read -p "Enter INPUT_FILE (default: trace.txt): " INPUT_FILE; \
	INPUT_FILE=$${INPUT_FILE:-trace.txt}; \
	read -p "Enter OUTPUT_FILE (default: dram.txt): " OUTPUT_FILE; \
	OUTPUT_FILE=$${OUTPUT_FILE:-dram.txt}; \
	$(VSIM) $(VSIM_FLAGS) +define+INPUT_FILE=$$INPUT_FILE +define+OUTPUT_FILE=$$OUTPUT_FILE $(TOP_MOD)
debug :
	$(VLOG) $(VLOG_FLAGS) $(SRC)+define+DEBUG
run : compile

	$(VSIM) $(VSIM_FLAGS) +define+INPUT_FILE=$$INPUT_FILE +define+OUTPUT_FILE=$$OUTPUT_FILE $(TOP_MOD) -do "run -all"




.PHONY: all compile simulate debug
