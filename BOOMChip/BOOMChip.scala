package chipyard

import org.chipsalliance.cde.config.{Config, Parameters}

/* ------------------------- */

class BOOMConfig
  extends Config(
    // Add CXL-specific configurations with default parameters
    new WithAgilexCXL() ++

      // IO Binders for connecting to external interfaces
      new chipyard.iobinders.WithAXI4MemPunchthrough ++

      // Standard harness binders for simulation
      new chipyard.harness.WithUARTAdapter ++
      new chipyard.harness.WithBlackBoxSimMem ++
      new chipyard.harness.WithGPIOTiedOff ++
      new chipyard.harness.WithSimSPIFlashModel ++
      new chipyard.harness.WithSimAXIMMIO ++
      new chipyard.harness.WithTieOffInterrupts ++
      new chipyard.harness.WithTieOffL2FBusAXI ++

      // Standard IO binders
      new chipyard.iobinders.WithAXI4MMIOPunchthrough ++
      new chipyard.iobinders.WithL2FBusAXI4Punchthrough ++
      new chipyard.iobinders.WithBlockDeviceIOPunchthrough ++
      new chipyard.iobinders.WithNICIOPunchthrough ++
      new chipyard.iobinders.WithSerialTLIOCells ++
      new chipyard.iobinders.WithUARTIOCells ++
      new chipyard.iobinders.WithGPIOCells ++
      new chipyard.iobinders.WithTraceIOPunchthrough ++
      new chipyard.iobinders.WithExtInterruptIOCells ++

      // Clock domain setup
      new chipyard.config.WithPeripheryBusFrequency(10.0) ++
      new chipyard.config.WithMemoryBusFrequency(100.0) ++
      new chipyard.config.WithPeripheryBusFrequency(100.0) ++

      // System configuration
      new chipyard.config.WithSystemBusWidth(128) ++
      new chipyard.config.WithBootROM ++
      new chipyard.config.AbstractConfig
  )

// Function to create a configuration with CXL support
class WithAgilexCXL(params: AgilexCXLParams = AgilexCXLParams()) extends Config((site, here, up) => {
  case AgilexCXLKey => params
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with CanHaveAgilexCXL
})

// Configuration to include CXL wrapper
class WithAgilexCXLWrapper extends Config((site, here, up) => {
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with CanHaveAgilexCXL with CanHaveAgilexCXLWrapper
})

class BOOMChip
  extends Config(
    // BOOM核心配置
    new boom.v4.common.WithNLargeBooms(1) ++
      new chipyard.config.WithSystemBusWidth(128) ++
      new WithAgilexCXL ++
      new WithAgilexCXLWrapper ++
      new BOOMConfig
  )
