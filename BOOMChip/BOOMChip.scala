package chipyard

import boom.v4.common.{BoomCoreParams, BoomMultiIOModule, BoomTile, BoomTileParams}
import chipyard.config.{WithBootROM, WithSystemBusWidth}
import org.chipsalliance.cde.config.{Config, Field, Parameters}
import freechips.rocketchip.subsystem.{MBUS, _}
import chipyard.cxl._
import chipyard.harness.{BuildTop, WithSimAXIMem, WithUARTAdapter}
import chipyard.iobinders.{IOCellKey, OverrideIOBinder, UARTPort, WithUARTIOCells}
import chipyard.iocell.{DigitalInIOCell, DigitalInIOCellBundle, GenericAnalogIOCell, GenericDigitalGPIOCell, GenericDigitalOutIOCell, IOCellTypeParams}
import chisel3.Module.clock
import chisel3._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.rocket.{BTBParams, DCacheParams, ICacheParams}
import freechips.rocketchip.tile.{TileKey, TileVisibilityNodeKey}
import freechips.rocketchip.tilelink.{TLClientNode, TLEphemeralNode, TLIdentityNode, TLManagerNode, TLMasterParameters, TLMasterPortParameters, TLNode, TLSlaveParameters, TLSlavePortParameters, TLWidthWidget}

// -----------------------------------------------------------------------------
// 1) Simple CXL configuration binding
// -----------------------------------------------------------------------------
class WithCXLBasic extends Config((site, here, up) => {
  case AgilexCXLKey => AgilexCXLParams()
})

class BOOMWithCXLSystem(implicit p: Parameters) extends ChipyardSystem {
  // 使用 Option 处理 CXL 参数
  val cxlParams = p(AgilexCXLKey)
  val cxlAdapter = LazyModule(new AgilexCXLAdapter(cxlParams))

  // 获取内存总线并连接
  //  private val sbus = locateTLBusWrapper(SBUS)
  //  sbus.coupleTo("cxl") { bus =>
  //    cxlAdapter.node := bus
  //  }
  private val mbus = locateTLBusWrapper(MBUS)
  mbus.coupleTo("cxl") { bus => cxlAdapter.node := bus }
  val edge = mbus.busView // now non‐empty, because WithDefaultMemPort/WithSimAXIMem put a manager there
}

class WithOneBoomTile extends Config((site, here, up) => {
  case TileKey =>
    BoomTileParams(
      name = Some("boom0"),
      core = BoomCoreParams(),
      icache = Some(ICacheParams()),
      dcache = Some(DCacheParams()),
      btb = Some(BTBParams()),
      tileId = 1

    )
})
final class TileVisibilityAdapter(implicit p: Parameters) extends LazyModule {
  val node = TLIdentityNode()                  // nothing but a TL-to-TL shim

  lazy val module = new LazyModuleImp(this) {
    // no RTL in the shim itself
  }
}
//------------------------------------------------------------
// 3. Config fragment: allocate the adapter once and export its node
//------------------------------------------------------------
final class WithTileVisibility extends Config((site, here, up) => {
  case TileVisibilityNodeKey =>
    // Need to create Parameters object from Config
    implicit val p: Parameters = Parameters.root(site)
    val visLM = LazyModule(new TileVisibilityAdapter)

    // Instead of trying to connect to another bus, create a standalone
    // "dummy" node that can provide the necessary parameters
    val dummyClientNode = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLMasterParameters.v1(
      name = "dummy-client",
      sourceId = IdRange(0, 1),
      requestFifo = false
    )))))

    val dummyManagerNode = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address = Seq(AddressSet(0x0, 0xffff)),
      regionType = RegionType.UNCACHED,
      executable = true,
      supportsGet = TransferSizes(1, 64),
      supportsPutFull = TransferSizes(1, 64)
    )), beatBytes = 8)))

    // Connect them to the identity node to provide parameters but
    // don't actually use these connections in hardware
    visLM.node := dummyClientNode
    dummyManagerNode := visLM.node

    visLM.node
})
/**
 * A singleton so we can refer to the same LazyModule from Config
 * (Config runs at Scala‐compile time, before Module elaboration).
 */

// -----------------------------------------------------------------------------
// 4) Build-time configuration
// -----------------------------------------------------------------------------
// Change BOOMWithCXLTop to extend LazyModule
class BOOMWithCXLTop(implicit p: Parameters) extends LazyModule {
  // 1. Instantiate the system as a LazyModule
  private val lazySys = LazyModule(new BOOMWithCXLSystem)

  // 2. Make any connections between lazy modules here

  // 3. Define the module implementation
  lazy val module = new LazyModuleImp(this) {
    // Implementation details go here
  }
}



class BOOMChip extends Config(
  new WithBootROM ++
    new WithDefaultMemPort ++
    new WithSimAXIMem ++
    new WithOneBoomTile ++
    new WithCXLBasic ++
    new boom.v4.common.WithNLargeBooms(1) ++
    new WithSystemBusWidth(128) ++
    new WithCoherentBusTopology ++
    new WithMemoryBusFrequency(500.0) ++
    new WithSystemBusFrequency(500.0) ++
    new WithPeripheryBusFrequency(500.0) ++
    new WithControlBusFrequency(500.0) ++
    new WithFrontBusFrequency(500.0) ++
    new WithNBanks(1) ++
    new WithTileVisibility ++
    // now your BuildTop override will actually stick:
    new Config((site, here, up) => {
      case BuildTop => (p: Parameters) => new BOOMWithCXLTop()(p)
    }) ++
    // <<<<< move AbstractConfig *before* your BuildTop override >>>>>
    new chipyard.config.AbstractConfig


)