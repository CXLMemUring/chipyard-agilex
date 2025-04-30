// See LICENSE.SiFive for license details.

package chipyard.cxl

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._

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
case object AgilexCXLKey extends Field[AgilexCXLParams](AgilexCXLParams())

/**
 * Scala BlackBox wrapper matching the Verilog stub for Intel Agilex CXL IP
 */
class AgilexCXLBlackBox(params: AgilexCXLParams)(implicit p: Parameters)
    extends BlackBox with HasBlackBoxResource {

  // Add the Verilog file resource
  addResource("AgilexCXLBlackBox.v")

  // Explicitly name the BlackBox to match the Verilog module
  override def desiredName: String = "intel_agilex_cxl_ip"

  val io = IO(new Bundle {
    // Clock & Reset
    val clock       = Input(Clock())
    val reset       = Input(Reset())

    // AXI4 Slave Write Address Channel
    val axi4_awid    = Input(UInt(params.idBits.W))
    val axi4_awaddr  = Input(UInt(64.W))
    val axi4_awlen   = Input(UInt(8.W))
    val axi4_awsize  = Input(UInt(3.W))
    val axi4_awburst = Input(UInt(2.W))
    val axi4_awprot  = Input(UInt(3.W))
    val axi4_awcache = Input(UInt(4.W))
    val axi4_awuser  = Input(UInt(4.W))
    val axi4_awqos   = Input(UInt(4.W))
    val axi4_awvalid = Input(Bool())
    val axi4_awready = Output(Bool())

    // AXI4 Slave Write Data Channel
    val axi4_wdata  = Input(UInt((params.beatBytes*8).W))
    val axi4_wstrb  = Input(UInt(params.beatBytes.W))
    val axi4_wlast  = Input(Bool())
    val axi4_wuser  = Input(UInt(4.W))
    val axi4_wvalid = Input(Bool())
    val axi4_wready = Output(Bool())

    // AXI4 Slave Write Response Channel
    val axi4_bid    = Output(UInt(params.idBits.W))
    val axi4_bresp  = Output(UInt(2.W))
    val axi4_buser  = Output(UInt(4.W))
    val axi4_bvalid = Output(Bool())
    val axi4_bready = Input(Bool())

    // AXI4 Slave Read Address Channel
    val axi4_arid    = Input(UInt(params.idBits.W))
    val axi4_araddr  = Input(UInt(64.W))
    val axi4_arlen   = Input(UInt(8.W))
    val axi4_arsize  = Input(UInt(3.W))
    val axi4_arburst = Input(UInt(2.W))
    val axi4_arprot  = Input(UInt(3.W))
    val axi4_arcache = Input(UInt(4.W))
    val axi4_aruser  = Input(UInt(4.W))
    val axi4_arvalid = Input(Bool())
    val axi4_arready = Output(Bool())

    // AXI4 Slave Read Data Channel
    val axi4_rid    = Output(UInt(params.idBits.W))
    val axi4_rdata  = Output(UInt((params.beatBytes*8).W))
    val axi4_rresp  = Output(UInt(2.W))
    val axi4_rlast  = Output(Bool())
    val axi4_rvalid = Output(Bool())
    val axi4_rready = Input(Bool())

    // CXL-specific status
    val cxl_link_up = Output(Bool())
  })
}

/**
 * Adapter from CXL HIP TLP Stream to TileLink-C interface
 * Supports basic CXL.mem Get/Put and CXL.cache Acquire/Release.
 * For full x86 coherence and ordering, a directory and fence engine must be added.
 */
class AgilexCXLAdapter(val hipParams: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  // 声明一个 TL-C 管理者节点
  val node = TLManagerNode(Seq(
    TLSlavePortParameters.v1(
      managers = Seq(TLSlaveParameters.v1(
        address     = Seq(AddressSet(hipParams.base, hipParams.size-1)),
        regionType       = RegionType.CACHED,
        executable       = true,
        supportsAcquireT = TransferSizes(1, hipParams.beatBytes),  // Probe T
        supportsAcquireB = TransferSizes(1, hipParams.beatBytes),  // Probe B (必填)
        supportsGet      = TransferSizes(1, hipParams.beatBytes),
        supportsPutFull  = TransferSizes(1, hipParams.beatBytes)
      )),
      beatBytes = hipParams.beatBytes,
      endSinkId  = 1
    )
  ))

  lazy val module = new LazyModuleImp(this) {
    // 1) 显式传递 implicit 参数 p
    val hip = Module(new AgilexCXLBlackBox(hipParams)(p))

    // 2) BlackBox 时钟/复位
    hip.io.clock := clock
    hip.io.reset := reset

    // 3) 使用 node.in 而不是 bundleIn
    //    node.in: Seq[(TLBundle, TLManagerEdge)]，head._1 就是 TV->A/D bundle
    val (tl, edge) = node.in.head

    // 4) 举例：把所有 AXI4 AW 请求映射到 TL A 通道的 Get/Put
    //    注意：这里只是示意，真正要做 rx_stream 解包的话，需用 hip.io.axi4.aw/ar/w/r/b 一组信号
    tl.a.valid := hip.io.axi4_awvalid
    hip.io.axi4_awready := tl.a.ready
    tl.a.bits.opcode := Mux(hip.io.axi4_awvalid, TLMessages.Get, TLMessages.PutFullData)
    tl.a.bits.size   := hip.io.axi4_awsize
    tl.a.bits.source := hip.io.axi4_awid
    tl.a.bits.address:= hip.io.axi4_awaddr
    tl.a.bits.data   := hip.io.axi4_wdata
    tl.a.bits.mask   := hip.io.axi4_wstrb

    // 5) 把 TL D 通道的响应打包回 AXI4 R/B
    hip.io.axi4_rvalid := tl.d.valid
    tl.d.ready         := hip.io.axi4_rready
    hip.io.axi4_rdata  := tl.d.bits.data
    hip.io.axi4_rresp  := 0.U
    hip.io.axi4_rid    := tl.d.bits.source
    hip.io.axi4_rlast  := true.B

    // 同理，为写响应映射 B 通道
    hip.io.axi4_bvalid := tl.d.valid && tl.d.bits.opcode === TLMessages.AccessAckData
    hip.io.axi4_bid    := tl.d.bits.source
    hip.io.axi4_bresp  := 0.U
    tl.d.ready         := hip.io.axi4_bready

    // 6) 链路状态直通
    //    （如果你的 Verilog IP 始终拉高 cxl_link_up，就可以直接连）
    val _ = hip.io.cxl_link_up
  }
}