SHELL := /bin/bash
QIPDIR = ../quartus/hardware_test_design/IP/BOOMChip
F = ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.f
SV = $(QIPDIR)/chipyard.harness.TestHarness.BOOMChip.top.sv

all: copy_rtl

# rule to build the .sv
$(SV): $(F)
	@echo "→ Ensuring $(QIPDIR) exists"
	@mkdir -p $(@D)
	@echo "→ Concatenating all .sv from $< into $@"
	@xargs cat < $< > $@

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

copy_rtl: compile ../quartus/hardware_test_design/IP/BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.sv 
	cp ../chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.BOOMChip/gen-collateral/chipyard.harness.TestHarness.BOOMChip.top.mems.v ../quartus/hardware_test_design/IP/BOOMChip/chipyard.harness.TestHarness.BOOMChip.top.mems.v