package chipyard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config.{Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.util._

// Bundle to interface with Intel Agilex CXL IP
class IntelCXLIO(params: IntelCXLParams) extends Bundle {
  // AXI4 interface that will connect to the CXL IP
  val axi4 = new AXI4Bundle(AXI4BundleParameters(
    addrBits = 64,
    dataBits = params.beatBytes * 8,
    idBits   = params.idBits
  ))
  
  // CXL-specific signals if needed
  val cxl_link_up = Output(Bool())
  
  // Add any additional CXL-specific signals required by the Intel IP
  // These would be defined based on the Intel Agilex CXL IP documentation
}

// Top-level module for the BOOM + CXL system
class BoomCXLTop(implicit p: Parameters) extends Module {
  // Get the Chipyard system
  val system = Module(LazyModule(new ChipyardSystem with HasIntelCXLAdapter).module)
  
  // Intel CXL IO
  val io = IO(new Bundle {
    val cxl = new IntelCXLIO(p(IntelCXLKey))
  })
  
  // Get the AXI4 bundle from the CXL adapter
  val cxlAdapter = system.asInstanceOf[ChipyardSystemModuleImp].outer.asInstanceOf[HasIntelCXLAdapter].cxlAdapter
  val cxlBundle = cxlAdapter.module.axi4Bundle
  
  // Connect AXI4 signals to the Intel CXL IP
  io.cxl.axi4 <> cxlBundle
  
  // Default values for other signals
  io.cxl.cxl_link_up := true.B // Just a placeholder
}

// Helper object to instantiate the top-level module
object BoomCXLTop {
  def apply()(implicit p: Parameters): BoomCXLTop = new BoomCXLTop()
}

// Class for BlackBox wrapper when connecting to Intel Agilex FPGA
class IntelAgilexCXLWrapper(params: IntelCXLParams) extends BlackBox {
  // Define IO for the BlackBox
  val io = IO(new Bundle {
    // AXI4 interface from BOOM
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits   = params.idBits
    )))
    
    // Additional signals needed for CXL interface
    // (Would be based on Intel's CXL IP documentation)
    val cxl_link_up = Input(Bool())
    
    // Clock and reset
    val clock = Input(Clock())
    val reset = Input(Reset())
  })
  
  // Optional override for desiredName if needed
  override def desiredName = "intel_agilex_cxl_wrapper"
}

// Module that instantiates and connects the BlackBox
class IntelCXLBlackBoxBridge(params: IntelCXLParams)(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val cxl = new IntelCXLIO(params)
  })
  
  // Instantiate the BlackBox
  val cxl_wrapper = Module(new IntelAgilexCXLWrapper(params))
  
  // Connect clock and reset
  cxl_wrapper.io.clock := clock
  cxl_wrapper.io.reset := reset
  
  // Connect AXI4 interface
  cxl_wrapper.io.axi4 <> io.cxl.axi4
  
  // Connect other signals
  cxl_wrapper.io.cxl_link_up := io.cxl.cxl_link_up
}

// Configuration trait that instantiates the BlackBox bridge
trait WithIntelCXLBlackBoxBridge extends HasIntelCXLAdapter { this: BaseSubsystem =>
  // Get the module implementation
  val cxlBridge = LazyModule(new LazyModule {
    override lazy val module = new LazyModuleImp(this) {
      val bridgeImpl = Module(new IntelCXLBlackBoxBridge(p(IntelCXLKey)))
      
      // Connect to CXL adapter
      bridgeImpl.io.cxl.axi4 <> outer.cxlAdapter.module.axi4Bundle
      
      // Default values for other signals
      bridgeImpl.io.cxl.cxl_link_up := true.B
    }
  })
} 