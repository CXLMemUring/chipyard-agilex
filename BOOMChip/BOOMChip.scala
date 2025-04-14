package chipyard

import freechips.rocketchip.config.{Config}
import freechips.rocketchip.devices.tilelink.{BootROMLocated}
import freechips.rocketchip.subsystem._
 

/* Fragments de configuració */

// Defineix el bus de memòria de 32b (per defecte són 64b)
class With4BMemPort extends Config((site, here, up) => {
  case MemoryBusKey => up(MemoryBusKey, site).copy(beatBytes = 4)
})

/* ------------------------- */

// Configuració del sistema
class BOOMConfig extends Config(
  // El Harness és la interfície de simulació. No s'utilitza, però s'ha de definir obligatoriament.
  new chipyard.harness.WithUARTAdapter ++                       
  new chipyard.harness.WithBlackBoxSimMem ++                    
  new chipyard.harness.WithSimSerial ++                         
  new chipyard.harness.WithSimDebug ++                         
  new chipyard.harness.WithGPIOTiedOff ++                       
  new chipyard.harness.WithSimSPIFlashModel ++                  
  new chipyard.harness.WithSimAXIMMIO ++                        
  new chipyard.harness.WithTieOffInterrupts ++                  
  new chipyard.harness.WithTieOffL2FBusAXI ++                   
  new chipyard.harness.WithTieOffCustomBootPin ++

  // Els IOBinders connecten el sistema amb la simulació. No s'utilitzen, però s'ha de definir obligatoriament.
  new chipyard.iobinders.WithAXI4MemPunchthrough ++
  new chipyard.iobinders.WithAXI4MMIOPunchthrough ++
  new chipyard.iobinders.WithL2FBusAXI4Punchthrough ++
  new chipyard.iobinders.WithBlockDeviceIOPunchthrough ++
  new chipyard.iobinders.WithNICIOPunchthrough ++
  new chipyard.iobinders.WithSerialTLIOCells ++
  new chipyard.iobinders.WithUARTIOCells ++
  new chipyard.iobinders.WithGPIOCells ++
  new chipyard.iobinders.WithUARTIOCells ++
  new chipyard.iobinders.WithSPIIOCells ++
  new chipyard.iobinders.WithTraceIOPunchthrough ++
  new chipyard.iobinders.WithExtInterruptIOCells ++

  // Configuració de timings per a simulació. No s'utilitzen, però s'ha de definir obligatoriament.
  new chipyard.config.WithPeripheryBusFrequencyAsDefault ++      
  new chipyard.config.WithMemoryBusFrequency(100.0) ++           
  new chipyard.config.WithPeripheryBusFrequency(100.0) ++

 
  new With4BMemPort ++                                           // Veure With4BMemPort
  //new chipyard.config.WithUART ++                                // add a UART
  new chipyard.config.WithBootROM ++                             // Amb BootROM
  new chipyard.WithMulticlockCoherentBusTopology ++              // Jerarquía de busos estàndar
  new chipyard.config.WithL2TLBs(0) ++                           // Elimina TLB L2 (massa costós)
  new chipyard.config.WithNoSubsystemDrivenClocks ++             // Tots els rellotges es deriven del clock del top        
  new chipyard.config.WithNoDebug ++                             // Sense mòduls de Debug
  new freechips.rocketchip.subsystem.WithNExtTopInterrupts(0) ++ // Sense interrupcions
  new freechips.rocketchip.subsystem.WithNoSlavePort ++          // Sense port per a DMA
  new freechips.rocketchip.system.BaseConfig)                    // Config. base de RocketChip

// Dispositiu a generar amb BOOM core en lloc de RocketCore
class BOOMChip extends Config(
  new boom.v3.common.WithNLargeBooms(1) ++                      // 1 BOOM core (out-of-order)
  new chipyard.config.WithSystemBusWidth(128) ++                // Configuració amb bus adequat per a BOOM
  new BOOMConfig)                                                // Resta de configuració del sistema

// Variacions amb diferents mides del BOOM core
class SmallBOOMChip extends Config(
  new boom.v3.common.WithNSmallBooms(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new BOOMConfig)

class MediumBOOMChip extends Config(
  new boom.v3.common.WithNMediumBooms(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new BOOMConfig)

// Aquesta és la configuració per defecte, amb un Large BOOM
class UABChip extends Config(new BOOMChip)