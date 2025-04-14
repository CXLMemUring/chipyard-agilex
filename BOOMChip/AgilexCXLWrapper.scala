package chipyard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config.{Parameters}
import freechips.rocketchip.amba.axi4._

// BlackBox wrapper for Intel Agilex CXL IP
class AgilexCXLBlackBox(params: AgilexCXLParams) extends BlackBox {
  // Define IO for the BlackBox
  val io = IO(new Bundle {
    // AXI4 interface from BOOM/Rocket
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits   = params.idBits
    )))
    
    // CXL specific signals
    val cxl_link_up = Output(Bool())
    
    // Clock and reset
    val clock = Input(Clock())
    val reset = Input(Reset())
  })
  
  // Override the default name
  override def desiredName = "intel_agilex_cxl_ip"
}

// Module that instantiates the CXL BlackBox and handles the connections
class AgilexCXLWrapperModule(params: AgilexCXLParams)(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    // AXI4 interface to connect to the TileLink-AXI4 adapter
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits   = params.idBits
    )))
    
    // Status output
    val cxl_link_up = Output(Bool())
  })
  
  // Instantiate the BlackBox
  val cxl_blackbox = Module(new AgilexCXLBlackBox(params))
  
  // Connect clock and reset
  cxl_blackbox.io.clock := clock
  cxl_blackbox.io.reset := reset
  
  // Connect AXI4 signals
  cxl_blackbox.io.axi4 <> io.axi4
  
  // Connect status signals
  io.cxl_link_up := cxl_blackbox.io.cxl_link_up
}

// LazyModule wrapper for the CXL BlackBox
class AgilexCXLWrapper(params: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  // AXI4 node to connect to the adapter
  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    slaves = Seq(AXI4SlaveParameters(
      address       = Seq(AddressSet(params.base, params.size-1)),
      resources     = (new SimpleDevice("agilex-cxl", Seq("intel,agilex-cxl"))).reg("mem"),
      executable    = true,
      supportsWrite = TransferSizes(1, params.beatBytes * 8),
      supportsRead  = TransferSizes(1, params.beatBytes * 8)
    )),
    beatBytes = params.beatBytes
  )))
  
  lazy val module = new LazyModuleImp(this) {
    // Get the AXI4 bundle
    val (axi4Bundle, _) = node.in(0)
    
    // Instantiate the wrapper module
    val cxl_wrapper = Module(new AgilexCXLWrapperModule(params))
    
    // Connect AXI4 interface
    cxl_wrapper.io.axi4 <> axi4Bundle
    
    // Export status signals (could be used for monitoring)
    val cxl_link_up = IO(Output(Bool()))
    cxl_link_up := cxl_wrapper.io.cxl_link_up
  }
}

// Trait to add a CXL BlackBox wrapper to a system with CXL support
trait CanHaveAgilexCXLWrapper extends CanHaveAgilexCXL { this: BaseSubsystem =>
  // Create the wrapper
  val cxlWrapper = LazyModule(new AgilexCXLWrapper(cxlParams))
  
  // Connect the adapter to the wrapper
  cxlWrapper.node := cxlAdapter.axi4Node
}

// Configuration to include CXL wrapper
class WithAgilexCXLWrapper extends Config((site, here, up) => {
  case BuildSystem => (p: Parameters) => new ChipyardSystem()(p) with CanHaveAgilexCXL with CanHaveAgilexCXLWrapper
}) 