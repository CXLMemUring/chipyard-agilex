// See LICENSE.SiFive for license details.

package chipyard

import boom.v4.common.BoomTile
import chipyard.config.WithSystemBusWidth
import org.chipsalliance.cde.config.{Config, Parameters}
import freechips.rocketchip.subsystem._
import chipyard.cxl._
import chipyard.harness.{BuildTop, WithSimAXIMem, WithUARTAdapter}
import chipyard.iobinders.{IOCellKey, OverrideIOBinder, UARTPort, WithUARTIOCells}
import chipyard.iocell.{DigitalInIOCell, DigitalInIOCellBundle, GenericAnalogIOCell, GenericDigitalGPIOCell, GenericDigitalOutIOCell, IOCellTypeParams}
import chisel3.Module.clock
import chisel3._
import freechips.rocketchip.diplomacy._

// -----------------------------------------------------------------------------
// 1) Simple CXL configuration binding
// -----------------------------------------------------------------------------
class WithCXLBasic extends Config((site, here, up) => {
  case AgilexCXLKey => AgilexCXLParams()
})

class BOOMWithCXLSystem(implicit p: Parameters) extends ChipyardSystem
 {
  // 使用 Option 处理 CXL 参数
  val cxlParams = p(AgilexCXLKey)
  val cxlAdapter = LazyModule(new AgilexCXLAdapter(cxlParams))
  val wrapperMod = LazyModule(new AgilexCXLWrapper(cxlParams))

// 获取内存总线并连接
  private val sbus = locateTLBusWrapper(SBUS)
  sbus.coupleTo("cxl") { bus =>
    cxlAdapter.node := bus
  }
  // 直接连接 adapter 到 wrapper
  wrapperMod.node := cxlAdapter.axi4Node
 }
// -----------------------------------------------------------------------------
// 3) Custom top without ChipTop
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
// 4) Build-time configuration
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