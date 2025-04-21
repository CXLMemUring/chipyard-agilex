package chipyard

import boom.v4.common.WithNLargeBooms
import org.chipsalliance.cde.config.{Config, Parameters}
import chipyard.cxl.{AgilexCXLKey, AgilexCXLParams, CanHaveAgilexCXL, CanHaveAgilexCXLWrapper}
import chipyard.harness.{BuildTop, HasHarnessInstantiators}
import chipyard.iobinders.{HasIOBinders, Port}
import chisel3.{Bool, Bundle, Clock, IO, Input, Output, RawModule, Reset}
import freechips.rocketchip.diplomacy.LazyModule
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
      new chipyard.config.WithBootROM ++
      new chipyard.config.AbstractConfig
  )
class WithCXLSystem extends Config((site, here, up) => {
    case AgilexCXLKey => AgilexCXLParams()
      case BuildSystem =>
      (p: Parameters) => new chipyard.ChipyardSystem()(p)
        with CanHaveAgilexCXL
        with CanHaveAgilexCXLWrapper
  })
/**
 * 2) Wrap the existing ChipTop in I/O binders + harness instantiators,
 *    catching that early `None.get` on ports.
 */
class ChipTopWithCXL(implicit p: Parameters)
  extends chipyard.ChipTop()(p)
    with HasIOBinders
    with HasHarnessInstantiators {

  // ports() in HasIOBinders actually returns Seq[Port[_]]
  override def ports: Seq[chipyard.iobinders.Port[_]] = {
    try super.ports
    catch { case _: NoSuchElementException => Seq.empty }
  }

  // harness signals (in a RawModule you must declare IOs yourself)
  val harnessClock   = IO(Input(Clock()))
  val harnessReset   = IO(Input(Bool()))
  val harnessSuccess = IO(Output(Bool()))

  // tie into the harness trait:
  override def referenceClockFreqMHz: Double = 100.0
  override def referenceClock: Clock          = harnessClock
  override def referenceReset: Reset          = harnessReset.asAsyncReset
  override def success: Bool                  = harnessSuccess
  override def instantiateChipTops(): Seq[LazyModule] = {
    // <-- name this local val exactly "ChipTop"
    val ChipTop = LazyModule(
      new ChipyardSystem()(p)
        with CanHaveAgilexCXL
        with CanHaveAgilexCXLWrapper
    )

    Seq(ChipTop)
  }
}

/**
 * 3) Override BuildTop so the harness tops out on your ChipTopWithCXL.
 */
class WithCXLTop extends Config((site, here, up) => {
  case BuildTop => (p: Parameters) => new ChipTopWithCXL()(p)
})

/**
 * 4) Finally compose your BOOMChip config:
 *    - One BOOM core
 *    - CXL‑augmented subsystem
 *    - CXL‑wrapped harness top
 *    - Your BOOMConfig (I/O binders, bootROM, etc.)
 */
class BOOMChip extends Config(
  new boom.v4.common.WithNLargeBooms(1) ++
    new WithCXLSystem ++    // subsystem has CXL
    new WithCXLTop ++       // top has harness & IO binders
    new BOOMConfig          // your existing I/O binders, BootROM, etc.
)