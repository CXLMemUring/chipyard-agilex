package chipyard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config.{Parameters, Field}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.subsystem.{MBUS}
import freechips.rocketchip.devices.tilelink._

// Parameters specific to Intel Agilex CXL IP
case class AgilexCXLParams(
  base: BigInt = 0x8000_0000L,
  size: BigInt = 0x4000_0000L, // 1GB
  beatBytes: Int = 8,
  idBits: Int = 4,
  cxlVersion: Int = 2 // CXL 2.0
)

// Key to configure the CXL adapter
case object AgilexCXLKey extends Field[AgilexCXLParams]

// LazyModule for Intel CXL adapter
class AgilexCXLAdapter(params: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  // Create TileLink Manager Node for the CXL memory region
  val node = TLManagerNode(Seq(TLSlavePortParameters.v1(
    managers = Seq(TLSlaveParameters.v1(
      address            = Seq(AddressSet(params.base, params.size-1)),
      resources          = (new SimpleDevice("intel-cxl", Seq("intel,agilex-cxl"))).reg("mem"),
      regionType         = RegionType.UNCACHED, // CXL memory is treated as uncached initially
      executable         = true,
      supportsGet        = TransferSizes(1, params.beatBytes * 8),
      supportsPutFull    = TransferSizes(1, params.beatBytes * 8),
      supportsPutPartial = TransferSizes(1, params.beatBytes * 8),
      fifoId             = Some(0)
    )),
    beatBytes = params.beatBytes
  )))

  // Create AXI4 Client Node to connect to Intel Agilex CXL IP
  val axi4Node = AXI4MasterNode(Seq(AXI4MasterPortParameters(
    masters = Seq(AXI4MasterParameters(
      name = "agilex-cxl-adapter",
      id   = IdRange(0, 1 << params.idBits)
    ))
  )))

  // Connect TileLink to AXI4 with appropriate conversions
  axi4Node := 
    AXI4UserYanker() := 
    AXI4Deinterleaver(params.beatBytes * 8) := 
    TLToAXI4() := 
    TLFragmenter(params.beatBytes, params.beatBytes * 8) := 
    TLBuffer() := 
    node

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    // The AXI4 bundle is available as outer.axi4Node.out(0)._1
    val (axi4Bundle, _) = axi4Node.out(0)
    
    // Debug signals, can be removed in production
    dontTouch(axi4Bundle)
  }
}

// Mixin trait to add CXL support to a Chipyard system
trait CanHaveAgilexCXL { this: BaseSubsystem =>
  val cxlParams = p(AgilexCXLKey)
  
  // Create the adapter
  val cxlAdapter = LazyModule(new AgilexCXLAdapter(cxlParams))
  
  // Connect to memory bus (MBUS)
  val mbusWrapper = this.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(MBUS)
  cxlAdapter.node := mbusWrapper.outwardNode
}

// Function to create a configuration with CXL support
class WithAgilexCXL(params: AgilexCXLParams = AgilexCXLParams()) extends Config((site, here, up) => {
  case AgilexCXLKey => params
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with CanHaveAgilexCXL
}) 