# BOOM Core with Intel Agilex CXL Integration

This directory contains adapters and configurations to connect Chipyard's BOOM (Berkeley Out-of-Order Machine) cores to Intel Agilex FPGA using CXL (Compute Express Link) interface.

## Overview

- BOOM is an advanced open-source, out-of-order RISC-V core that provides high performance
- Intel Agilex FPGAs support CXL which enables memory coherence between processors and accelerators
- This integration allows BOOM cores to communicate with accelerators or memory expansion devices over CXL

## Components

1. **AgilexCXLAdapter.scala**: TileLink to AXI4 conversion for BOOM and CXL protocol handling
2. **AgilexCXLWrapper.scala**: BlackBox wrapper for Intel Agilex CXL IP integration
3. **AgilexCXLConfig.scala**: Configurations for connecting BOOM cores to Agilex CXL
4. **BOOMChip.scala**: Basic BOOM configurations with different core sizes

## Available Configurations

### Simulation Configurations (without BlackBox wrapper)

- `SmallBoomWithCXLConfig`: Small BOOM core with CXL connectivity
- `MediumBoomWithCXLConfig`: Medium BOOM core with CXL connectivity
- `LargeBoomWithCXLConfig`: Large BOOM core with CXL connectivity
- `BoomCXLChip`: Default configuration (uses Large BOOM)

### FPGA Implementation Configurations (with BlackBox wrapper)

- `SmallBoomWithCXLWrapperConfig`: Small BOOM with BlackBox CXL wrapper for FPGA 
- `MediumBoomWithCXLWrapperConfig`: Medium BOOM with BlackBox CXL wrapper for FPGA
- `LargeBoomWithCXLWrapperConfig`: Large BOOM with BlackBox CXL wrapper for FPGA
- `BoomCXLFPGAChip`: Default FPGA implementation configuration

## Usage

### For Simulation

To build the design for simulation, use:

```bash
cd chipyard
./scripts/build-toolchains.sh  # If not already built
source env.sh

# Generate Verilog for simulation
make -C sims/verilator CONFIG=BoomCXLChip
```

### For FPGA Implementation

```bash
cd chipyard
./scripts/build-toolchains.sh  # If not already built
source env.sh

# Generate Verilog for FPGA implementation
make -C fpga/intel CONFIG=BoomCXLFPGAChip
```

## Intel Agilex CXL IP Integration

To use this adapter with Intel Agilex CXL IP:

1. Obtain Intel Agilex CXL IP from Intel
2. Update the `AgilexCXLBlackBox` parameters and interface to match the IP
3. Create a Verilog wrapper if necessary to interface with Intel's IP
4. Use the BlackBox wrapper version of the configuration for FPGA implementation

## Memory Map

The CXL memory space is mapped at:
- Base: 0x8000_0000
- Size: 0x4000_0000 (1GB)

## Notes on Performance

- Use LargeBOOM for best performance
- Adjust system and memory bus frequencies as needed for CXL protocol requirements
- CXL memory region is currently marked as uncached - modify if using CXL.cache protocol 