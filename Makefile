# file: Makefile
# author: Pietro Alberto Levo
# date: 1st April 2026
# follow the comments in this file to properly configure your project

# select top entity
TOP = dff_async

SRC_DIR = src
TB_DIR = tb
BUILD = build

# source files, ALWAYS order them bottom up
SRCS = nand2.v dff_async.v
SRCS := $(addprefix $(SRC_DIR)/,$(SRCS))

# testbench files (put only the one that you need)
TB_SRCS = tb_dff.cpp
TB_SRCS := $(addprefix $(TB_DIR)/,$(TB_SRCS))

# Comando di default
all: run

# Compilation with verilator
compile:
	mkdir -p obj_dir/$(BUILD)
	verilator -Wall --trace --cc $(SRCS) \
		--exe $(TB_SRCS) \
		--top-module $(TOP) \
		--build -o $(BUILD)/sim

# execute simulation
run: compile
	./obj_dir/$(BUILD)/sim

# open GTKWave
wave:
	gtkwave dump.vcd --script auto.tcl &

# yosys
rtl: 
	@mkdir -p netlist
	yosys -p " \
		read_verilog $(SRCS); \
		hierarchy -check -top $(TOP); \
		proc; \
		opt; \
		wreduce; \
		opt_clean; \
		prep -top $(TOP); \
		write_json netlist/netlist.json"
	npx netlistsvg netlist/netlist.json -o schematic.svg
	@sed -i 's/<svg /<svg style="background-color:white" /' schematic.svg

# clean build
clean:
	rm -rf obj_dir $(BUILD) *.vcd dump.vcd schematic.dot schematic.svg netlist

help:
	@echo "_______________________________________"
	@echo "|------- GOOD MORNING ENGINEER -------|"
	@echo "| Below the commands of this makefile |"
	@echo "|_____________________________________|"
	@echo "| make all: compile and simulate      |"
	@echo "| make wave: open gtkwave             |"
	@echo "| make rtl: create the schematic      |"
	@echo "| make compile: compile files         |"	
	@echo "| make run: execute simulation        |"
	@echo "| make clean: clean build             |"
	@echo "|_____________________________________|"

.PHONY: all compile run wave rtl clean
