package chipyard

import org.chipsalliance.cde.config.{Config, Parameters}
import chipyard.cxl.{AgilexCXLKey, AgilexCXLParams, CanHaveAgilexCXL, CanHaveAgilexCXLWrapper}
import chipyard.harness.BuildTop
import freechips.rocketchip.subsystem.{BaseSubsystem, HasTileLinkLocations}

/* ------------------------- */

class BOOMConfig
  extends Config(
    //     IO Binders for connecting to external interfaces
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
      new chipyard.iobinders.WithTraceIOPunchthrough ++
      new chipyard.iobinders.WithExtInterruptIOCells ++

      // System configuration
      new chipyard.config.WithSystemBusWidth(128) ++
      new chipyard.config.WithBootROM
  )

// We subclass the normal ChipTop module, mixing in the CXL traits
class SystemWithCXL(implicit p: Parameters)
  extends ChipyardSystem()(p)
    with CanHaveAgilexCXL
    with CanHaveAgilexCXLWrapper
// 2) Override BuildTop (NOT BuildSystem) so that the harness instantiates your ChipTopWithCXL:
class WithCXLConfig extends Config(
  // Step A: pull in every default from AbstractConfig
  new chipyard.config.AbstractConfig++

  // Step B: then bind our CXL key and swap in the subclassed system
  new Config((site, here, up) => {
    case AgilexCXLKey => AgilexCXLParams()                                     // non‑null defaults
    case BuildSystem  => (p: Parameters) => new chipyard.SystemWithCXL()(p)    // PRCI + our mixins
  })
)

// 3) Then put that Config _last_ in your BOOMChip chain:
class BOOMChip extends Config(
  new boom.v4.common.WithNLargeBooms(1) ++
    new BOOMConfig ++ // includes AbstractConfig
    new WithCXLConfig // ← override BuildTop _after_ AbstractConfig
)
