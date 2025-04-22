// See LICENSE.SiFive for license details.

package chipyard.cxl

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.subsystem.{BaseSubsystem, HasTileLinkLocations, MBUS}
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.prci.{ClockSinkNode, ClockSinkParameters}
import freechips.rocketchip.resources.SimpleDevice

/** Parameters for Intel Agilex CXL IP Integration */

/** Parameters for Intel Agilex CXL IP Integration */
case class AgilexCXLParams(
                            base: BigInt = 0xc0000000L, // 改为对齐的地址
                            size: BigInt = 0x40000000L, // 1 GB (必须是2的幂次方)
                            beatBytes: Int = 8,
                            idBits: Int = 4,
                            cxlVersion: Int = 2 // CXL 2.0
                          )

/** Key to configure the CXL adapter */
//case object AgilexCXLKey extends Field[AgilexCXLParams](AgilexCXLParams())
case object AgilexCXLKey extends Field[Option[AgilexCXLParams]](None)

/**
 * TL Manager + TL→AXI4 Adapter for CXL memory region
 */
// 修改后的 CXL Adapter
class AgilexCXLAdapter(params: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  // 只保留 TileLink manager 节点
  val node = TLManagerNode(Seq(TLSlavePortParameters.v1(
    managers = Seq(TLSlaveParameters.v1(
      address    = Seq(AddressSet(params.base, params.size - 1)),
      resources  = (new SimpleDevice("intel-cxl", Seq("intel,agilex-cxl"))).reg("mem"),
      regionType = RegionType.UNCACHED,
      executable = true,
      supportsGet        = TransferSizes(1, params.beatBytes * 8),
      supportsPutFull    = TransferSizes(1, params.beatBytes * 8),
      supportsPutPartial = TransferSizes(1, params.beatBytes * 8),
      fifoId             = Some(0)
    )),
    beatBytes = params.beatBytes
  )))

  // 添加重置域
  val resetDomain = LazyScope(this) {
    implicit val valName = ValName("cxl_reset")
    val resetCrossingSource = ClockSinkNode(Seq(ClockSinkParameters()))
  }

  lazy val module = new LazyModuleImp(this) {
    // 确保有重置信号
    val reset_domain = IO(Input(Reset()))
    reset := reset_domain
  }
}


/**
 * BlackBox wrapper for Intel Agilex CXL IP
 */
class AgilexCXLBlackBox(params: AgilexCXLParams) extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits = params.idBits
    )))
    val cxl_link_up = Output(Bool())
    val clock = Input(Clock())
    val reset = Input(Reset())
  })

  override def desiredName = "intel_agilex_cxl_ip"

  addResource("AgilexCXLBlackBox.v")
}

/**
 * Module that instantiates the BlackBox and connects AXI4
 */
class AgilexCXLWrapperModule(params: AgilexCXLParams) extends Module {
  val io = IO(new Bundle {
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits = params.idBits
    )))
    val cxl_link_up = Output(Bool())
  })

  val cxl = Module(new AgilexCXLBlackBox(params))
  // Clock & reset
  cxl.io.clock := clock
  cxl.io.reset := reset
  // AXI4
  cxl.io.axi4 <> io.axi4
  // Status
  io.cxl_link_up := cxl.io.cxl_link_up
}

/**
 * Diplomatic wrapper around the BlackBox
 */
class AgilexCXLWrapper(params: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    slaves = Seq(AXI4SlaveParameters(
      address = Seq(AddressSet(params.base, params.size - 1)),
      resources = (new SimpleDevice("agilex-cxl", Seq("intel,agilex-cxl"))).reg("mem"),
      regionType = RegionType.UNCACHED,
      supportsWrite = TransferSizes(1, params.beatBytes * 8),
      supportsRead = TransferSizes(1, params.beatBytes * 8)
    )),
    beatBytes = params.beatBytes
  )))

  lazy val module = new LazyModuleImp(this) {
    val (axi4Bundle, _) = node.in.head
    val wrapperMod = Module(new AgilexCXLWrapperModule(params))
    wrapperMod.io.axi4 <> axi4Bundle

    val cxl_link_up = IO(Output(Bool()))
    cxl_link_up := wrapperMod.io.cxl_link_up
  }
}
