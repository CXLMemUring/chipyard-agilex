package chipyard

import chipyard.config.WithSystemBusWidth
import org.chipsalliance.cde.config.{Config, Parameters}
import freechips.rocketchip.subsystem._
import chipyard.cxl._
import chipyard.harness.BuildTop
import chisel3.Module.{clock, reset}
import chisel3._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util.ResetCatchAndSync

// 添加简单的 CXL 配置

// 添加简单的 CXL 配置
class WithCXLBasic extends Config((site, here, up) => {
  case AgilexCXLKey => Some(AgilexCXLParams(
    base = 0xc0000000L,
    size = 0x40000000L,
    beatBytes = 8,
    idBits = 4
  ))
})

// 创建一个包含 CXL 的自定义系统
class BOOMWithCXLSystem(implicit p: Parameters) extends ChipyardSystem {
  // 添加 CXL 适配器
  val cxlOpt = p(AgilexCXLKey).map { cxlParams =>
    val adapter = LazyModule(new AgilexCXLAdapter(cxlParams))
    val mbus = locateTLBusWrapper(MBUS)

    mbus.coupleTo("cxl") { adapter.node := _ }
    InModuleBody {
      adapter.module.reset := ResetCatchAndSync(clock, reset.asBool)
    }
    adapter
  }
}

// 创建自定义的 ChipTop
class BOOMWithCXLChipTop(implicit p: Parameters) extends ChipTop {
  override lazy val lazySystem = LazyModule(new BOOMWithCXLSystem)
}

// 最终的配置
class BOOMChip extends Config(
  new Config((site, here, up) => {
    case BuildTop => (p: Parameters) => new BOOMWithCXLChipTop()(p).suggestName("ChipTop")
  }) ++
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
    new chipyard.config.AbstractConfig
)