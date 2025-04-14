package chipyard

import org.chipsalliance.cde.config.{Config}
import freechips.rocketchip.devices.tilelink.{BootROMLocated}
import freechips.rocketchip.subsystem.{MemoryBusKey}
import chipyard.harness.{HarnessClockInstantiatorKey}


// 注释掉32位内存总线配置，这可能导致与InclusiveCache的不兼容
// class With4BMemPort
//     extends Config((site, here, up) => {
//       case MemoryBusKey => {
//         val memBusParams = up(MemoryBusKey, site)
//         memBusParams.copy(beatBytes = 4)
//       }
//     })

/* ------------------------- */

// Configuració del sistema
class BOOMConfig
    extends Config(
      // 移除32位内存总线配置
      // new With4BMemPort ++
      // 基础配置
      new chipyard.config.AbstractConfig
    )

// Dispositiu a generar amb BOOM core en lloc de RocketCore
class BOOMChip
    extends Config(
      // BOOM核心配置
      new boom.v3.common.WithNLargeBooms(1) ++
        new chipyard.config.WithSystemBusWidth(128) ++
        new BOOMConfig
    )

// Variacions amb diferents mides del BOOM core
class SmallBOOMChip
    extends Config(
      new boom.v3.common.WithNSmallBooms(1) ++
        new chipyard.config.WithSystemBusWidth(128) ++
        new BOOMConfig
    )

class MediumBOOMChip
    extends Config(
      new boom.v3.common.WithNMediumBooms(1) ++
        new chipyard.config.WithSystemBusWidth(128) ++
        new BOOMConfig
    )
