package chipyard

import boom.v4.common.BoomTile
import chipyard.config.WithSystemBusWidth
import org.chipsalliance.cde.config.{Config, Parameters}
import freechips.rocketchip.subsystem._
import chipyard.cxl._
import chipyard.harness.{BuildTop, WithSimAXIMem}
import chisel3.Module.{clock, reset}
import chisel3._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci.SynchronousCrossing
import freechips.rocketchip.tilelink.TLWidthWidget
import freechips.rocketchip.util.ResetCatchAndSync

// 添加简单的 CXL 配置
class WithCXLBasic extends Config((site, here, up) => {
  case AgilexCXLKey => AgilexCXLParams(
    base = 0xc0000000L,
    size = 0x40000000L,
    beatBytes = 8,
    idBits = 4
  )
})

// -----------------------------------------------------------------------------
// 2) System that instantiates the CXL adapter
// -----------------------------------------------------------------------------
class BOOMWithCXLSystem(implicit p: Parameters) extends ChipyardSystem {
  // 首先确保BOOM处理器的时钟和复位域已正确设置
  //  val boom = LazyModule(new BoomTile())
  // 然后添加CXL适配器，并确保它使用与BOOM相同的时钟域

  val adapter = LazyModule(new AgilexCXLAdapter(p(AgilexCXLKey)))
  // 显式地连接CXL适配器与系统总线的时钟域
  val sbus = locateTLBusWrapper(SBUS)
  sbus.coupleTo("cxl") {
    adapter.node := TLWidthWidget(sbus.beatBytes) := _
  }
}

// -----------------------------------------------------------------------------
// 3) ChipTop and configuration
// -----------------------------------------------------------------------------
class BOOMWithCXLChipTop(implicit p: Parameters) extends ChipTop {
  override lazy val lazySystem = LazyModule(new BOOMWithCXLSystem)
}


class BOOMChip extends Config(

    new WithSimAXIMem ++
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
      new Config((site, here, up) => {
        case BuildTop => (p: Parameters) => new BOOMWithCXLChipTop()(p)
      }) ++
    new chipyard.config.AbstractConfig
)