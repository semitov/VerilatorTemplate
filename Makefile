# file: Makefile
# author: Pietro Alberto Levo
# date: 1st April 2026
# last update: 4th May 2026
# follow the comments in this file to properly configure your project

####################################################################################
# MAIUSC inside boxes like this one are IMPORTANT and need changes when working!!! #
####################################################################################

# Colors
RED     = \033[0;31m
GREEN   = \033[0;32m
YELLOW  = \033[1;33m
BLUE    = \033[0;34m
MAGENTA = \033[0;35m
CYAN    = \033[0;36m
NC      = \033[0m

#####################
# SELECT TOP ENTITY #
TOP = dff_async
#####################


SRC_DIR = src
TB_DIR = tb
BUILD = build
OBJ = obj_dir
COV = coverage

#############################################
# SOURCE FILES, ALWAYS ORDER THEM BOTTOM UP #
SRCS = nand2.v dff_async.v
SRCS := $(addprefix $(SRC_DIR)/,$(SRCS))
#############################################


####################################################
# TESTBENCH FILES (PUT ONLY THE ONE THAT YOU NEED) #
TB_SRCS = tb_dff.cpp
TB_SRCS := $(addprefix $(TB_DIR)/,$(TB_SRCS))
####################################################

# Comando di default
all: run wave


# Static analysis
analyze:
	@echo -e "$(CYAN)[LINT] Analyzing $(TOP) in STRICT VERILOG MODE...$(NC)"
	@if [ ! -f "$(TB_SRCS)" ]; then \
		echo -e "$(RED)[ERROR] Testbench $(TB_SRCS) not found$(NC)"; exit 1; \
	fi
	verilator \
		--cc $(SRCS) \
		--exe $(TB_SRCS) \
		--top-module $(TOP) \
		--lint-only \
		--error-limit 1 \
		-Wall \
		-Wpedantic \
		-Werror-IMPLICIT \
		-Werror-UNDRIVEN \
		-Werror-PINMISSING \
		-Werror-LATCH \
		-Werror-CASEINCOMPLETE \
		-Werror-BLKSEQ \
		-Werror-BLKANDNBLK \
		-Wno-UNOPTFLAT \
		-Wno-WIDTH
	@echo -e "$(GREEN)[LINT] No issues found$(NC)"


# Compilation with verilator
compile: analyze
	@echo -e "$(CYAN)[INFO] Compiling $(TOP)...$(NC)"
	@mkdir -p $(OBJ)/$(BUILD)
	@if [ ! -f "$(TB_SRCS)" ]; then \
 		echo -e "$(RED)[ERROR] Testbench $(TB_SRCS) not found$(NC)"; exit 1; \
	fi
	verilator \
		--cc $(SRCS) \
		--exe $(TB_SRCS) \
		--top-module $(TOP) \
		--trace --trace-structs\
		--assert \
		--error-limit 5 \
		-Wall \
		-Wno-UNOPTFLAT \
		-Wno-WIDTH \
		--build -o $(BUILD)/sim
	@echo -e "$(GREEN)[OK] Compilation completed$(NC)"


# execute simulation
run: compile
	@echo -e "$(CYAN)[INFO] Running simulation...$(NC)"
	./$(OBJ)/$(BUILD)/sim
	@echo -e "$(GREEN)[OK] Simulation finished$(NC)"


# Build simulation with coverage enabled, see if all signals and has been tested
coverage:
	@echo -e "$(CYAN)[COVERAGE] Building simulation with coverage enabled...$(NC)"
	@mkdir -p $(COV)
	@mkdir -p $(OBJ)/$(BUILD)
	verilator \
			--cc $(SRCS) \
			--exe $(TB_SRCS) \
			--coverage \
			--top-module $(TOP) \
			--trace --trace-structs \
			--assert \
			--error-limit 1 \
			-Wall -Wno-UNOPTFLAT -Wno-WIDTH \
			--build -o $(BUILD)/sim_cov
	@echo -e "$(CYAN)[COVERAGE] Running simulation...$(NC)"
	./$(OBJ)/$(BUILD)/sim_cov
	@echo -e "$(CYAN)[COVERAGE] Generating TXT report...$(NC)"
	verilator_coverage --write-info  $(COV)/coverage.txt  $(COV)/sim_cov.dat
	@echo -e "$(GREEN)[OK] Coverage report saved in $(COV)/coverage.txt$(NC)"


# open GTKWave
wave: run
	@echo -e "$(CYAN)[INFO] Opening GTKWave...$(NC)"
	gtkwave dump.vcd --script auto.tcl &


# yosys pre-synthesis schematic
rtl: 
	@mkdir -p netlist
	yosys -p " \
		read_verilog $(SRCS); \
		hierarchy -check -top $(TOP); \
		proc; \
		opt; \
		opt_clean; \
		write_json netlist/netlist.json"
	npx netlistsvg netlist/netlist.json -o schematic.svg
	@sed -i 's/<svg /<svg style="background-color:white" /' schematic.svg


cov-clean:
	rm -f  $(COV)/*

# clean build
clean:
	@echo -e "$(YELLOW)[CLEAN] Removing build files...$(NC)"
	rm -rf $(OBJ) $(BUILD) *.vcd dump.vcd schematic.svg netlist
	@echo -e "$(GREEN)[OK] Clean completed$(NC)"

help:
	@echo "_______________________________________"
	@echo "|------- GOOD MORNING ENGINEER -------|"
	@echo "| Below the commands of this makefile |"
	@echo "|_____________________________________|"
	@echo "| make all: one to rule them all      |"
	@echo "| make analyze: static analysis       |"
	@echo "| make compile: compile files         |"
	@echo "| make run: execute simulation        |"
	@echo "| make wave: open gtkwave             |"
	@echo "| make rtl: create the schematic      |"
	@echo "| make coverage: build with coverage  |"
	@echo "| make cov-clean: clean coverage rpt  |"
	@echo "| make clean: clean build             |"
	@echo "|_____________________________________|"


.PHONY: all compile run wave rtl coverage cov-clean clean
