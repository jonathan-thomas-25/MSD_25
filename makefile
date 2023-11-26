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
	$(VSIM) $(VSIM_FLAGS) $(TOP_MOD)
run : compile simulate



.PHONY: all compile simulate
