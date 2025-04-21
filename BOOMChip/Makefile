SHELL := /bin/bash

all: copy_rtl

add_config: BOOMChip.scala
	ln -sf ${PWD}/BOOMChip.scala ../chipyard/generators/chipyard/src/main/scala/config
	mkdir -p ../chipyard/generators/rocket-chip/src/main/scala/cxl
	ln -sf ${PWD}/AgilexCXL.scala ../chipyard/generators/rocket-chip/src/main/scala/cxl
	ln -sf ${PWD}/package.scala ../chipyard/generators/rocket-chip/src/main/scala/cxl
        ln -sf ${PWD}/AgilexCXLBlackBox.v ../chipyard/generators/rocket-chip/src/main/scala/cxl
bootrom_replace: bootrom
	cp -r bootrom ../chipyard/generators/testchipip/src/main/resources/testchipip/bootrom

compile: add_config bootrom_replace
	source ../chipyard/env.sh
	cd ../chipyard/sims/verilator && make verilog CONFIG=BOOMChip

copy_rtl:
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/gen-collateral/chipyard.harness.TestHarness.BOOMChip.top.mems.v ../quartus/ip/BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.mems.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.v ../quartus/ip/BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/ClockDividerN.sv ../quartus/ip/BOOMChip/ClockDividerN.sv
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/EICG_wrapper.v ../quartus/ip/BOOMChip/EICG_wrapper.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/IOCell.v ../quartus/ip/BOOMChip/IOCell.v
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/plusarg_reader.v ../quartus/ip/BOOMChip/plusarg_reader.v
