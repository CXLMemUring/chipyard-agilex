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
import freechips.rocketchip.resources.SimpleDevice

/** Parameters for Intel Agilex CXL IP Integration */
case class AgilexCXLParams(
                            base: BigInt = 0x8000_0000L,
                            size: BigInt = 0x4000_0000L, // 1 GB
                            beatBytes: Int = 8,
                            idBits: Int = 4,
                            cxlVersion: Int = 2 // CXL 2.0
                          )

/** Key to configure the CXL adapter */
case object AgilexCXLKey extends Field[AgilexCXLParams](AgilexCXLParams())

/**
 * TL Manager + TL→AXI4 Adapter for CXL memory region
 */
class AgilexCXLAdapter(params: AgilexCXLParams)(implicit p: Parameters) extends LazyModule {
  // TileLink manager for CPU/Cache to access CXL region
  val node = TLManagerNode(Seq(TLSlavePortParameters.v1(
    managers = Seq(TLSlaveParameters.v1(
      address = Seq(AddressSet(params.base, params.size - 1)),
      resources = (new SimpleDevice("intel-cxl", Seq("intel,agilex-cxl"))).reg("mem"),
      regionType = RegionType.UNCACHED,
      executable = true,
      supportsGet = TransferSizes(1, params.beatBytes * 8),
      supportsPutFull = TransferSizes(1, params.beatBytes * 8),
      supportsPutPartial = TransferSizes(1, params.beatBytes * 8),
      fifoId = Some(0)
    )),
    beatBytes = params.beatBytes
  )))

  // AXI4 Master Node to CXL IP
  val axi4Node = AXI4MasterNode(Seq(AXI4MasterPortParameters(
    masters = Seq(AXI4MasterParameters(
      name = "agilex-cxl-adapter",
      id = IdRange(0, 1 << params.idBits)
    ))
  )))

  // Diplomatic connection: TL → TLBuffer → TLFragmenter → TLToAXI4 → Deinterleaver → UserYanker → AXI4
  axi4Node :=
    AXI4UserYanker() :=
    AXI4Deinterleaver(params.beatBytes * 8) :=
    TLToAXI4(combinational = false, adapterName = Some("AgilexCXL")) :=
    TLFragmenter(params.beatBytes, params.beatBytes * 8) :=
    TLBuffer() :=
    node

  lazy val module = new LazyModuleImp(this) {
    val (axi4Bundle, _) = axi4Node.out.head
    // Expose debug signals if needed
    dontTouch(axi4Bundle)
  }
}

/**
 * BlackBox wrapper for Intel Agilex CXL IP
 */
class AgilexCXLBlackBox(params: AgilexCXLParams) extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    // AXI4 interface
    val axi4 = Flipped(new AXI4Bundle(AXI4BundleParameters(
      addrBits = 64,
      dataBits = params.beatBytes * 8,
      idBits = params.idBits
    )))
    // CXL status
    val cxl_link_up = Output(Bool())
    // Clocks and resets
    val clock = Input(Clock())
    val reset = Input(Reset())
  })

  override def desiredName = "intel_agilex_cxl_ip"

  addResource("AgilexCXLBlackBox.v") // If needed
}

/**
 * Module to instantiate BlackBox and connect AXI4
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
  // Connect clocks and resets
  cxl.io.clock := clock
  cxl.io.reset := reset
  // Connect AXI4 signals
  cxl.io.axi4 <> io.axi4
  // Expose status
  io.cxl_link_up := cxl.io.cxl_link_up
}

/**
 * Diplomatic LazyModule wrapper around the BlackBox
 */

/**
 * Diplomatic LazyModule wrapper around the BlackBox
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

    // Instantiate the Chisel BlackBox under a fresh name
    val wrapperMod = Module(new AgilexCXLWrapperModule(params))
    wrapperMod.io.axi4 <> axi4Bundle

    // Expose CXL status
    val cxl_link_up = IO(Output(Bool()))
    cxl_link_up := wrapperMod.io.cxl_link_up
  }
}

/** Mixin trait to add CXL adapter to a subsystem */
trait CanHaveAgilexCXL {
  this: BaseSubsystem with HasTileLinkLocations =>
  // Remove redundant implicit p; use p from BaseSubsystem
  lazy val cxlParams = p(AgilexCXLKey)
  lazy val cxlAdapter = LazyModule(new AgilexCXLAdapter(cxlParams))

  // Connect to memory bus
  //  val mbus = locateTLBusWrapper(MBUS)
  //  cxlAdapter.node :=* mbus.inwardNode
//  val mbus = locateTLBusWrapper(MBUS)
  // bind manager (cxlAdapter.node) into the bus’s inward port
//  mbus.inwardNode := cxlAdapter.node
//  cxlAdapter.node := mbus.inwardNode
  val mbus = locateTLBusWrapper(MBUS)
  mbus.coupleTo("cxl") { c =>
    // ‘c’ here is the bus’s TLInwardNode being handed in,
    // and we connect your manager node into it:
    cxlAdapter.node := c
  }
}

/** Mixin trait to add CXL BlackBox wrapper linked to adapter */
trait CanHaveAgilexCXLWrapper extends CanHaveAgilexCXL {
  this: BaseSubsystem with HasTileLinkLocations =>
  // Use p from BaseSubsystem
  val cxlWrapper = LazyModule(new AgilexCXLWrapper(cxlParams))

  // Connect adapter AXI4 master to CXL IP wrapper AXI4 slave
  cxlWrapper.node := cxlAdapter.axi4Node
}
