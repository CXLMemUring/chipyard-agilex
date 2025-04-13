package chipyard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config.{Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.subsystem.{MBUS}
import freechips.rocketchip.devices.tilelink._

// Parameters specific to Intel Agilex CXL IP
case class IntelCXLParams(
  base: BigInt = 0x8000_0000L,
  size: BigInt = 0x4000_0000L, // 1GB
  beatBytes: Int = 8,
  idBits: Int = 4,
  // Add any other parameters specific to Intel Agilex CXL
  cxlVersion: Int = 2 // CXL 2.0
)

// LazyModule for Intel CXL adapter
class IntelCXLAdapter(params: IntelCXLParams)(implicit p: Parameters) extends LazyModule {
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
      name = "intel-cxl-adapter",
      id   = IdRange(0, 1 << params.idBits)
    ))
  )))

  // Connect TileLink to AXI4
  axi4Node := AXI4UserYanker() := AXI4Deinterleaver(params.beatBytes * 8) := TLToAXI4() := TLFragmenter(params.beatBytes, params.beatBytes * 8) := node

  lazy val module = new IntelCXLAdapterModuleImp(this)
}

class IntelCXLAdapterModuleImp(outer: IntelCXLAdapter) extends LazyModuleImp(outer) {
  // The AXI4 bundle is available as outer.axi4Node.out(0)._1
  // Get the AXI4 bundle for connection to Intel IP
  val (axi4Bundle, _) = outer.axi4Node.out(0)
  
  // Additional logic for CXL protocol handling could be added here
  // For now, we're just exposing the AXI4 interface that will connect to Intel's CXL IP
}

// Mixin trait to add CXL support to a Chipyard system
trait HasIntelCXLAdapter { this: BaseSubsystem =>
  // Parameters
  val cxlParams = p(IntelCXLKey)
  
  // Create the adapter
  val cxlAdapter = LazyModule(new IntelCXLAdapter(cxlParams))
  
  // Connect to memory bus (MBUS)
  val mbusWrapper = this.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(MBUS)
  cxlAdapter.node := TLBuffer() := mbusWrapper.outwardNode
}

// Key to configure the CXL adapter
case object IntelCXLKey extends Field[IntelCXLParams]

// Add trait to config system
class WithIntelCXLAdapter(params: IntelCXLParams) extends Config((site, here, up) => {
  case IntelCXLKey => params
}) 