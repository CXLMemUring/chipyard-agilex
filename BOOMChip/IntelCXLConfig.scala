package chipyard

import freechips.rocketchip.config.{Config}
import freechips.rocketchip.devices.tilelink.{BootROMLocated}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.util.{HeterogeneousBag}
import freechips.rocketchip.prci._

// Configuration for Intel Agilex CXL connectivity
class WithIntelAgilexCXLBridge extends Config((site, here, up) => {
  case SystemBusKey => up(SystemBusKey, site).copy(beatBytes = 8) // 64-bit bus for CXL
})

// Default CXL parameters
class WithDefaultCXLParams extends Config((site, here, up) => {
  case IntelCXLKey => IntelCXLParams(
    base = 0x8000_0000L,
    size = 0x4000_0000L, // 1GB
    beatBytes = 8,
    idBits = 4,
    cxlVersion = 2
  )
})

// Harness binder for the CXL interface
class WithCXLAXI4MemPunchthrough extends Config((site, here, up) => {
  case ExtMem => Some(MemoryPortParams(MasterPortParams(
    base = x"8000_0000", 
    size = x"4000_0000", // 1GB
    beatBytes = 8,
    idBits = 4
  )))
})

// Configuration that uses a BOOM core with CXL interface
class BoomCXLConfig extends Config(
  // Add CXL-specific configurations
  new WithCXLAXI4MemPunchthrough ++
  new WithIntelAgilexCXLBridge ++
  new WithDefaultCXLParams ++

  // IO Binders for AXI4 interface to CXL
  new chipyard.iobinders.WithAXI4MemPunchthrough ++
  
  // Standard harness binders that remain unchanged
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
  
  // Use BOOM core with appropriate memory configuration
  new boom.v3.common.WithNLargeBooms(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++ // Make sure we have adequate system bus width
  new chipyard.config.WithBootROM ++
  new chipyard.WithMulticlockCoherentBusTopology ++
  new freechips.rocketchip.system.BaseConfig
)

// Extension of the BoomCXLConfig that adds our custom CXL adapter
class BoomCXLWithAdapterConfig extends Config(
  new WithIntelCXLAdapter(IntelCXLParams()) ++
  new BoomCXLConfig
)

// This is a concrete instantiable class for a BOOM-based system with CXL bridge
class BoomIntelCXLChip extends Config(
  new BoomCXLWithAdapterConfig
)

// Create a complete system with BOOM and Intel CXL using direct connections
class WithBoomAndCXLSystem extends Config((site, here, up) => {
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with HasIntelCXLAdapter
})

// Create a complete system with BOOM and Intel CXL using BlackBox bridge
class WithBoomAndCXLBlackBoxSystem extends Config((site, here, up) => {
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with HasIntelCXLAdapter with WithIntelCXLBlackBoxBridge
})

// Complete system configuration that can be simulated
class BoomCXLSystemConfig extends Config(
  new WithBoomAndCXLSystem ++
  new BoomIntelCXLChip
)

// Complete system configuration that can be implemented on Intel Agilex FPGA
class BoomCXLBlackBoxSystemConfig extends Config(
  new WithBoomAndCXLBlackBoxSystem ++
  new BoomIntelCXLChip
) 