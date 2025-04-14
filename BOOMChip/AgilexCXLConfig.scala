package chipyard

import freechips.rocketchip.config.{Config}
import freechips.rocketchip.devices.tilelink.{BootROMLocated}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.util.{HeterogeneousBag}
import freechips.rocketchip.prci._

// IO Binder for handling AXI4 connections to CXL IP
class WithCXLAXI4IOPunchthrough extends Config((site, here, up) => {
  case ExtMem => Some(MemoryPortParams(MasterPortParams(
    base = x"8000_0000", 
    size = x"4000_0000", // 1GB
    beatBytes = 8,
    idBits = 4
  )))
})

// Basic CXL configuration for the Agilex FPGA
class AgilexCXLConfig extends Config(
  // Add CXL-specific configurations with default parameters
  new WithAgilexCXL() ++
  new WithCXLAXI4IOPunchthrough ++
  
  // IO Binders for connecting to external interfaces
  new chipyard.iobinders.WithAXI4MemPunchthrough ++
  
  // Standard harness binders for simulation
  new chipyard.harness.WithUARTAdapter ++                       
  new chipyard.harness.WithBlackBoxSimMem ++                    
  new chipyard.harness.WithSimSerial ++                         
  new chipyard.harness.WithSimDebug ++                         
  new chipyard.harness.WithGPIOTiedOff ++                       
  new chipyard.harness.WithSimSPIFlashModel ++                  
  new chipyard.harness.WithSimAXIMMIO ++                        
  new chipyard.harness.WithTieOffInterrupts ++                  
  new chipyard.harness.WithTieOffL2FBusAXI ++                   
  new chipyard.harness.WithTieOffCustomBootPin ++

  // Standard IO binders
  new chipyard.iobinders.WithAXI4MMIOPunchthrough ++ 
  new chipyard.iobinders.WithL2FBusAXI4Punchthrough ++
  new chipyard.iobinders.WithBlockDeviceIOPunchthrough ++
  new chipyard.iobinders.WithNICIOPunchthrough ++
  new chipyard.iobinders.WithSerialTLIOCells ++
  new chipyard.iobinders.WithUARTIOCells ++
  new chipyard.iobinders.WithGPIOCells ++
  new chipyard.iobinders.WithSPIIOCells ++
  new chipyard.iobinders.WithTraceIOPunchthrough ++
  new chipyard.iobinders.WithExtInterruptIOCells ++

  // Clock domain setup
  new chipyard.config.WithPeripheryBusFrequencyAsDefault ++
  new chipyard.config.WithMemoryBusFrequency(100.0) ++
  new chipyard.config.WithPeripheryBusFrequency(100.0) ++
  
  // System configuration 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.WithBootROM ++
  new chipyard.WithMulticlockCoherentBusTopology ++
  new freechips.rocketchip.system.BaseConfig
)

// Configuration with BlackBox wrapper for FPGA implementation
class AgilexCXLWithWrapperConfig extends Config(
  new WithAgilexCXLWrapper() ++
  new AgilexCXLConfig
)

// BOOM with Intel Agilex CXL configurations for simulation
class SmallBoomWithCXLConfig extends Config(
  new boom.v3.common.WithNSmallBooms(1) ++
  new AgilexCXLConfig
)

class MediumBoomWithCXLConfig extends Config(
  new boom.v3.common.WithNMediumBooms(1) ++
  new AgilexCXLConfig
)

class LargeBoomWithCXLConfig extends Config(
  new boom.v3.common.WithNLargeBooms(1) ++
  new AgilexCXLConfig
)

// BOOM with Intel Agilex CXL configurations for FPGA implementation with BlackBox wrapper
class SmallBoomWithCXLWrapperConfig extends Config(
  new boom.v3.common.WithNSmallBooms(1) ++
  new AgilexCXLWithWrapperConfig
)

class MediumBoomWithCXLWrapperConfig extends Config(
  new boom.v3.common.WithNMediumBooms(1) ++
  new AgilexCXLWithWrapperConfig
)

class LargeBoomWithCXLWrapperConfig extends Config(
  new boom.v3.common.WithNLargeBooms(1) ++
  new AgilexCXLWithWrapperConfig
)

// Default configuration uses a Large BOOM with CXL
class BoomCXLChip extends Config(
  new LargeBoomWithCXLConfig
)

// Default configuration for FPGA implementation
class BoomCXLFPGAChip extends Config(
  new LargeBoomWithCXLWrapperConfig
) 