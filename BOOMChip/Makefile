SHELL := /bin/bash

all: copy_rtl

add_config: BOOMChip.scala
	cp BOOMChip.scala ../chipyard/generators/chipyard/src/main/scala/config

bootrom_replace: bootrom
	cp -r bootrom ../chipyard/generators/testchipip/src/main/resources/testchipip/bootrom

compile: add_config bootrom_replace
	source ../chipyard/env.sh
	cd ../chipyard/sims/verilator && make verilog CONFIG=BOOMChip

copy_rtl:
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/chipyard.TestHarness.BOOMChip.top.mems.v ../quartus/ip/BOOMChip/chipyard.TestHarness.BOOMChip.top.mems.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/chipyard.TestHarness.BOOMChip.top.v ../quartus/ip/BOOMChip/chipyard.TestHarness.BOOMChip.top.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/ClockDividerN.sv ../quartus/ip/BOOMChip/ClockDividerN.sv
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/EICG_wrapper.v ../quartus/ip/BOOMChip/EICG_wrapper.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/IOCell.v ../quartus/ip/BOOMChip/IOCell.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.TestHarness.BOOMChip/plusarg_reader.v ../quartus/ip/BOOMChip/plusarg_reader.v

gen_fsbl_mif: FSBL/FSBL.S
	cd FSBL && make clean && make && make mif
	cp FSBL/FSBL.mif ../quartus/onchip_memory.mif