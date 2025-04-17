// (C) 2001-2022 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// Copyright 2022 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

// QPDS UPDATE
`include "cxl_type2_defines.svh.iv"

import cxlip_top_pkg::*;
import afu_axi_if_pkg::*;

`ifdef QUARTUS_FPGA_SYNTH
`include "rnr_cxl_soft_ip_intf.svh.iv"
`include "rnr_ial_sip_intf.svh.iv";
`endif

module cxltyp2_ed (
  input                    refclk0,     // to RTile
  input                    refclk1,     // to RTile
  input                    refclk4,     // to Fabric PLL
  input                    resetn,
  // CXL 
  input             [15:0] cxl_rx_n,
  input             [15:0] cxl_rx_p,
  output            [15:0] cxl_tx_n,
  output            [15:0] cxl_tx_p,

//-----------------------NOTE---------------------------------------
// DDR Memory Interface (2 Channel)
//------------------------------------------------------------------
`ifndef ENABLE_4_BBS_SLICE   // MC Channel=2
  input  [1:0]   mem_refclk,                                    // EMIF PLL reference clock
  output [0:0]   mem_ck         [1:0],  // DDR4 interface signals
  output [0:0]   mem_ck_n       [1:0],  //
  output [16:0]  mem_a          [1:0],  //
  output [1:0]   mem_act_n,                                     //
  output [1:0]   mem_ba         [1:0],  //
  output [1:0]   mem_bg         [1:0],  //
`ifdef HDM_64G
  output [1:0]   mem_cke        [1:0],  //
  output [1:0]   mem_cs_n       [1:0],  //
  output [1:0]   mem_odt        [1:0],  //
`else
  output [0:0]   mem_cke        [1:0],  //
  output [0:0]   mem_cs_n       [1:0],  //
  output [0:0]   mem_odt        [1:0],  //
`endif
  output [1:0]   mem_reset_n,                                   //
  output [1:0]   mem_par,                                       //
  input  [1:0]   mem_oct_rzqin,                                 //
  input  [1:0]   mem_alert_n, 
`ifdef ENABLE_DDR_DBI_PINS                                  //Micron DIMM
  inout  [8:0]   mem_dqs        [1:0],  //
  inout  [8:0]   mem_dqs_n      [1:0],  //
  inout  [8:0]   mem_dbi_n      [1:0],  //
`else
  inout  [17:0]   mem_dqs        [1:0],  //
  inout  [17:0]   mem_dqs_n      [1:0],  //
`endif  
  inout  [71:0]  mem_dq         [1:0]    //
//-----------------------NOTE---------------------------------------
// DDR Memory Interface (4 Channel)
//------------------------------------------------------------------
`else  // MC CHANNEL =4

  input  [3:0]   mem_refclk,                                    // EMIF PLL reference clock
  output [0:0]   mem_ck         [3:0],  // DDR4 interface signals
  output [0:0]   mem_ck_n       [3:0],  //
  output [16:0]  mem_a          [3:0],  //
  output [3:0]   mem_act_n,                                     //
  output [1:0]   mem_ba         [3:0],  //
  output [1:0]   mem_bg         [3:0],  //
`ifdef HDM_64G
  output [1:0]   mem_cke        [3:0],  //
  output [1:0]   mem_cs_n       [3:0],  //
  output [1:0]   mem_odt        [3:0],  //
`else
  output [0:0]   mem_cke        [3:0],  //
  output [0:0]   mem_cs_n       [3:0],  //
  output [0:0]   mem_odt        [3:0],  //
`endif
  output [3:0]   mem_reset_n,                                   //
  output [3:0]   mem_par,                                       //
  input  [3:0]   mem_oct_rzqin,                                 //
  input  [3:0]   mem_alert_n, 
`ifdef ENABLE_DDR_DBI_PINS                                  //Micron DIMM
  inout  [8:0]   mem_dqs        [3:0],  //
  inout  [8:0]   mem_dqs_n      [3:0],  //
  inout  [8:0]   mem_dbi_n      [3:0],  //
`else
  inout  [17:0]   mem_dqs        [3:0],  //
  inout  [17:0]   mem_dqs_n      [3:0],  //
`endif  
  inout  [71:0]  mem_dq         [3:0]    //

`endif


);

  //-------------------------------------------------------
  // Signals & Settings                                  --
  //-------------------------------------------------------
//>>>

   //CXLIP <---> iAFU
  
  logic                                                 ip2hdm_reset_n;
   // DDRMC <--> BBS Slice
     logic [35:0]                                       hdm_size_256mb ; // Brought out to top from 22ww18a
      logic [63:0]                                      mc2ip_memsize;

//Channel-0
    
      logic [63:0]                                      mc2ip_0_memsize;
	
      logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc2ip_0_sr_status                ;    
      logic                                             mc2ip_0_rspfifo_full;
      logic                                             mc2ip_0_rspfifo_empty;
      logic [cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc2ip_0_rspfifo_fill_level  ;
      logic                                             mc2ip_0_reqfifo_full;
      logic                                             mc2ip_0_reqfifo_empty;
      logic [cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc2ip_0_reqfifo_fill_level  ;
    
      logic                                             hdm2ip_avmm0_cxlmem_ready;	
      logic                                             hdm2ip_avmm0_ready;
      logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    hdm2ip_avmm0_readdata            ;
      logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         hdm2ip_avmm0_rsp_mdata           ;
      logic                                             hdm2ip_avmm0_read_poison;
      logic                                             hdm2ip_avmm0_readdatavalid;
 // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when hdm2ip_avmm0_readdatavalid is active
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm0_ecc_err_corrected   ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm0_ecc_err_detected    ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm0_ecc_err_fatal       ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm0_ecc_err_syn_e       ;
      logic                                             hdm2ip_avmm0_ecc_err_valid;	
	
     logic                                             ip2hdm_avmm0_read;
     logic                                             ip2hdm_avmm0_write;
     logic                                             ip2hdm_avmm0_write_poison;
     logic                                             ip2hdm_avmm0_write_ras_sbe;    
     logic                                             ip2hdm_avmm0_write_ras_dbe;    
     logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    ip2hdm_avmm0_writedata           ;
     logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      ip2hdm_avmm0_byteenable          ;
       logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    ip2hdm_avmm0_address            ;  //added from 22ww18a
     logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         ip2hdm_avmm0_req_mdata           ;

//Channel 1
     logic [63:0]                                      mc2ip_1_memsize;
	
      logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc2ip_1_sr_status                ;    
      logic                                             mc2ip_1_rspfifo_full;
      logic                                             mc2ip_1_rspfifo_empty;
      logic [cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc2ip_1_rspfifo_fill_level  ;
      logic                                             mc2ip_1_reqfifo_full;
      logic                                             mc2ip_1_reqfifo_empty;
      logic [cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc2ip_1_reqfifo_fill_level  ;
    
      logic                                             hdm2ip_avmm1_cxlmem_ready;	
      logic                                             hdm2ip_avmm1_ready;
      logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    hdm2ip_avmm1_readdata            ;
      logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         hdm2ip_avmm1_rsp_mdata           ;
      logic                                             hdm2ip_avmm1_read_poison;
      logic                                             hdm2ip_avmm1_readdatavalid;
 // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when hdm2ip_avmm1_readdatavalid is active
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm1_ecc_err_corrected   ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm1_ecc_err_detected    ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm1_ecc_err_fatal       ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm1_ecc_err_syn_e       ;
      logic                                             hdm2ip_avmm1_ecc_err_valid;	
	
     logic                                             ip2hdm_avmm1_read;
     logic                                             ip2hdm_avmm1_write;
     logic                                             ip2hdm_avmm1_write_poison;
     logic                                             ip2hdm_avmm1_write_ras_sbe;    
     logic                                             ip2hdm_avmm1_write_ras_dbe;    
     logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    ip2hdm_avmm1_writedata           ;
     logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      ip2hdm_avmm1_byteenable          ;
       logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    ip2hdm_avmm1_address            ;  //added from 22ww18a
     logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         ip2hdm_avmm1_req_mdata           ;
	
//Channel 2
    
      logic [63:0]                                      mc2ip_2_memsize;
	
      logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc2ip_2_sr_status                ;    
      logic                                             mc2ip_2_rspfifo_full;
      logic                                             mc2ip_2_rspfifo_empty;
      logic [cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc2ip_2_rspfifo_fill_level  ;
      logic                                             mc2ip_2_reqfifo_full;
      logic                                             mc2ip_2_reqfifo_empty;
      logic [cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc2ip_2_reqfifo_fill_level  ;
    
      logic                                             hdm2ip_avmm2_cxlmem_ready;	
      logic                                             hdm2ip_avmm2_ready;
      logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    hdm2ip_avmm2_readdata            ;
      logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         hdm2ip_avmm2_rsp_mdata           ;
      logic                                             hdm2ip_avmm2_read_poison;
      logic                                             hdm2ip_avmm2_readdatavalid;
 // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when hdm2ip_avmm2_readdatavalid is active
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm2_ecc_err_corrected   ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm2_ecc_err_detected    ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm2_ecc_err_fatal       ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm2_ecc_err_syn_e       ;
      logic                                             hdm2ip_avmm2_ecc_err_valid;	
	
     logic                                             ip2hdm_avmm2_read;
     logic                                             ip2hdm_avmm2_write;
     logic                                             ip2hdm_avmm2_write_poison;
     logic                                             ip2hdm_avmm2_write_ras_sbe;    
     logic                                             ip2hdm_avmm2_write_ras_dbe;    
     logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    ip2hdm_avmm2_writedata           ;
     logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      ip2hdm_avmm2_byteenable          ;
       logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    ip2hdm_avmm2_address            ;  //added from 22ww18a
     logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         ip2hdm_avmm2_req_mdata           ;

//Channel 3
      logic [63:0]                                      mc2ip_3_memsize;
	
      logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc2ip_3_sr_status                ;    
      logic                                             mc2ip_3_rspfifo_full;
      logic                                             mc2ip_3_rspfifo_empty;
      logic [cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc2ip_3_rspfifo_fill_level  ;
      logic                                             mc2ip_3_reqfifo_full;
      logic                                             mc2ip_3_reqfifo_empty;
      logic [cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc2ip_3_reqfifo_fill_level  ;
    
      logic                                             hdm2ip_avmm3_cxlmem_ready;	
      logic                                             hdm2ip_avmm3_ready;
      logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    hdm2ip_avmm3_readdata            ;
      logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         hdm2ip_avmm3_rsp_mdata           ;
      logic                                             hdm2ip_avmm3_read_poison;
      logic                                             hdm2ip_avmm3_readdatavalid;
 // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when hdm2ip_avmm3_readdatavalid is active
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm3_ecc_err_corrected   ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm3_ecc_err_detected    ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm3_ecc_err_fatal       ;
      logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     hdm2ip_avmm3_ecc_err_syn_e       ;
      logic                                             hdm2ip_avmm3_ecc_err_valid;	
	
     logic                                             ip2hdm_avmm3_read;
     logic                                             ip2hdm_avmm3_write;
     logic                                             ip2hdm_avmm3_write_poison;
     logic                                             ip2hdm_avmm3_write_ras_sbe;    
     logic                                             ip2hdm_avmm3_write_ras_dbe;    
     logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    ip2hdm_avmm3_writedata           ;
     logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      ip2hdm_avmm3_byteenable          ;
     logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    ip2hdm_avmm3_address            ;  //added from 22ww18a
     logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         ip2hdm_avmm3_req_mdata           ;





   logic ip2hdm_clk;
   logic usr_clk;
   logic usr_rst_n;

  logic                              ip2csr_avmm_clk;
  logic                              ip2csr_avmm_rstn;  
  logic                              csr2ip_avmm_waitrequest;            
  logic [31:0]                       csr2ip_avmm_readdata;               
  logic                              csr2ip_avmm_readdatavalid;          
  logic [31:0]                       ip2csr_avmm_writedata;              
  logic [21:0]                       ip2csr_avmm_address;                
  logic                              ip2csr_avmm_write;                  
  logic                              ip2csr_avmm_read;                   
  logic [3:0]                        ip2csr_avmm_byteenable;


  //CXL compliance csr avmm interface 
  logic                               ip2cafu_avmm_clk;
  logic                               ip2cafu_avmm_rstn;  
  logic                               cafu2ip_avmm_waitrequest;
  logic [63:0]                        cafu2ip_avmm_readdata;
  logic                               cafu2ip_avmm_readdatavalid;
  logic [0:0]                         ip2cafu_avmm_burstcount;
  logic [63:0]                        ip2cafu_avmm_writedata;
  logic [21:0]                        ip2cafu_avmm_address;
  logic                               ip2cafu_avmm_write;
  logic                               ip2cafu_avmm_read;
  logic [7:0]                         ip2cafu_avmm_byteenable;


  //TO EXT COMPLIANCE
  logic [31:0]                        cxl_compliance_conf_base_addr_high ;
  logic                               cxl_compliance_conf_base_addr_high_valid;
  logic [31:0]                        cxl_compliance_conf_base_addr_low ;
  logic                               cxl_compliance_conf_base_addr_low_valid;

  logic                               cxl_warm_rst_n;
  logic                               cxl_cold_rst_n;
  logic [4:0]                         usr_rx_st_ready;


  logic [31:0]                       ccv_afu_conf_base_addr_high;
  logic                              ccv_afu_conf_base_addr_high_valid;
  logic [27:0]                       ccv_afu_conf_base_addr_low;
  logic                              ccv_afu_conf_base_addr_low_valid;




  logic                afu_cam_ext5;
  logic                afu_cam_ext6;
  logic                cam_afu_ext5;
  logic                cam_afu_ext6;

  logic                resetprep_en;
  logic                bfe_afu_quiesce_req;
  logic                afu_bfe_quiesce_ack;


  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write address channels
   logic [11:0]               cafu2ip_aximm0_awid;
   logic [63:0]               cafu2ip_aximm0_awaddr; 
   logic [9:0]                cafu2ip_aximm0_awlen;
   logic [2:0]                cafu2ip_aximm0_awsize;
   logic [1:0]                cafu2ip_aximm0_awburst;
   logic [2:0]                cafu2ip_aximm0_awprot;
   logic [3:0]                cafu2ip_aximm0_awqos;
   logic [4:0]                cafu2ip_aximm0_awuser;
   logic                      cafu2ip_aximm0_awvalid;
   logic [3:0]                cafu2ip_aximm0_awcache;
   logic [1:0]                cafu2ip_aximm0_awlock;
   logic [3:0]                cafu2ip_aximm0_awregion;
   logic                      ip2cafu_aximm0_awready;
  
   logic [11:0]               cafu2ip_aximm1_awid;
   logic [63:0]               cafu2ip_aximm1_awaddr; 
   logic [9:0]                cafu2ip_aximm1_awlen;
   logic [2:0]                cafu2ip_aximm1_awsize;
   logic [1:0]                cafu2ip_aximm1_awburst;
   logic [2:0]                cafu2ip_aximm1_awprot;
   logic [3:0]                cafu2ip_aximm1_awqos;
   logic [4:0]                cafu2ip_aximm1_awuser;
   logic                      cafu2ip_aximm1_awvalid;
   logic [3:0]                cafu2ip_aximm1_awcache;
   logic [1:0]                cafu2ip_aximm1_awlock;
   logic [3:0]                cafu2ip_aximm1_awregion;
   logic                      ip2cafu_aximm1_awready;
  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write data channels
   logic [511:0]              cafu2ip_aximm0_wdata;
   logic [(512/8)-1:0]        cafu2ip_aximm0_wstrb;
   logic                      cafu2ip_aximm0_wlast;
   logic                      cafu2ip_aximm0_wuser;
   logic                      cafu2ip_aximm0_wvalid;
   logic [15:0]               cafu2ip_aximm0_wid;
   logic                      ip2cafu_aximm0_wready;
  
   logic [511:0]              cafu2ip_aximm1_wdata;
   logic [(512/8)-1:0]        cafu2ip_aximm1_wstrb;
   logic                      cafu2ip_aximm1_wlast;
   logic                      cafu2ip_aximm1_wuser;
   logic                      cafu2ip_aximm1_wvalid;
   logic [7:0]                cafu2ip_aximm1_wid;
   logic                      ip2cafu_aximm1_wready;
  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write response channels
   logic [11:0]               ip2cafu_aximm0_bid;
   logic [1:0]                ip2cafu_aximm0_bresp;
   logic [3:0]                ip2cafu_aximm0_buser;
   logic                      ip2cafu_aximm0_bvalid;
   logic                      cafu2ip_aximm0_bready;
  
   logic [11:0]               ip2cafu_aximm1_bid;
   logic [1:0]                ip2cafu_aximm1_bresp;
   logic [3:0]                ip2cafu_aximm1_buser;
   logic                      ip2cafu_aximm1_bvalid;
   logic                      cafu2ip_aximm1_bready;
  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read address channels
   logic [11:0]                        cafu2ip_aximm0_arid;
   logic [63:0]                        cafu2ip_aximm0_araddr;
   logic [9:0]                         cafu2ip_aximm0_arlen;
   logic [2:0]                         cafu2ip_aximm0_arsize;
   logic [1:0]                         cafu2ip_aximm0_arburst;
   logic [2:0]                         cafu2ip_aximm0_arprot;
   logic [3:0]                         cafu2ip_aximm0_arqos;
   logic [4:0]                         cafu2ip_aximm0_aruser;
   logic                               cafu2ip_aximm0_arvalid;
   logic [3:0]                         cafu2ip_aximm0_arcache;
   logic [1:0]                         cafu2ip_aximm0_arlock;
   logic [3:0]                         cafu2ip_aximm0_arregion;
   logic                               ip2cafu_aximm0_arready;
  
   logic [11:0]                        cafu2ip_aximm1_arid;
   logic [63:0]                        cafu2ip_aximm1_araddr;
   logic [9:0]                         cafu2ip_aximm1_arlen;
   logic [2:0]                         cafu2ip_aximm1_arsize;
   logic [1:0]                         cafu2ip_aximm1_arburst;
   logic [2:0]                         cafu2ip_aximm1_arprot;
   logic [3:0]                         cafu2ip_aximm1_arqos;
   logic [4:0]                         cafu2ip_aximm1_aruser;
   logic                               cafu2ip_aximm1_arvalid;
   logic [3:0]                         cafu2ip_aximm1_arcache;
   logic [1:0]                         cafu2ip_aximm1_arlock;
   logic [3:0]                         cafu2ip_aximm1_arregion;
   logic                               ip2cafu_aximm1_arready;

  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read response channels
   logic [11:0]                        ip2cafu_aximm0_rid;
   logic [511:0]                       ip2cafu_aximm0_rdata;
   logic [3:0]                         ip2cafu_aximm0_rresp;
   logic                               ip2cafu_aximm0_rlast;
   logic                               ip2cafu_aximm0_ruser;
   logic                               ip2cafu_aximm0_rvalid;
   logic                               cafu2ip_aximm0_rready;
  
   logic [11:0]                        ip2cafu_aximm1_rid;
   logic [511:0]                       ip2cafu_aximm1_rdata;
   logic [3:0]                         ip2cafu_aximm1_rresp;
   logic                               ip2cafu_aximm1_rlast;
   logic                               ip2cafu_aximm1_ruser;
   logic                               ip2cafu_aximm1_rvalid;
   logic                               cafu2ip_aximm1_rready;


  // IO - User AVST interface
    logic                             ip2uio_tx_ready;      //TBD
     logic                            uio2ip_tx_st0_dvalid;
     logic                            uio2ip_tx_st0_sop;
     logic                            uio2ip_tx_st0_eop;
     logic                            uio2ip_tx_st0_passthrough;
     logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st0_data;
     logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st0_data_parity;
     logic [127:0]                    uio2ip_tx_st0_hdr;
     logic [3:0]                      uio2ip_tx_st0_hdr_parity;
     logic                            uio2ip_tx_st0_hvalid;
     logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st0_prefix;
     logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st0_prefix_parity;
     logic [11:0]                     uio2ip_tx_st0_RSSAI_prefix;
     logic                            uio2ip_tx_st0_RSSAI_prefix_parity;
     logic [1:0]                      uio2ip_tx_st0_pvalid;
     logic                            uio2ip_tx_st0_vfactive;
     logic [10:0]                     uio2ip_tx_st0_vfnum ;
     logic [2:0]                      uio2ip_tx_st0_pfnum;
     logic [(CXL_IO_CHWIDTH-1):0]     uio2ip_tx_st0_chnum;
     logic [2:0]                      uio2ip_tx_st0_empty;  // [log2(CXL_IO_DWIDTH/32)-1:0]
     logic                            uio2ip_tx_st0_misc_parity;

     logic                            uio2ip_tx_st1_dvalid;
     logic                            uio2ip_tx_st1_sop;
     logic                            uio2ip_tx_st1_eop;
     logic                            uio2ip_tx_st1_passthrough;
     logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st1_data;
     logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st1_data_parity;
     logic [127:0]                    uio2ip_tx_st1_hdr;
     logic [3:0]                      uio2ip_tx_st1_hdr_parity;
     logic                            uio2ip_tx_st1_hvalid;
     logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st1_prefix;
     logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st1_prefix_parity;
     logic [11:0]                     uio2ip_tx_st1_RSSAI_prefix;
     logic                            uio2ip_tx_st1_RSSAI_prefix_parity;
     logic [1:0]                      uio2ip_tx_st1_pvalid;
     logic                            uio2ip_tx_st1_vfactive;
     logic [10:0]                     uio2ip_tx_st1_vfnum ;
     logic [2:0]                      uio2ip_tx_st1_pfnum;
     logic [(CXL_IO_CHWIDTH-1):0]     uio2ip_tx_st1_chnum;
     logic [2:0]                      uio2ip_tx_st1_empty; 
     logic                            uio2ip_tx_st1_misc_parity;

     logic                            uio2ip_tx_st2_dvalid;
     logic                            uio2ip_tx_st2_sop;
     logic                            uio2ip_tx_st2_eop;
     logic                            uio2ip_tx_st2_passthrough;
     logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st2_data;
     logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st2_data_parity;
     logic [127:0]                    uio2ip_tx_st2_hdr;
     logic [3:0]                      uio2ip_tx_st2_hdr_parity;
     logic                            uio2ip_tx_st2_hvalid;
     logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st2_prefix;
     logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st2_prefix_parity;
     logic [11:0]                     uio2ip_tx_st2_RSSAI_prefix;
     logic                            uio2ip_tx_st2_RSSAI_prefix_parity;
     logic [1:0]                      uio2ip_tx_st2_pvalid;
     logic                            uio2ip_tx_st2_vfactive;
     logic [10:0]                     uio2ip_tx_st2_vfnum ;
     logic [2:0]                      uio2ip_tx_st2_pfnum;
     logic [(CXL_IO_CHWIDTH-1):0]     uio2ip_tx_st2_chnum;
     logic [2:0]                      uio2ip_tx_st2_empty;  
     logic                            uio2ip_tx_st2_misc_parity;

     logic                            uio2ip_tx_st3_dvalid;
     logic                            uio2ip_tx_st3_sop;
     logic                            uio2ip_tx_st3_eop;
     logic                            uio2ip_tx_st3_passthrough;
     logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st3_data;
     logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st3_data_parity;
     logic [127:0]                    uio2ip_tx_st3_hdr;
     logic [3:0]                      uio2ip_tx_st3_hdr_parity;
     logic                            uio2ip_tx_st3_hvalid;
     logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st3_prefix;
     logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st3_prefix_parity;
     logic [11:0]                     uio2ip_tx_st3_RSSAI_prefix;
     logic                            uio2ip_tx_st3_RSSAI_prefix_parity;
     logic [1:0]                      uio2ip_tx_st3_pvalid;
     logic                            uio2ip_tx_st3_vfactive;
     logic [10:0]                     uio2ip_tx_st3_vfnum ;
     logic [2:0]                      uio2ip_tx_st3_pfnum;
     logic [(CXL_IO_CHWIDTH-1):0]     uio2ip_tx_st3_chnum;
     logic [2:0]                      uio2ip_tx_st3_empty;  
     logic                            uio2ip_tx_st3_misc_parity;

//TBD 
    logic [2:0]                      ip2uio_tx_st_Hcrdt_update;
    logic [(CXL_IO_CHWIDTH-1):0]     ip2uio_tx_st_Hcrdt_ch;
    logic [5:0]                      ip2uio_tx_st_Hcrdt_update_cnt;
    logic [2:0]                      ip2uio_tx_st_Hcrdt_init;
     logic [2:0]                      uio2ip_tx_st_Hcrdt_init_ack;
    logic [2:0]                      ip2uio_tx_st_Dcrdt_update;
    logic [(CXL_IO_CHWIDTH-1):0]     ip2uio_tx_st_Dcrdt_ch;
    logic [11:0]                     ip2uio_tx_st_Dcrdt_update_cnt;
    logic [2:0]                      ip2uio_tx_st_Dcrdt_init ;
     logic [2:0]                      uio2ip_tx_st_Dcrdt_init_ack;
  
   logic                             ip2uio_rx_st0_dvalid;
   logic                             ip2uio_rx_st0_sop;
   logic                             ip2uio_rx_st0_eop;
   logic                             ip2uio_rx_st0_passthrough;
   logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st0_data;
   logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st0_data_parity;
   logic  [127:0]                    ip2uio_rx_st0_hdr;
   logic  [3:0]                      ip2uio_rx_st0_hdr_parity;
   logic                             ip2uio_rx_st0_hvalid;
   logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st0_prefix;
   logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st0_prefix_parity;
   logic  [11:0]                     ip2uio_rx_st0_RSSAI_prefix;
   logic                             ip2uio_rx_st0_RSSAI_prefix_parity;
   logic  [1:0]                      ip2uio_rx_st0_pvalid;
   logic  [2:0]                      ip2uio_rx_st0_bar;
   logic                             ip2uio_rx_st0_vfactive;
   logic  [10:0]                     ip2uio_rx_st0_vfnum;
   logic  [2:0]                      ip2uio_rx_st0_pfnum;
   logic  [(CXL_IO_CHWIDTH-1):0]     ip2uio_rx_st0_chnum;
   logic                             ip2uio_rx_st0_misc_parity;
   logic  [2:0]                      ip2uio_rx_st0_empty;  

   logic                             ip2uio_rx_st1_dvalid;
   logic                             ip2uio_rx_st1_sop;
   logic                             ip2uio_rx_st1_eop;
   logic                             ip2uio_rx_st1_passthrough;
   logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st1_data;
   logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st1_data_parity;
   logic  [127:0]                    ip2uio_rx_st1_hdr;
   logic  [3:0]                      ip2uio_rx_st1_hdr_parity;
   logic                             ip2uio_rx_st1_hvalid;
   logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st1_prefix;
   logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st1_prefix_parity;
   logic  [11:0]                     ip2uio_rx_st1_RSSAI_prefix;
   logic                             ip2uio_rx_st1_RSSAI_prefix_parity;
   logic  [1:0]                      ip2uio_rx_st1_pvalid;
   logic  [2:0]                      ip2uio_rx_st1_bar;
   logic                             ip2uio_rx_st1_vfactive;
   logic  [10:0]                     ip2uio_rx_st1_vfnum;
   logic  [2:0]                      ip2uio_rx_st1_pfnum;
   logic  [(CXL_IO_CHWIDTH-1):0]     ip2uio_rx_st1_chnum;
   logic                             ip2uio_rx_st1_misc_parity;
   logic  [2:0]                      ip2uio_rx_st1_empty;  // [log2(CXL_IO_DWIDTH/32)-1:0]
  
   logic                             ip2uio_rx_st2_dvalid;
   logic                             ip2uio_rx_st2_sop;
   logic                             ip2uio_rx_st2_eop;
   logic                             ip2uio_rx_st2_passthrough;
   logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st2_data;
   logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st2_data_parity;
   logic  [127:0]                    ip2uio_rx_st2_hdr;
   logic  [3:0]                      ip2uio_rx_st2_hdr_parity;
   logic                             ip2uio_rx_st2_hvalid;
   logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st2_prefix;
   logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st2_prefix_parity;
   logic  [11:0]                     ip2uio_rx_st2_RSSAI_prefix;
   logic                             ip2uio_rx_st2_RSSAI_prefix_parity;
   logic  [1:0]                      ip2uio_rx_st2_pvalid;
   logic  [2:0]                      ip2uio_rx_st2_bar;
   logic                             ip2uio_rx_st2_vfactive;
   logic  [10:0]                     ip2uio_rx_st2_vfnum;
   logic  [2:0]                      ip2uio_rx_st2_pfnum;
   logic  [(CXL_IO_CHWIDTH-1):0]     ip2uio_rx_st2_chnum;
   logic                             ip2uio_rx_st2_misc_parity;
   logic  [2:0]                      ip2uio_rx_st2_empty;  // [log2(CXL_IO_DWIDTH/32)-1:0]

   logic                             ip2uio_rx_st3_dvalid;
   logic                             ip2uio_rx_st3_sop;
   logic                             ip2uio_rx_st3_eop;
   logic                             ip2uio_rx_st3_passthrough;
   logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st3_data;
   logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st3_data_parity;
   logic  [127:0]                    ip2uio_rx_st3_hdr;
   logic  [3:0]                      ip2uio_rx_st3_hdr_parity;
   logic                             ip2uio_rx_st3_hvalid;
   logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st3_prefix;
   logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st3_prefix_parity;
   logic  [11:0]                     ip2uio_rx_st3_RSSAI_prefix;
   logic                             ip2uio_rx_st3_RSSAI_prefix_parity;
   logic  [1:0]                      ip2uio_rx_st3_pvalid;
   logic  [2:0]                      ip2uio_rx_st3_bar;
   logic                             ip2uio_rx_st3_vfactive;
   logic  [10:0]                     ip2uio_rx_st3_vfnum;
   logic  [2:0]                      ip2uio_rx_st3_pfnum;
   logic  [(CXL_IO_CHWIDTH-1):0]     ip2uio_rx_st3_chnum;
   logic                             ip2uio_rx_st3_misc_parity;
   logic  [2:0]                      ip2uio_rx_st3_empty;  // [log2(CXL_IO_DWIDTH/32)-1:0]
  
    logic [2:0]                       uio2ip_rx_st_Hcrdt_update;
    logic [(CXL_IO_CHWIDTH-1):0]      uio2ip_rx_st_Hcrdt_ch;
    logic [5:0]                       uio2ip_rx_st_Hcrdt_update_cnt;
    logic [2:0]                       uio2ip_rx_st_Hcrdt_init;
   logic [2:0]                       ip2uio_rx_st_Hcrdt_init_ack;
    logic [2:0]                       uio2ip_rx_st_Dcrdt_update;
    logic [(CXL_IO_CHWIDTH-1):0]      uio2ip_rx_st_Dcrdt_ch;
    logic [11:0]                      uio2ip_rx_st_Dcrdt_update_cnt;
    logic [2:0]                       uio2ip_rx_st_Dcrdt_init;
   logic [2:0]                       ip2uio_rx_st_Dcrdt_init_ack;

   logic [7:0]                       ip2uio_bus_number ;                            
   logic [4:0]                       ip2uio_device_number ;

  //-------------------------------------------------------
  // Intel Reset control                                 --
  //-------------------------------------------------------

  wire nInit_done;        

  intel_reset_release reset_release (
    .ninit_done (nInit_done)
  );    
 


//>>>

  
  //-------------------------------------------------------
  // --------------------IP------------------  
  //-------------------------------------------------------

//<<<

  // QPDS DEBUG
  //cxl_type2_cxlip_top #(
  //`ifdef SIM_ADME_OFF     
  //.ADME_ENABLE (0) 
  //`else
  //.ADME_ENABLE (1) 
  //`endif
  //)
  //cxl_type2_cxlip_top 
  //( 
  intel_rtile_cxl_top_cxltyp2_ed intel_rtile_cxl_top_inst (
    .refclk0                                (refclk0       ) ,     // To R-Tile
    .refclk1                                (refclk1       ) ,     // To R-Tile
    .refclk4                                (refclk4       ) ,     // To Fabric PLL
    
    .resetn                                 (resetn        ) ,
    .nInit_done                             (nInit_done    ) ,    
    .cxl_warm_rst_n                         (cxl_warm_rst_n) ,     // OUTPUT  
    .cxl_cold_rst_n                         (cxl_cold_rst_n) ,     // OUTPUT

    .cxl_tx_n                               (cxl_tx_n      ) ,     // To R-tile
    .cxl_tx_p                               (cxl_tx_p      ) ,     // To R-tile
    .cxl_rx_n                               (cxl_rx_n      ) ,     // To R-tile
    .cxl_rx_p                               (cxl_rx_p      ) ,     // To R-tile

    .ip2hdm_clk                             (ip2hdm_clk    ) ,     // PLD clk 
    

// DDRMC <--> BBS Slice
    .ip2hdm_reset_n                        (ip2hdm_reset_n ),     // pipelined Warm reset from from BBS
    .hdm_size_256mb                        (hdm_size_256mb ),   	 
    .mc2ip_memsize                         (mc2ip_memsize  ),
  
`ifndef ENABLE_4_BBS_SLICE   // MC_CHANNEL=2

    //Channel-->0	  
   // .mc2ip_0_memsize                       (mc2ip_0_memsize            ),
    .mc2ip_0_sr_status                     (mc2ip_0_sr_status          ),

    .ip2hdm_avmm0_read                     (ip2hdm_avmm0_read          ),
    .ip2hdm_avmm0_write                    (ip2hdm_avmm0_write         ),
    .ip2hdm_avmm0_write_poison             (ip2hdm_avmm0_write_poison  ),
    .ip2hdm_avmm0_write_ras_sbe            (ip2hdm_avmm0_write_ras_sbe ),    
    .ip2hdm_avmm0_write_ras_dbe            (ip2hdm_avmm0_write_ras_dbe ),    
    .ip2hdm_avmm0_address                  (ip2hdm_avmm0_address       ),
    .ip2hdm_avmm0_req_mdata                (ip2hdm_avmm0_req_mdata     ),
    .ip2hdm_avmm0_writedata                (ip2hdm_avmm0_writedata     ),
    .ip2hdm_avmm0_byteenable               (ip2hdm_avmm0_byteenable    ),

    .hdm2ip_avmm0_ready                    (hdm2ip_avmm0_ready            ),
    .hdm2ip_avmm0_readdata                 (hdm2ip_avmm0_readdata         ),
    .hdm2ip_avmm0_rsp_mdata                (hdm2ip_avmm0_rsp_mdata        ),
    .hdm2ip_avmm0_cxlmem_ready             (hdm2ip_avmm0_cxlmem_ready     ),       
    .hdm2ip_avmm0_read_poison              (hdm2ip_avmm0_read_poison      ),
    .hdm2ip_avmm0_readdatavalid            (hdm2ip_avmm0_readdatavalid    ),
    .hdm2ip_avmm0_ecc_err_corrected        (hdm2ip_avmm0_ecc_err_corrected),
    .hdm2ip_avmm0_ecc_err_detected         (hdm2ip_avmm0_ecc_err_detected ),
    .hdm2ip_avmm0_ecc_err_fatal            (hdm2ip_avmm0_ecc_err_fatal    ),
    .hdm2ip_avmm0_ecc_err_syn_e            (hdm2ip_avmm0_ecc_err_syn_e    ),
    .hdm2ip_avmm0_ecc_err_valid            (hdm2ip_avmm0_ecc_err_valid    ),

    .mc2ip_0_rspfifo_full                  (mc2ip_0_rspfifo_full          ),
    .mc2ip_0_rspfifo_empty                 (mc2ip_0_rspfifo_empty         ),
    .mc2ip_0_rspfifo_fill_level            (mc2ip_0_rspfifo_fill_level    ),
    .mc2ip_0_reqfifo_full                  (mc2ip_0_reqfifo_full          ),
    .mc2ip_0_reqfifo_empty                 (mc2ip_0_reqfifo_empty         ),
    .mc2ip_0_reqfifo_fill_level            (mc2ip_0_reqfifo_fill_level    ),
	  
    //Channel-->1	  
    //.mc2ip_1_memsize                       (mc2ip_1_memsize            ),
    .mc2ip_1_sr_status                     (mc2ip_1_sr_status          ),

    .ip2hdm_avmm1_read                     (ip2hdm_avmm1_read          ),
    .ip2hdm_avmm1_write                    (ip2hdm_avmm1_write         ),
    .ip2hdm_avmm1_write_poison             (ip2hdm_avmm1_write_poison  ),
    .ip2hdm_avmm1_write_ras_sbe            (ip2hdm_avmm1_write_ras_sbe ),    
    .ip2hdm_avmm1_write_ras_dbe            (ip2hdm_avmm1_write_ras_dbe ),    
    .ip2hdm_avmm1_address                  (ip2hdm_avmm1_address       ),
    .ip2hdm_avmm1_req_mdata                (ip2hdm_avmm1_req_mdata     ),
    .ip2hdm_avmm1_writedata                (ip2hdm_avmm1_writedata     ),
    .ip2hdm_avmm1_byteenable               (ip2hdm_avmm1_byteenable    ),

    .hdm2ip_avmm1_ready                    (hdm2ip_avmm1_ready            ),
    .hdm2ip_avmm1_readdata                 (hdm2ip_avmm1_readdata         ),
    .hdm2ip_avmm1_rsp_mdata                (hdm2ip_avmm1_rsp_mdata        ),
    .hdm2ip_avmm1_cxlmem_ready             (hdm2ip_avmm1_cxlmem_ready     ),       
    .hdm2ip_avmm1_read_poison              (hdm2ip_avmm1_read_poison      ),
    .hdm2ip_avmm1_readdatavalid            (hdm2ip_avmm1_readdatavalid    ),
    .hdm2ip_avmm1_ecc_err_corrected        (hdm2ip_avmm1_ecc_err_corrected),
    .hdm2ip_avmm1_ecc_err_detected         (hdm2ip_avmm1_ecc_err_detected ),
    .hdm2ip_avmm1_ecc_err_fatal            (hdm2ip_avmm1_ecc_err_fatal    ),
    .hdm2ip_avmm1_ecc_err_syn_e            (hdm2ip_avmm1_ecc_err_syn_e    ),
    .hdm2ip_avmm1_ecc_err_valid            (hdm2ip_avmm1_ecc_err_valid    ),

    .mc2ip_1_rspfifo_full                  (mc2ip_1_rspfifo_full          ),
    .mc2ip_1_rspfifo_empty                 (mc2ip_1_rspfifo_empty         ),
    .mc2ip_1_rspfifo_fill_level            (mc2ip_1_rspfifo_fill_level    ),
    .mc2ip_1_reqfifo_full                  (mc2ip_1_reqfifo_full          ),
    .mc2ip_1_reqfifo_empty                 (mc2ip_1_reqfifo_empty         ),
    .mc2ip_1_reqfifo_fill_level            (mc2ip_1_reqfifo_fill_level    ),	  

`else

    // DDRMC <--> BBS Slice
	  
    //Channel-->0	  
//    .mc2ip_0_memsize                       (mc2ip_0_memsize            ),
    .mc2ip_0_sr_status                     (mc2ip_0_sr_status          ),

    .ip2hdm_avmm0_read                     (ip2hdm_avmm0_read          ),
    .ip2hdm_avmm0_write                    (ip2hdm_avmm0_write         ),
    .ip2hdm_avmm0_write_poison             (ip2hdm_avmm0_write_poison  ),
    .ip2hdm_avmm0_write_ras_sbe            (ip2hdm_avmm0_write_ras_sbe ),    
    .ip2hdm_avmm0_write_ras_dbe            (ip2hdm_avmm0_write_ras_dbe ),    
    .ip2hdm_avmm0_address                  (ip2hdm_avmm0_address       ),
    .ip2hdm_avmm0_req_mdata                (ip2hdm_avmm0_req_mdata     ),
    .ip2hdm_avmm0_writedata                (ip2hdm_avmm0_writedata     ),
    .ip2hdm_avmm0_byteenable               (ip2hdm_avmm0_byteenable    ),

    .hdm2ip_avmm0_ready                    (hdm2ip_avmm0_ready            ),
    .hdm2ip_avmm0_readdata                 (hdm2ip_avmm0_readdata         ),
    .hdm2ip_avmm0_rsp_mdata                (hdm2ip_avmm0_rsp_mdata        ),
    .hdm2ip_avmm0_cxlmem_ready             (hdm2ip_avmm0_cxlmem_ready     ),       
    .hdm2ip_avmm0_read_poison              (hdm2ip_avmm0_read_poison      ),
    .hdm2ip_avmm0_readdatavalid            (hdm2ip_avmm0_readdatavalid    ),
    .hdm2ip_avmm0_ecc_err_corrected        (hdm2ip_avmm0_ecc_err_corrected),
    .hdm2ip_avmm0_ecc_err_detected         (hdm2ip_avmm0_ecc_err_detected ),
    .hdm2ip_avmm0_ecc_err_fatal            (hdm2ip_avmm0_ecc_err_fatal    ),
    .hdm2ip_avmm0_ecc_err_syn_e            (hdm2ip_avmm0_ecc_err_syn_e    ),
    .hdm2ip_avmm0_ecc_err_valid            (hdm2ip_avmm0_ecc_err_valid    ),

    .mc2ip_0_rspfifo_full                  (mc2ip_0_rspfifo_full          ),
    .mc2ip_0_rspfifo_empty                 (mc2ip_0_rspfifo_empty         ),
    .mc2ip_0_rspfifo_fill_level            (mc2ip_0_rspfifo_fill_level    ),
    .mc2ip_0_reqfifo_full                  (mc2ip_0_reqfifo_full          ),
    .mc2ip_0_reqfifo_empty                 (mc2ip_0_reqfifo_empty         ),
    .mc2ip_0_reqfifo_fill_level            (mc2ip_0_reqfifo_fill_level    ),
	  
    //Channel-->1	  
    //.mc2ip_1_memsize                       (mc2ip_1_memsize            ),
    .mc2ip_1_sr_status                     (mc2ip_1_sr_status          ),

    .ip2hdm_avmm1_read                     (ip2hdm_avmm1_read          ),
    .ip2hdm_avmm1_write                    (ip2hdm_avmm1_write         ),
    .ip2hdm_avmm1_write_poison             (ip2hdm_avmm1_write_poison  ),
    .ip2hdm_avmm1_write_ras_sbe            (ip2hdm_avmm1_write_ras_sbe ),    
    .ip2hdm_avmm1_write_ras_dbe            (ip2hdm_avmm1_write_ras_dbe ),    
    .ip2hdm_avmm1_address                  (ip2hdm_avmm1_address       ),
    .ip2hdm_avmm1_req_mdata                (ip2hdm_avmm1_req_mdata     ),
    .ip2hdm_avmm1_writedata                (ip2hdm_avmm1_writedata     ),
    .ip2hdm_avmm1_byteenable               (ip2hdm_avmm1_byteenable    ),

    .hdm2ip_avmm1_ready                    (hdm2ip_avmm1_ready            ),
    .hdm2ip_avmm1_readdata                 (hdm2ip_avmm1_readdata         ),
    .hdm2ip_avmm1_rsp_mdata                (hdm2ip_avmm1_rsp_mdata        ),
    .hdm2ip_avmm1_cxlmem_ready             (hdm2ip_avmm1_cxlmem_ready     ),       
    .hdm2ip_avmm1_read_poison              (hdm2ip_avmm1_read_poison      ),
    .hdm2ip_avmm1_readdatavalid            (hdm2ip_avmm1_readdatavalid    ),
    .hdm2ip_avmm1_ecc_err_corrected        (hdm2ip_avmm1_ecc_err_corrected),
    .hdm2ip_avmm1_ecc_err_detected         (hdm2ip_avmm1_ecc_err_detected ),
    .hdm2ip_avmm1_ecc_err_fatal            (hdm2ip_avmm1_ecc_err_fatal    ),
    .hdm2ip_avmm1_ecc_err_syn_e            (hdm2ip_avmm1_ecc_err_syn_e    ),
    .hdm2ip_avmm1_ecc_err_valid            (hdm2ip_avmm1_ecc_err_valid    ),

    .mc2ip_1_rspfifo_full                  (mc2ip_1_rspfifo_full          ),
    .mc2ip_1_rspfifo_empty                 (mc2ip_1_rspfifo_empty         ),
    .mc2ip_1_rspfifo_fill_level            (mc2ip_1_rspfifo_fill_level    ),
    .mc2ip_1_reqfifo_full                  (mc2ip_1_reqfifo_full          ),
    .mc2ip_1_reqfifo_empty                 (mc2ip_1_reqfifo_empty         ),
    .mc2ip_1_reqfifo_fill_level            (mc2ip_1_reqfifo_fill_level    ),	  
	  
 

 //Channel-->2	  
    //.mc2ip_2_memsize                       (mc2ip_2_memsize            ),
    .mc2ip_2_sr_status                     (mc2ip_2_sr_status          ),

    .ip2hdm_avmm2_read                     (ip2hdm_avmm2_read          ),
    .ip2hdm_avmm2_write                    (ip2hdm_avmm2_write         ),
    .ip2hdm_avmm2_write_poison             (ip2hdm_avmm2_write_poison  ),
    .ip2hdm_avmm2_write_ras_sbe            (ip2hdm_avmm2_write_ras_sbe ),    
    .ip2hdm_avmm2_write_ras_dbe            (ip2hdm_avmm2_write_ras_dbe ),    
    .ip2hdm_avmm2_address                  (ip2hdm_avmm2_address       ),
    .ip2hdm_avmm2_req_mdata                (ip2hdm_avmm2_req_mdata     ),
    .ip2hdm_avmm2_writedata                (ip2hdm_avmm2_writedata     ),
    .ip2hdm_avmm2_byteenable               (ip2hdm_avmm2_byteenable    ),

    .hdm2ip_avmm2_ready                    (hdm2ip_avmm2_ready            ),
    .hdm2ip_avmm2_readdata                 (hdm2ip_avmm2_readdata         ),
    .hdm2ip_avmm2_rsp_mdata                (hdm2ip_avmm2_rsp_mdata        ),
    .hdm2ip_avmm2_cxlmem_ready             (hdm2ip_avmm2_cxlmem_ready     ),       
    .hdm2ip_avmm2_read_poison              (hdm2ip_avmm2_read_poison      ),
    .hdm2ip_avmm2_readdatavalid            (hdm2ip_avmm2_readdatavalid    ),
    .hdm2ip_avmm2_ecc_err_corrected        (hdm2ip_avmm2_ecc_err_corrected),
    .hdm2ip_avmm2_ecc_err_detected         (hdm2ip_avmm2_ecc_err_detected ),
    .hdm2ip_avmm2_ecc_err_fatal            (hdm2ip_avmm2_ecc_err_fatal    ),
    .hdm2ip_avmm2_ecc_err_syn_e            (hdm2ip_avmm2_ecc_err_syn_e    ),
    .hdm2ip_avmm2_ecc_err_valid            (hdm2ip_avmm2_ecc_err_valid    ),

    .mc2ip_2_rspfifo_full                  (mc2ip_2_rspfifo_full          ),
    .mc2ip_2_rspfifo_empty                 (mc2ip_2_rspfifo_empty         ),
    .mc2ip_2_rspfifo_fill_level            (mc2ip_2_rspfifo_fill_level    ),
    .mc2ip_2_reqfifo_full                  (mc2ip_2_reqfifo_full          ),
    .mc2ip_2_reqfifo_empty                 (mc2ip_2_reqfifo_empty         ),
    .mc2ip_2_reqfifo_fill_level            (mc2ip_2_reqfifo_fill_level    ),
	  
    //Channel-->3	  

    //.mc2ip_3_memsize                       (mc2ip_3_memsize            ),
    .mc2ip_3_sr_status                     (mc2ip_3_sr_status          ),

    .ip2hdm_avmm3_read                     (ip2hdm_avmm3_read          ),
    .ip2hdm_avmm3_write                    (ip2hdm_avmm3_write         ),
    .ip2hdm_avmm3_write_poison             (ip2hdm_avmm3_write_poison  ),
    .ip2hdm_avmm3_write_ras_sbe            (ip2hdm_avmm3_write_ras_sbe ),    
    .ip2hdm_avmm3_write_ras_dbe            (ip2hdm_avmm3_write_ras_dbe ),    
    .ip2hdm_avmm3_address                  (ip2hdm_avmm3_address       ),
    .ip2hdm_avmm3_req_mdata                (ip2hdm_avmm3_req_mdata     ),
    .ip2hdm_avmm3_writedata                (ip2hdm_avmm3_writedata     ),
    .ip2hdm_avmm3_byteenable               (ip2hdm_avmm3_byteenable    ),

    .hdm2ip_avmm3_ready                    (hdm2ip_avmm3_ready            ),
    .hdm2ip_avmm3_readdata                 (hdm2ip_avmm3_readdata         ),
    .hdm2ip_avmm3_rsp_mdata                (hdm2ip_avmm3_rsp_mdata        ),
    .hdm2ip_avmm3_cxlmem_ready             (hdm2ip_avmm3_cxlmem_ready     ),       
    .hdm2ip_avmm3_read_poison              (hdm2ip_avmm3_read_poison      ),
    .hdm2ip_avmm3_readdatavalid            (hdm2ip_avmm3_readdatavalid    ),
    .hdm2ip_avmm3_ecc_err_corrected        (hdm2ip_avmm3_ecc_err_corrected),
    .hdm2ip_avmm3_ecc_err_detected         (hdm2ip_avmm3_ecc_err_detected ),
    .hdm2ip_avmm3_ecc_err_fatal            (hdm2ip_avmm3_ecc_err_fatal    ),
    .hdm2ip_avmm3_ecc_err_syn_e            (hdm2ip_avmm3_ecc_err_syn_e    ),
    .hdm2ip_avmm3_ecc_err_valid            (hdm2ip_avmm3_ecc_err_valid    ),

    .mc2ip_3_rspfifo_full                  (mc2ip_3_rspfifo_full          ),
    .mc2ip_3_rspfifo_empty                 (mc2ip_3_rspfifo_empty         ),
    .mc2ip_3_rspfifo_fill_level            (mc2ip_3_rspfifo_fill_level    ),
    .mc2ip_3_reqfifo_full                  (mc2ip_3_reqfifo_full          ),
    .mc2ip_3_reqfifo_empty                 (mc2ip_3_reqfifo_empty         ),
    .mc2ip_3_reqfifo_fill_level            (mc2ip_3_reqfifo_fill_level    ),	  
	  

`endif	

 //AXI <--> AXI2CCIP_SHIM <--> CCIP        write address channels

   .cafu2ip_aximm0_awid                 (cafu2ip_aximm0_awid      ) ,
   .cafu2ip_aximm0_awaddr               (cafu2ip_aximm0_awaddr    ) , 
   .cafu2ip_aximm0_awlen                (cafu2ip_aximm0_awlen     ) ,
   .cafu2ip_aximm0_awsize               (cafu2ip_aximm0_awsize    ) ,
   .cafu2ip_aximm0_awburst              (cafu2ip_aximm0_awburst   ) ,
   .cafu2ip_aximm0_awprot               (cafu2ip_aximm0_awprot    ) ,
   .cafu2ip_aximm0_awqos                (cafu2ip_aximm0_awqos     ) ,
   .cafu2ip_aximm0_awuser               (cafu2ip_aximm0_awuser    ) ,
   .cafu2ip_aximm0_awvalid              (cafu2ip_aximm0_awvalid   ) ,
   .cafu2ip_aximm0_awcache              (cafu2ip_aximm0_awcache   ) ,
   .cafu2ip_aximm0_awlock               (cafu2ip_aximm0_awlock    ) ,
   .cafu2ip_aximm0_awregion             (cafu2ip_aximm0_awregion  ) ,
   .ip2cafu_aximm0_awready              (ip2cafu_aximm0_awready   ) ,
  
   .cafu2ip_aximm1_awid                 (cafu2ip_aximm1_awid      ) ,
   .cafu2ip_aximm1_awaddr               (cafu2ip_aximm1_awaddr    ),
   .cafu2ip_aximm1_awlen                (cafu2ip_aximm1_awlen     ),
   .cafu2ip_aximm1_awsize               (cafu2ip_aximm1_awsize    ),
   .cafu2ip_aximm1_awburst              (cafu2ip_aximm1_awburst   ),
   .cafu2ip_aximm1_awprot               (cafu2ip_aximm1_awprot    ),
   .cafu2ip_aximm1_awqos                (cafu2ip_aximm1_awqos     ),
   .cafu2ip_aximm1_awuser               (cafu2ip_aximm1_awuser    ),
   .cafu2ip_aximm1_awvalid              (cafu2ip_aximm1_awvalid   ),
   .cafu2ip_aximm1_awcache              (cafu2ip_aximm1_awcache   ),
   .cafu2ip_aximm1_awlock               (cafu2ip_aximm1_awlock    ),
   .cafu2ip_aximm1_awregion             (cafu2ip_aximm1_awregion  ),
   .ip2cafu_aximm1_awready              (ip2cafu_aximm1_awready   ), 

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write data channels
  
   .cafu2ip_aximm0_wdata                (cafu2ip_aximm0_wdata     ),
   .cafu2ip_aximm0_wstrb                (cafu2ip_aximm0_wstrb     ),
   .cafu2ip_aximm0_wlast                (cafu2ip_aximm0_wlast     ),
   .cafu2ip_aximm0_wuser                (cafu2ip_aximm0_wuser     ),
   .cafu2ip_aximm0_wvalid               (cafu2ip_aximm0_wvalid    ),
  //.cafu2ip_aximm0_wid                  (cafu2ip_aximm0_wid       ),
   .ip2cafu_aximm0_wready               (ip2cafu_aximm0_wready    ),
  
   .cafu2ip_aximm1_wdata                (cafu2ip_aximm1_wdata     ),
   .cafu2ip_aximm1_wstrb                (cafu2ip_aximm1_wstrb     ),
   .cafu2ip_aximm1_wlast                (cafu2ip_aximm1_wlast     ),
   .cafu2ip_aximm1_wuser                (cafu2ip_aximm1_wuser     ),
   .cafu2ip_aximm1_wvalid               (cafu2ip_aximm1_wvalid    ),
  //.cafu2ip_aximm1_wid                  (cafu2ip_aximm1_wid       ),
   .ip2cafu_aximm1_wready               (ip2cafu_aximm1_wready    ),

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write response channels

  .ip2cafu_aximm0_bid                  (ip2cafu_aximm0_bid       ),
  .ip2cafu_aximm0_bresp                (ip2cafu_aximm0_bresp     ),
  .ip2cafu_aximm0_buser                (ip2cafu_aximm0_buser     ),
  .ip2cafu_aximm0_bvalid               (ip2cafu_aximm0_bvalid    ),
  .cafu2ip_aximm0_bready               (cafu2ip_aximm0_bready    ),
  
  .ip2cafu_aximm1_bid                  (ip2cafu_aximm1_bid       ),
  .ip2cafu_aximm1_bresp                (ip2cafu_aximm1_bresp     ),
  .ip2cafu_aximm1_buser                (ip2cafu_aximm1_buser     ),
  .ip2cafu_aximm1_bvalid               (ip2cafu_aximm1_bvalid    ),
  .cafu2ip_aximm1_bready               (cafu2ip_aximm1_bready    ),

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read address channels

   .cafu2ip_aximm0_arid               (cafu2ip_aximm0_arid     ),
   .cafu2ip_aximm0_araddr             (cafu2ip_aximm0_araddr   ),
   .cafu2ip_aximm0_arlen              (cafu2ip_aximm0_arlen    ),
   .cafu2ip_aximm0_arsize             (cafu2ip_aximm0_arsize   ),
   .cafu2ip_aximm0_arburst            (cafu2ip_aximm0_arburst  ),
   .cafu2ip_aximm0_arprot             (cafu2ip_aximm0_arprot   ),
   .cafu2ip_aximm0_arqos              (cafu2ip_aximm0_arqos    ),
   .cafu2ip_aximm0_aruser             (cafu2ip_aximm0_aruser   ),
   .cafu2ip_aximm0_arvalid            (cafu2ip_aximm0_arvalid  ),
   .cafu2ip_aximm0_arcache            (cafu2ip_aximm0_arcache  ),
   .cafu2ip_aximm0_arlock             (cafu2ip_aximm0_arlock   ),
   .cafu2ip_aximm0_arregion           (cafu2ip_aximm0_arregion ),
   .ip2cafu_aximm0_arready            (ip2cafu_aximm0_arready  ),
  
   .cafu2ip_aximm1_arid               (cafu2ip_aximm1_arid     ),
   .cafu2ip_aximm1_araddr             (cafu2ip_aximm1_araddr   ),
   .cafu2ip_aximm1_arlen              (cafu2ip_aximm1_arlen    ),
   .cafu2ip_aximm1_arsize             (cafu2ip_aximm1_arsize   ),
   .cafu2ip_aximm1_arburst            (cafu2ip_aximm1_arburst  ),
   .cafu2ip_aximm1_arprot             (cafu2ip_aximm1_arprot   ),
   .cafu2ip_aximm1_arqos              (cafu2ip_aximm1_arqos    ),
   .cafu2ip_aximm1_aruser             (cafu2ip_aximm1_aruser   ),
   .cafu2ip_aximm1_arvalid            (cafu2ip_aximm1_arvalid  ),
   .cafu2ip_aximm1_arcache            (cafu2ip_aximm1_arcache  ),
   .cafu2ip_aximm1_arlock             (cafu2ip_aximm1_arlock   ),
   .cafu2ip_aximm1_arregion           (cafu2ip_aximm1_arregion ),
   .ip2cafu_aximm1_arready            (ip2cafu_aximm1_arready  ),
 


  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read response channels
 
   .ip2cafu_aximm0_rid               (ip2cafu_aximm0_rid     ),
   .ip2cafu_aximm0_rdata             (ip2cafu_aximm0_rdata   ),
   .ip2cafu_aximm0_rresp             (ip2cafu_aximm0_rresp   ),
   .ip2cafu_aximm0_rlast             (ip2cafu_aximm0_rlast   ),
   .ip2cafu_aximm0_ruser             (ip2cafu_aximm0_ruser   ),
   .ip2cafu_aximm0_rvalid            (ip2cafu_aximm0_rvalid  ),
   .cafu2ip_aximm0_rready            (cafu2ip_aximm0_rready  ),
  
   .ip2cafu_aximm1_rid               (ip2cafu_aximm1_rid     ),
   .ip2cafu_aximm1_rdata             (ip2cafu_aximm1_rdata   ),
   .ip2cafu_aximm1_rresp             (ip2cafu_aximm1_rresp   ),
   .ip2cafu_aximm1_rlast             (ip2cafu_aximm1_rlast   ),
   .ip2cafu_aximm1_ruser             (ip2cafu_aximm1_ruser   ),
   .ip2cafu_aximm1_rvalid            (ip2cafu_aximm1_rvalid  ),
   .cafu2ip_aximm1_rready            (cafu2ip_aximm1_rready  ),



// Mirror
    .ip2csr_avmm_clk           ,  
    .ip2csr_avmm_rstn          , 
    .csr2ip_avmm_waitrequest   ,   
    .csr2ip_avmm_readdata      ,  
    .csr2ip_avmm_readdatavalid , 
    .ip2csr_avmm_writedata     ,
    .ip2csr_avmm_address       ,
    .ip2csr_avmm_write         ,
    .ip2csr_avmm_read          ,
    .ip2csr_avmm_byteenable    ,

    .ip2cafu_avmm_clk            ,
    .ip2cafu_avmm_rstn           ,
    .cafu2ip_avmm_waitrequest    ,
    .cafu2ip_avmm_readdata       ,
    .cafu2ip_avmm_readdatavalid  ,
    .ip2cafu_avmm_burstcount     ,
    .ip2cafu_avmm_writedata      ,
    .ip2cafu_avmm_address        ,
    .ip2cafu_avmm_write          ,
    .ip2cafu_avmm_read           ,
    .ip2cafu_avmm_byteenable     , 

    .afu_bfe_quiesce_ack                 (afu_bfe_quiesce_ack),
    .bfe_afu_quiesce_req                 (bfe_afu_quiesce_req),
    .resetprep_en                        (resetprep_en),   

    .ccv_afu_conf_base_addr_high         (ccv_afu_conf_base_addr_high),
    .ccv_afu_conf_base_addr_high_valid   (ccv_afu_conf_base_addr_high_valid),
    .ccv_afu_conf_base_addr_low          (ccv_afu_conf_base_addr_low),
    .ccv_afu_conf_base_addr_low_valid    (ccv_afu_conf_base_addr_low_valid),

    .ip2uio_tx_ready                     (ip2uio_tx_ready                ),
    .uio2ip_tx_st0_dvalid                (uio2ip_tx_st0_dvalid             ),
    .uio2ip_tx_st0_sop                   (uio2ip_tx_st0_sop                ),
    .uio2ip_tx_st0_eop                   (uio2ip_tx_st0_eop                ),
    .uio2ip_tx_st0_passthrough           (uio2ip_tx_st0_passthrough        ),
    .uio2ip_tx_st0_data                  (uio2ip_tx_st0_data               ),
    .uio2ip_tx_st0_data_parity           (uio2ip_tx_st0_data_parity        ),
    .uio2ip_tx_st0_hdr                   (uio2ip_tx_st0_hdr                ),
    .uio2ip_tx_st0_hdr_parity            (uio2ip_tx_st0_hdr_parity         ),
    .uio2ip_tx_st0_hvalid                (uio2ip_tx_st0_hvalid             ),
    .uio2ip_tx_st0_prefix                (uio2ip_tx_st0_prefix             ),
    .uio2ip_tx_st0_prefix_parity         (uio2ip_tx_st0_prefix_parity      ),
    .uio2ip_tx_st0_RSSAI_prefix          (uio2ip_tx_st0_RSSAI_prefix       ),
    .uio2ip_tx_st0_RSSAI_prefix_parity   (uio2ip_tx_st0_RSSAI_prefix_parity),
    .uio2ip_tx_st0_pvalid                (uio2ip_tx_st0_pvalid             ),
    .uio2ip_tx_st0_vfactive              (uio2ip_tx_st0_vfactive           ),
    .uio2ip_tx_st0_vfnum                 (uio2ip_tx_st0_vfnum              ),
    .uio2ip_tx_st0_pfnum                 (uio2ip_tx_st0_pfnum              ),
    .uio2ip_tx_st0_chnum                 (uio2ip_tx_st0_chnum              ),
    .uio2ip_tx_st0_empty                 (uio2ip_tx_st0_empty              ),
    .uio2ip_tx_st0_misc_parity           (uio2ip_tx_st0_misc_parity        ),
  
    .uio2ip_tx_st1_dvalid                (uio2ip_tx_st1_dvalid             ),
    .uio2ip_tx_st1_sop                   (uio2ip_tx_st1_sop                ),
    .uio2ip_tx_st1_eop                   (uio2ip_tx_st1_eop                ),
    .uio2ip_tx_st1_passthrough           (uio2ip_tx_st1_passthrough        ),
    .uio2ip_tx_st1_data                  (uio2ip_tx_st1_data               ),
    .uio2ip_tx_st1_data_parity           (uio2ip_tx_st1_data_parity        ),
    .uio2ip_tx_st1_hdr                   (uio2ip_tx_st1_hdr                ),
    .uio2ip_tx_st1_hdr_parity            (uio2ip_tx_st1_hdr_parity         ),
    .uio2ip_tx_st1_hvalid                (uio2ip_tx_st1_hvalid             ),
    .uio2ip_tx_st1_prefix                (uio2ip_tx_st1_prefix             ),
    .uio2ip_tx_st1_prefix_parity         (uio2ip_tx_st1_prefix_parity      ),
    .uio2ip_tx_st1_RSSAI_prefix          (uio2ip_tx_st1_RSSAI_prefix       ),
    .uio2ip_tx_st1_RSSAI_prefix_parity   (uio2ip_tx_st1_RSSAI_prefix_parity),
    .uio2ip_tx_st1_pvalid                (uio2ip_tx_st1_pvalid             ),
    .uio2ip_tx_st1_vfactive              (uio2ip_tx_st1_vfactive           ),
    .uio2ip_tx_st1_vfnum                 (uio2ip_tx_st1_vfnum              ),
    .uio2ip_tx_st1_pfnum                 (uio2ip_tx_st1_pfnum              ),
    .uio2ip_tx_st1_chnum                 (uio2ip_tx_st1_chnum              ),
    .uio2ip_tx_st1_empty                 (uio2ip_tx_st1_empty              ),
    .uio2ip_tx_st1_misc_parity           (uio2ip_tx_st1_misc_parity        ),
  
    .uio2ip_tx_st2_dvalid                (uio2ip_tx_st2_dvalid             ),
    .uio2ip_tx_st2_sop                   (uio2ip_tx_st2_sop                ),
    .uio2ip_tx_st2_eop                   (uio2ip_tx_st2_eop                ),
    .uio2ip_tx_st2_passthrough           (uio2ip_tx_st2_passthrough        ),
    .uio2ip_tx_st2_data                  (uio2ip_tx_st2_data               ),
    .uio2ip_tx_st2_data_parity           (uio2ip_tx_st2_data_parity        ),
    .uio2ip_tx_st2_hdr                   (uio2ip_tx_st2_hdr                ),
    .uio2ip_tx_st2_hdr_parity            (uio2ip_tx_st2_hdr_parity         ),
    .uio2ip_tx_st2_hvalid                (uio2ip_tx_st2_hvalid             ),
    .uio2ip_tx_st2_prefix                (uio2ip_tx_st2_prefix             ),
    .uio2ip_tx_st2_prefix_parity         (uio2ip_tx_st2_prefix_parity      ),
    .uio2ip_tx_st2_RSSAI_prefix          (uio2ip_tx_st2_RSSAI_prefix       ),
    .uio2ip_tx_st2_RSSAI_prefix_parity   (uio2ip_tx_st2_RSSAI_prefix_parity),
    .uio2ip_tx_st2_pvalid                (uio2ip_tx_st2_pvalid             ),
    .uio2ip_tx_st2_vfactive              (uio2ip_tx_st2_vfactive           ),
    .uio2ip_tx_st2_vfnum                 (uio2ip_tx_st2_vfnum              ),
    .uio2ip_tx_st2_pfnum                 (uio2ip_tx_st2_pfnum              ),
    .uio2ip_tx_st2_chnum                 (uio2ip_tx_st2_chnum              ),
    .uio2ip_tx_st2_empty                 (uio2ip_tx_st2_empty              ),
    .uio2ip_tx_st2_misc_parity           (uio2ip_tx_st2_misc_parity        ),
  
    .uio2ip_tx_st3_dvalid                (uio2ip_tx_st3_dvalid             ),
    .uio2ip_tx_st3_sop                   (uio2ip_tx_st3_sop                ),
    .uio2ip_tx_st3_eop                   (uio2ip_tx_st3_eop                ),
    .uio2ip_tx_st3_passthrough           (uio2ip_tx_st3_passthrough        ),
    .uio2ip_tx_st3_data                  (uio2ip_tx_st3_data               ),
    .uio2ip_tx_st3_data_parity           (uio2ip_tx_st3_data_parity        ),
    .uio2ip_tx_st3_hdr                   (uio2ip_tx_st3_hdr                ),
    .uio2ip_tx_st3_hdr_parity            (uio2ip_tx_st3_hdr_parity         ),
    .uio2ip_tx_st3_hvalid                (uio2ip_tx_st3_hvalid             ),
    .uio2ip_tx_st3_prefix                (uio2ip_tx_st3_prefix             ),
    .uio2ip_tx_st3_prefix_parity         (uio2ip_tx_st3_prefix_parity      ),
    .uio2ip_tx_st3_RSSAI_prefix          (uio2ip_tx_st3_RSSAI_prefix       ),
    .uio2ip_tx_st3_RSSAI_prefix_parity   (uio2ip_tx_st3_RSSAI_prefix_parity),
    .uio2ip_tx_st3_pvalid                (uio2ip_tx_st3_pvalid             ),
    .uio2ip_tx_st3_vfactive              (uio2ip_tx_st3_vfactive           ),
    .uio2ip_tx_st3_vfnum                 (uio2ip_tx_st3_vfnum              ),
    .uio2ip_tx_st3_pfnum                 (uio2ip_tx_st3_pfnum              ),
    .uio2ip_tx_st3_chnum                 (uio2ip_tx_st3_chnum              ),
    .uio2ip_tx_st3_empty                 (uio2ip_tx_st3_empty              ),
    .uio2ip_tx_st3_misc_parity           (uio2ip_tx_st3_misc_parity        ),

    .ip2uio_tx_st_Hcrdt_update           (ip2uio_tx_st_Hcrdt_update          ),
    .ip2uio_tx_st_Hcrdt_ch               (ip2uio_tx_st_Hcrdt_ch              ),
    .ip2uio_tx_st_Hcrdt_update_cnt       (ip2uio_tx_st_Hcrdt_update_cnt      ),
    .ip2uio_tx_st_Hcrdt_init             (ip2uio_tx_st_Hcrdt_init            ),
    .uio2ip_tx_st_Hcrdt_init_ack         (uio2ip_tx_st_Hcrdt_init_ack        ),
    .ip2uio_tx_st_Dcrdt_update           (ip2uio_tx_st_Dcrdt_update          ),
    .ip2uio_tx_st_Dcrdt_ch               (ip2uio_tx_st_Dcrdt_ch              ),
    .ip2uio_tx_st_Dcrdt_update_cnt       (ip2uio_tx_st_Dcrdt_update_cnt      ),
    .ip2uio_tx_st_Dcrdt_init             (ip2uio_tx_st_Dcrdt_init            ),
    .uio2ip_tx_st_Dcrdt_init_ack         (uio2ip_tx_st_Dcrdt_init_ack        ),
  
    .ip2uio_rx_st0_dvalid                (ip2uio_rx_st0_dvalid             ),
    .ip2uio_rx_st0_sop                   (ip2uio_rx_st0_sop                ),
    .ip2uio_rx_st0_eop                   (ip2uio_rx_st0_eop                ),
    .ip2uio_rx_st0_passthrough           (ip2uio_rx_st0_passthrough        ),
    .ip2uio_rx_st0_data                  (ip2uio_rx_st0_data               ),
    .ip2uio_rx_st0_data_parity           (ip2uio_rx_st0_data_parity        ),
    .ip2uio_rx_st0_hdr                   (ip2uio_rx_st0_hdr                ),
    .ip2uio_rx_st0_hdr_parity            (ip2uio_rx_st0_hdr_parity         ),
    .ip2uio_rx_st0_hvalid                (ip2uio_rx_st0_hvalid             ),
    .ip2uio_rx_st0_prefix                (ip2uio_rx_st0_prefix             ),
    .ip2uio_rx_st0_prefix_parity         (ip2uio_rx_st0_prefix_parity      ),
    .ip2uio_rx_st0_RSSAI_prefix          (ip2uio_rx_st0_RSSAI_prefix       ),
    .ip2uio_rx_st0_RSSAI_prefix_parity   (ip2uio_rx_st0_RSSAI_prefix_parity),
    .ip2uio_rx_st0_pvalid                (ip2uio_rx_st0_pvalid             ),
    .ip2uio_rx_st0_bar                   (ip2uio_rx_st0_bar                ),
    .ip2uio_rx_st0_vfactive              (ip2uio_rx_st0_vfactive           ),
    .ip2uio_rx_st0_vfnum                 (ip2uio_rx_st0_vfnum              ),
    .ip2uio_rx_st0_pfnum                 (ip2uio_rx_st0_pfnum              ),
    .ip2uio_rx_st0_chnum                 (ip2uio_rx_st0_chnum              ),
    .ip2uio_rx_st0_misc_parity           (ip2uio_rx_st0_misc_parity        ),
    .ip2uio_rx_st0_empty                 (ip2uio_rx_st0_empty              ),
  
    .ip2uio_rx_st1_dvalid                (ip2uio_rx_st1_dvalid             ),
    .ip2uio_rx_st1_sop                   (ip2uio_rx_st1_sop                ),
    .ip2uio_rx_st1_eop                   (ip2uio_rx_st1_eop                ),
    .ip2uio_rx_st1_passthrough           (ip2uio_rx_st1_passthrough        ),
    .ip2uio_rx_st1_data                  (ip2uio_rx_st1_data               ),
    .ip2uio_rx_st1_data_parity           (ip2uio_rx_st1_data_parity        ),
    .ip2uio_rx_st1_hdr                   (ip2uio_rx_st1_hdr                ),
    .ip2uio_rx_st1_hdr_parity            (ip2uio_rx_st1_hdr_parity         ),
    .ip2uio_rx_st1_hvalid                (ip2uio_rx_st1_hvalid             ),
    .ip2uio_rx_st1_prefix                (ip2uio_rx_st1_prefix             ),
    .ip2uio_rx_st1_prefix_parity         (ip2uio_rx_st1_prefix_parity      ),
    .ip2uio_rx_st1_RSSAI_prefix          (ip2uio_rx_st1_RSSAI_prefix       ),
    .ip2uio_rx_st1_RSSAI_prefix_parity   (ip2uio_rx_st1_RSSAI_prefix_parity),
    .ip2uio_rx_st1_pvalid                (ip2uio_rx_st1_pvalid             ),
    .ip2uio_rx_st1_bar                   (ip2uio_rx_st1_bar                ),
    .ip2uio_rx_st1_vfactive              (ip2uio_rx_st1_vfactive           ),
    .ip2uio_rx_st1_vfnum                 (ip2uio_rx_st1_vfnum              ),
    .ip2uio_rx_st1_pfnum                 (ip2uio_rx_st1_pfnum              ),
    .ip2uio_rx_st1_chnum                 (ip2uio_rx_st1_chnum              ),
    .ip2uio_rx_st1_misc_parity           (ip2uio_rx_st1_misc_parity        ),
    .ip2uio_rx_st1_empty                 (ip2uio_rx_st1_empty              ),
  
    .ip2uio_rx_st2_dvalid                (ip2uio_rx_st2_dvalid             ),
    .ip2uio_rx_st2_sop                   (ip2uio_rx_st2_sop                ),
    .ip2uio_rx_st2_eop                   (ip2uio_rx_st2_eop                ),
    .ip2uio_rx_st2_passthrough           (ip2uio_rx_st2_passthrough        ),
    .ip2uio_rx_st2_data                  (ip2uio_rx_st2_data               ),
    .ip2uio_rx_st2_data_parity           (ip2uio_rx_st2_data_parity        ),
    .ip2uio_rx_st2_hdr                   (ip2uio_rx_st2_hdr                ),
    .ip2uio_rx_st2_hdr_parity            (ip2uio_rx_st2_hdr_parity         ),
    .ip2uio_rx_st2_hvalid                (ip2uio_rx_st2_hvalid             ),
    .ip2uio_rx_st2_prefix                (ip2uio_rx_st2_prefix             ),
    .ip2uio_rx_st2_prefix_parity         (ip2uio_rx_st2_prefix_parity      ),
    .ip2uio_rx_st2_RSSAI_prefix          (ip2uio_rx_st2_RSSAI_prefix       ),
    .ip2uio_rx_st2_RSSAI_prefix_parity   (ip2uio_rx_st2_RSSAI_prefix_parity),
    .ip2uio_rx_st2_pvalid                (ip2uio_rx_st2_pvalid             ),
    .ip2uio_rx_st2_bar                   (ip2uio_rx_st2_bar                ),
    .ip2uio_rx_st2_vfactive              (ip2uio_rx_st2_vfactive           ),
    .ip2uio_rx_st2_vfnum                 (ip2uio_rx_st2_vfnum              ),
    .ip2uio_rx_st2_pfnum                 (ip2uio_rx_st2_pfnum              ),
    .ip2uio_rx_st2_chnum                 (ip2uio_rx_st2_chnum              ),
    .ip2uio_rx_st2_misc_parity           (ip2uio_rx_st2_misc_parity        ),
    .ip2uio_rx_st2_empty                 (ip2uio_rx_st2_empty              ),
    
    .ip2uio_rx_st3_dvalid                (ip2uio_rx_st3_dvalid             ),
    .ip2uio_rx_st3_sop                   (ip2uio_rx_st3_sop                ),
    .ip2uio_rx_st3_eop                   (ip2uio_rx_st3_eop                ),
    .ip2uio_rx_st3_passthrough           (ip2uio_rx_st3_passthrough        ),
    .ip2uio_rx_st3_data                  (ip2uio_rx_st3_data               ),
    .ip2uio_rx_st3_data_parity           (ip2uio_rx_st3_data_parity        ),
    .ip2uio_rx_st3_hdr                   (ip2uio_rx_st3_hdr                ),
    .ip2uio_rx_st3_hdr_parity            (ip2uio_rx_st3_hdr_parity         ),
    .ip2uio_rx_st3_hvalid                (ip2uio_rx_st3_hvalid             ),
    .ip2uio_rx_st3_prefix                (ip2uio_rx_st3_prefix             ),
    .ip2uio_rx_st3_prefix_parity         (ip2uio_rx_st3_prefix_parity      ),
    .ip2uio_rx_st3_RSSAI_prefix          (ip2uio_rx_st3_RSSAI_prefix       ),
    .ip2uio_rx_st3_RSSAI_prefix_parity   (ip2uio_rx_st3_RSSAI_prefix_parity),
    .ip2uio_rx_st3_pvalid                (ip2uio_rx_st3_pvalid             ),
    .ip2uio_rx_st3_bar                   (ip2uio_rx_st3_bar                ),
    .ip2uio_rx_st3_vfactive              (ip2uio_rx_st3_vfactive           ),
    .ip2uio_rx_st3_vfnum                 (ip2uio_rx_st3_vfnum              ),
    .ip2uio_rx_st3_pfnum                 (ip2uio_rx_st3_pfnum              ),
    .ip2uio_rx_st3_chnum                 (ip2uio_rx_st3_chnum              ),
    .ip2uio_rx_st3_misc_parity           (ip2uio_rx_st3_misc_parity        ),
    .ip2uio_rx_st3_empty                 (ip2uio_rx_st3_empty              ),
  
    .uio2ip_rx_st_Hcrdt_update           (uio2ip_rx_st_Hcrdt_update         ),
    .uio2ip_rx_st_Hcrdt_ch               (uio2ip_rx_st_Hcrdt_ch             ),
    .uio2ip_rx_st_Hcrdt_update_cnt       (uio2ip_rx_st_Hcrdt_update_cnt     ),
    .uio2ip_rx_st_Hcrdt_init             (uio2ip_rx_st_Hcrdt_init           ),
    .ip2uio_rx_st_Hcrdt_init_ack         (ip2uio_rx_st_Hcrdt_init_ack       ),
    .uio2ip_rx_st_Dcrdt_update           (uio2ip_rx_st_Dcrdt_update         ),
    .uio2ip_rx_st_Dcrdt_ch               (uio2ip_rx_st_Dcrdt_ch             ),
    .uio2ip_rx_st_Dcrdt_update_cnt       (uio2ip_rx_st_Dcrdt_update_cnt     ),
    .uio2ip_rx_st_Dcrdt_init             (uio2ip_rx_st_Dcrdt_init           ),
    .ip2uio_rx_st_Dcrdt_init_ack         (ip2uio_rx_st_Dcrdt_init_ack       ),

    .ip2uio_bus_number                   (ip2uio_bus_number                 ) , 
    .ip2uio_device_number                (ip2uio_device_number              )  
  );
  
//>>> 


  //-------------------------------------------------------
  //---------------- Example Design ------------------
  //-------------------------------------------------------

//<<<

ed_top_wrapper_typ2 ed_top_wrapper_typ2_inst
(
 // Clocks
  .ip2hdm_clk                           (ip2hdm_clk),          // SIP clk    : $PLD CLK

 // Resets
  .ip2hdm_reset_n                      (ip2hdm_reset_n),

  .ccv_afu_conf_base_addr_high         (ccv_afu_conf_base_addr_high),
  .ccv_afu_conf_base_addr_high_valid   (ccv_afu_conf_base_addr_high_valid),
  .ccv_afu_conf_base_addr_low          (ccv_afu_conf_base_addr_low),
  .ccv_afu_conf_base_addr_low_valid    (ccv_afu_conf_base_addr_low_valid),

  
 //AXI <--> AXI2CCIP_SHIM <--> CCIP        write address channels

   .axi0_awid                         (cafu2ip_aximm0_awid)     ,
   .axi0_awaddr                       (cafu2ip_aximm0_awaddr)   , 
   .axi0_awlen                        (cafu2ip_aximm0_awlen)    ,
   .axi0_awsize                       (cafu2ip_aximm0_awsize)   ,
   .axi0_awburst                      (cafu2ip_aximm0_awburst)  ,
   .axi0_awprot                       (cafu2ip_aximm0_awprot)   ,
   .axi0_awqos                        (cafu2ip_aximm0_awqos)    ,
   .axi0_awuser                       (cafu2ip_aximm0_awuser)   ,
   .axi0_awvalid                      (cafu2ip_aximm0_awvalid)  ,
   .axi0_awcache                      (cafu2ip_aximm0_awcache)  ,
   .axi0_awlock                       (cafu2ip_aximm0_awlock)   ,
   .axi0_awregion                     (cafu2ip_aximm0_awregion) ,
   .axi0_awready                      (ip2cafu_aximm0_awready)  ,
  
   .axi1_awid                         (cafu2ip_aximm1_awid)     ,
   .axi1_awaddr                       (cafu2ip_aximm1_awaddr)   ,
   .axi1_awlen                        (cafu2ip_aximm1_awlen)    ,
   .axi1_awsize                       (cafu2ip_aximm1_awsize)   ,
   .axi1_awburst                      (cafu2ip_aximm1_awburst)  ,
   .axi1_awprot                       (cafu2ip_aximm1_awprot)   ,
   .axi1_awqos                        (cafu2ip_aximm1_awqos)    ,
   .axi1_awuser                       (cafu2ip_aximm1_awuser)   ,
   .axi1_awvalid                      (cafu2ip_aximm1_awvalid)  ,
   .axi1_awcache                      (cafu2ip_aximm1_awcache)  ,
   .axi1_awlock                       (cafu2ip_aximm1_awlock)   ,
   .axi1_awregion                     (cafu2ip_aximm1_awregion) ,
   .axi1_awready                      (ip2cafu_aximm1_awready)  , 

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write data channels
  
   .axi0_wdata                        (cafu2ip_aximm0_wdata ),
   .axi0_wstrb                        (cafu2ip_aximm0_wstrb ),
   .axi0_wlast                        (cafu2ip_aximm0_wlast ),
   .axi0_wuser                        (cafu2ip_aximm0_wuser ),
   .axi0_wvalid                       (cafu2ip_aximm0_wvalid),
 //  .axi0_wid                          (cafu2ip_aximm0_wid)   ,
   .axi0_wready                       (ip2cafu_aximm0_wready),
  
   .axi1_wdata                        (cafu2ip_aximm1_wdata ),
   .axi1_wstrb                        (cafu2ip_aximm1_wstrb ),
   .axi1_wlast                        (cafu2ip_aximm1_wlast ),
   .axi1_wuser                        (cafu2ip_aximm1_wuser ),
   .axi1_wvalid                       (cafu2ip_aximm1_wvalid),
  // .axi1_wid                          (cafu2ip_aximm1_wid)   ,
   .axi1_wready                       (ip2cafu_aximm1_wready),

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        write response channels

  .axi0_bid                          (ip2cafu_aximm0_bid)    ,
  .axi0_bresp                        (ip2cafu_aximm0_bresp)  ,
  .axi0_buser                        (ip2cafu_aximm0_buser)  ,
  .axi0_bvalid                       (ip2cafu_aximm0_bvalid) ,
  .axi0_bready                       (cafu2ip_aximm0_bready) ,
  
  .axi1_bid                          (ip2cafu_aximm1_bid)    ,
  .axi1_bresp                        (ip2cafu_aximm1_bresp)  ,
  .axi1_buser                        (ip2cafu_aximm1_buser)  ,
  .axi1_bvalid                       (ip2cafu_aximm1_bvalid) ,
  .axi1_bready                       (cafu2ip_aximm1_bready) ,

  
  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read address channels

   .axi0_arid                        (cafu2ip_aximm0_arid     ),
   .axi0_araddr                      (cafu2ip_aximm0_araddr   ),
   .axi0_arlen                       (cafu2ip_aximm0_arlen    ),
   .axi0_arsize                      (cafu2ip_aximm0_arsize   ),
   .axi0_arburst                     (cafu2ip_aximm0_arburst  ),
   .axi0_arprot                      (cafu2ip_aximm0_arprot   ),
   .axi0_arqos                       (cafu2ip_aximm0_arqos    ),
   .axi0_aruser                      (cafu2ip_aximm0_aruser   ),
   .axi0_arvalid                     (cafu2ip_aximm0_arvalid  ),
   .axi0_arcache                     (cafu2ip_aximm0_arcache  ),
   .axi0_arlock                      (cafu2ip_aximm0_arlock   ),
   .axi0_arregion                    (cafu2ip_aximm0_arregion ),
   .axi0_arready                     (ip2cafu_aximm0_arready  ),
  
   .axi1_arid                        (cafu2ip_aximm1_arid     ),
   .axi1_araddr                      (cafu2ip_aximm1_araddr   ),
   .axi1_arlen                       (cafu2ip_aximm1_arlen    ),
   .axi1_arsize                      (cafu2ip_aximm1_arsize   ),
   .axi1_arburst                     (cafu2ip_aximm1_arburst  ),
   .axi1_arprot                      (cafu2ip_aximm1_arprot   ),
   .axi1_arqos                       (cafu2ip_aximm1_arqos    ),
   .axi1_aruser                      (cafu2ip_aximm1_aruser   ),
   .axi1_arvalid                     (cafu2ip_aximm1_arvalid  ),
   .axi1_arcache                     (cafu2ip_aximm1_arcache  ),
   .axi1_arlock                      (cafu2ip_aximm1_arlock   ),
   .axi1_arregion                    (cafu2ip_aximm1_arregion ),
   .axi1_arready                     (ip2cafu_aximm1_arready  ),
 


  //AXI <--> AXI2CCIP_SHIM <--> CCIP        read response channels
 
   .axi0_rid                        (ip2cafu_aximm0_rid     ),
   .axi0_rdata                      (ip2cafu_aximm0_rdata   ),
   .axi0_rresp                      (ip2cafu_aximm0_rresp   ),
   .axi0_rlast                      (ip2cafu_aximm0_rlast   ),
   .axi0_ruser                      (ip2cafu_aximm0_ruser   ),
   .axi0_rvalid                     (ip2cafu_aximm0_rvalid  ),
   .axi0_rready                     (cafu2ip_aximm0_rready  ),
  
   .axi1_rid                        (ip2cafu_aximm1_rid     ),
   .axi1_rdata                      (ip2cafu_aximm1_rdata   ),
   .axi1_rresp                      (ip2cafu_aximm1_rresp   ),
   .axi1_rlast                      (ip2cafu_aximm1_rlast   ),
   .axi1_ruser                      (ip2cafu_aximm1_ruser   ),
   .axi1_rvalid                     (ip2cafu_aximm1_rvalid  ),
   .axi1_rready                     (cafu2ip_aximm1_rready  ),

  
 // Between AFU and Cambria 
  .afu_cam_ext5                    (afu_cam_ext5),
  .afu_cam_ext6                    (afu_cam_ext6),

  .cam_afu_ext5                    (cam_afu_ext5),
  .cam_afu_ext6                    (cam_afu_ext6),

  // Between AFU and BBS 
  .resetprep_en                    (resetprep_en),
  .bfe_afu_quiesce_req             (bfe_afu_quiesce_req),
  .afu_bfe_quiesce_ack             (afu_bfe_quiesce_ack),

  //CSR Access AVMM Bus
  .ip2cafu_avmm_clk             , // AVMM clock : 125MHz
  .ip2cafu_avmm_rstn            ,
  .cafu2ip_avmm_waitrequest     ,
  .cafu2ip_avmm_readdata        ,
  .cafu2ip_avmm_readdatavalid   ,
  .ip2cafu_avmm_writedata       ,
  .ip2cafu_avmm_address         ,
  .ip2cafu_avmm_write           ,
  .ip2cafu_avmm_read            ,
  .ip2cafu_avmm_byteenable      ,

 
//ex_default_csr_top ex_default_csr_top_inst
    .ip2csr_avmm_clk                   ,
    .ip2csr_avmm_rstn                  ,
    .csr2ip_avmm_waitrequest           ,
    .csr2ip_avmm_readdata              ,
    .csr2ip_avmm_readdatavalid         ,
    .ip2csr_avmm_writedata             ,
    .ip2csr_avmm_address               ,
    .ip2csr_avmm_write                 ,
    .ip2csr_avmm_read                  ,
    .ip2csr_avmm_byteenable            , 

//intel_cxl_pio_ed_top intel_cxl_pio_ed_top_inst 
    .ed_rx_st0_bar_i                  (ip2uio_rx_st0_bar                   ) ,                                 
    .ed_rx_st1_bar_i                  (ip2uio_rx_st1_bar                   ) ,                                 
    .ed_rx_st2_bar_i                  (ip2uio_rx_st2_bar                   ) ,                                 
    .ed_rx_st3_bar_i                  (ip2uio_rx_st3_bar                   ) ,                                 
    .ed_rx_st0_eop_i                  (ip2uio_rx_st0_eop                   ) ,                                 
    .ed_rx_st1_eop_i                  (ip2uio_rx_st1_eop                   ) ,                                 
    .ed_rx_st2_eop_i                  (ip2uio_rx_st2_eop                   ) ,                                 
    .ed_rx_st3_eop_i                  (ip2uio_rx_st3_eop                   ) ,                                 
    .ed_rx_st0_header_i               (ip2uio_rx_st0_hdr                   ) ,                                 
    .ed_rx_st1_header_i               (ip2uio_rx_st1_hdr                   ) ,                                 
    .ed_rx_st2_header_i               (ip2uio_rx_st2_hdr                   ) ,                                 
    .ed_rx_st3_header_i               (ip2uio_rx_st3_hdr                   ) ,                                 
    .ed_rx_st0_payload_i              (ip2uio_rx_st0_data               ) ,                                 
    .ed_rx_st1_payload_i              (ip2uio_rx_st1_data               ) ,                                 
    .ed_rx_st2_payload_i              (ip2uio_rx_st2_data               ) ,                                 
    .ed_rx_st3_payload_i              (ip2uio_rx_st3_data               ) ,                                 
    .ed_rx_st0_sop_i                  (ip2uio_rx_st0_sop                   ) ,                                 
    .ed_rx_st1_sop_i                  (ip2uio_rx_st1_sop                   ) ,                                 
    .ed_rx_st2_sop_i                  (ip2uio_rx_st2_sop                   ) ,                                 
    .ed_rx_st3_sop_i                  (ip2uio_rx_st3_sop                   ) ,                                 
    .ed_rx_st0_hvalid_i               (ip2uio_rx_st0_hvalid                ) ,                                 
    .ed_rx_st1_hvalid_i               (ip2uio_rx_st1_hvalid                ) ,                                 
    .ed_rx_st2_hvalid_i               (ip2uio_rx_st2_hvalid                ) ,                                 
    .ed_rx_st3_hvalid_i               (ip2uio_rx_st3_hvalid                ) ,                                 
    .ed_rx_st0_dvalid_i               (ip2uio_rx_st0_dvalid                ) ,                                 
    .ed_rx_st1_dvalid_i               (ip2uio_rx_st1_dvalid                ) ,                                 
    .ed_rx_st2_dvalid_i               (ip2uio_rx_st2_dvalid                ) ,                                 
    .ed_rx_st3_dvalid_i               (ip2uio_rx_st3_dvalid                ) ,                                 
    .ed_rx_st0_pvalid_i               (ip2uio_rx_st0_pvalid                ) ,                                 
    .ed_rx_st1_pvalid_i               (ip2uio_rx_st1_pvalid                ) ,                                 
    .ed_rx_st2_pvalid_i               (ip2uio_rx_st2_pvalid                ) ,                                 
    .ed_rx_st3_pvalid_i               (ip2uio_rx_st3_pvalid                ) ,                                 
    .ed_rx_st0_empty_i                (ip2uio_rx_st0_empty                 ) ,                                 
    .ed_rx_st1_empty_i                (ip2uio_rx_st1_empty                 ) ,                                 
    .ed_rx_st2_empty_i                (ip2uio_rx_st2_empty                 ) ,                                 
    .ed_rx_st3_empty_i                (ip2uio_rx_st3_empty                 ) ,                                 
    .ed_rx_st0_pfnum_i                (ip2uio_rx_st0_pfnum                 ) ,    
    .ed_rx_st1_pfnum_i                (ip2uio_rx_st1_pfnum                 ) ,                                 
    .ed_rx_st2_pfnum_i                (ip2uio_rx_st2_pfnum                 ) ,                                 
    .ed_rx_st3_pfnum_i                (ip2uio_rx_st3_pfnum                 ) ,                                 
    .ed_rx_st0_tlp_prfx_i             (ip2uio_rx_st0_prefix                ) ,                                 
    .ed_rx_st1_tlp_prfx_i             (ip2uio_rx_st1_prefix                ) ,                                 
    .ed_rx_st2_tlp_prfx_i             (ip2uio_rx_st2_prefix                ) ,                                 
    .ed_rx_st3_tlp_prfx_i             (ip2uio_rx_st3_prefix                ) ,                                 
    .ed_rx_st0_data_parity_i          (ip2uio_rx_st0_data_parity           ) ,                                 
    .ed_rx_st0_hdr_parity_i           (ip2uio_rx_st0_hdr_parity            ) ,                                   
    .ed_rx_st0_tlp_prfx_parity_i      (ip2uio_rx_st0_prefix_parity       ) ,                                   
    .ed_rx_st0_rssai_prefix_i         (ip2uio_rx_st0_RSSAI_prefix          ) ,                                   
    .ed_rx_st0_rssai_prefix_parity_i  (ip2uio_rx_st0_RSSAI_prefix_parity   ) ,                                   
    .ed_rx_st0_vfactive_i             (ip2uio_rx_st0_vfactive              ) ,                                   
    .ed_rx_st0_vfnum_i                (ip2uio_rx_st0_vfnum                 ) ,                                   
    .ed_rx_st0_chnum_i                (ip2uio_rx_st0_chnum                 ) ,                                   
    .ed_rx_st0_misc_parity_i          (ip2uio_rx_st0_misc_parity           ) ,                                   
    .ed_rx_st1_data_parity_i          (ip2uio_rx_st1_data_parity           ) ,                                   
    .ed_rx_st1_hdr_parity_i           (ip2uio_rx_st1_hdr_parity            ) ,                                   
    .ed_rx_st1_tlp_prfx_parity_i      (ip2uio_rx_st1_prefix_parity       ) ,                                   
    .ed_rx_st1_rssai_prefix_i         (ip2uio_rx_st1_RSSAI_prefix          ) ,                                   
    .ed_rx_st1_rssai_prefix_parity_i  (ip2uio_rx_st1_RSSAI_prefix_parity   ) ,                                   
    .ed_rx_st1_vfactive_i             (ip2uio_rx_st1_vfactive              ) ,                                   
    .ed_rx_st1_vfnum_i                (ip2uio_rx_st1_vfnum                 ) ,                                   
    .ed_rx_st1_chnum_i                (ip2uio_rx_st1_chnum                 ) ,                                   
    .ed_rx_st1_misc_parity_i          (ip2uio_rx_st1_misc_parity           ) ,                                   
    .ed_rx_st2_data_parity_i           (ip2uio_rx_st2_data_parity          ) ,                                
    .ed_rx_st2_hdr_parity_i            (ip2uio_rx_st2_hdr_parity           ) ,                                
    .ed_rx_st2_tlp_prfx_parity_i       (ip2uio_rx_st2_prefix_parity      ) ,                                
    .ed_rx_st2_rssai_prefix_i          (ip2uio_rx_st2_RSSAI_prefix         ) ,                                
    .ed_rx_st2_rssai_prefix_parity_i   (ip2uio_rx_st2_RSSAI_prefix_parity  ) ,                                
    .ed_rx_st2_vfactive_i              (ip2uio_rx_st2_vfactive             ) ,                                
    .ed_rx_st2_vfnum_i                 (ip2uio_rx_st2_vfnum                ) ,                                
    .ed_rx_st2_chnum_i                 (ip2uio_rx_st2_chnum                ) ,                                
    .ed_rx_st2_misc_parity_i           (ip2uio_rx_st2_misc_parity          ) ,                                
    .ed_rx_st3_data_parity_i           (ip2uio_rx_st3_data_parity          ) ,                                
    .ed_rx_st3_hdr_parity_i            (ip2uio_rx_st3_hdr_parity           ) ,                                
    .ed_rx_st3_tlp_prfx_parity_i       (ip2uio_rx_st3_prefix_parity      ) ,                                
    .ed_rx_st3_rssai_prefix_i          (ip2uio_rx_st3_RSSAI_prefix         ) ,                                
    .ed_rx_st3_rssai_prefix_parity_i   (ip2uio_rx_st3_RSSAI_prefix_parity  ) ,                                
    .ed_rx_st3_vfactive_i              (ip2uio_rx_st3_vfactive             ) ,                                
    .ed_rx_st3_vfnum_i                 (ip2uio_rx_st3_vfnum                ) ,                                
    .ed_rx_st3_chnum_i                 (ip2uio_rx_st3_chnum                ) ,                                
    .ed_rx_st3_misc_parity_i           (ip2uio_rx_st3_misc_parity          ) ,                                
    .ed_rx_bus_number                  (ip2uio_bus_number                   ) ,
    .ed_rx_device_number               (ip2uio_device_number                ) ,
    .ed_rx_function_number             ('d0)                               ,
    
    .ed_rx_st_ready_o                  (usr_rx_st_ready                  ) ,                             
    .ed_clk                            (usr_clk                          ) ,                             
    .ed_rst_n                          (usr_rst_n                        ) ,                             
    .ed_tx_st0_eop_o                   (uio2ip_tx_st0_eop                  ) ,                             
    .ed_tx_st1_eop_o                   (uio2ip_tx_st1_eop                  ) ,                             
    .ed_tx_st2_eop_o                   (uio2ip_tx_st2_eop                  ) ,                             
    .ed_tx_st3_eop_o                   (uio2ip_tx_st3_eop                  ) ,                             
    .ed_tx_st0_header_o                (uio2ip_tx_st0_hdr               ) ,                             
    .ed_tx_st1_header_o                (uio2ip_tx_st1_hdr               ) ,                             
    .ed_tx_st2_header_o                (uio2ip_tx_st2_hdr               ) ,                             
    .ed_tx_st3_header_o                (uio2ip_tx_st3_hdr               ) ,                             
    .ed_tx_st0_prefix_o                (uio2ip_tx_st0_prefix               ) ,                             
    .ed_tx_st1_prefix_o                (uio2ip_tx_st1_prefix               ) ,                             
    .ed_tx_st2_prefix_o                (uio2ip_tx_st2_prefix               ) ,                             
    .ed_tx_st3_prefix_o                (uio2ip_tx_st3_prefix               ) ,                             
    .ed_tx_st0_payload_o               (uio2ip_tx_st0_data                 ) ,                             
    .ed_tx_st1_payload_o               (uio2ip_tx_st1_data                 ) ,                             
    .ed_tx_st2_payload_o               (uio2ip_tx_st2_data                 ) ,                             
    .ed_tx_st3_payload_o               (uio2ip_tx_st3_data                 ) ,                             
    .ed_tx_st0_sop_o                   (uio2ip_tx_st0_sop                  ) ,                             
    .ed_tx_st1_sop_o                   (uio2ip_tx_st1_sop                  ) ,                             
    .ed_tx_st2_sop_o                   (uio2ip_tx_st2_sop                  ) ,                             
    .ed_tx_st3_sop_o                   (uio2ip_tx_st3_sop                  ) ,                             
    .ed_tx_st0_dvalid_o                (uio2ip_tx_st0_dvalid               ) ,                             
    .ed_tx_st1_dvalid_o                (uio2ip_tx_st1_dvalid               ) ,                             
    .ed_tx_st2_dvalid_o                (uio2ip_tx_st2_dvalid               ) ,                             
    .ed_tx_st3_dvalid_o                (uio2ip_tx_st3_dvalid               ) ,                             
    .ed_tx_st0_pvalid_o                (uio2ip_tx_st0_pvalid               ) ,                             
    .ed_tx_st1_pvalid_o                (uio2ip_tx_st1_pvalid               ) ,                             
    .ed_tx_st2_pvalid_o                (uio2ip_tx_st2_pvalid               ) ,                             
    .ed_tx_st3_pvalid_o                (uio2ip_tx_st3_pvalid               ) ,                             
    .ed_tx_st0_hvalid_o                (uio2ip_tx_st0_hvalid               ) ,                             
    .ed_tx_st1_hvalid_o                (uio2ip_tx_st1_hvalid               ) ,                             
    .ed_tx_st2_hvalid_o                (uio2ip_tx_st2_hvalid               ) ,                             
    .ed_tx_st3_hvalid_o                (uio2ip_tx_st3_hvalid               ) ,                             
    .ed_tx_st0_data_parity             (uio2ip_tx_st0_data_parity          ) ,                               
    .ed_tx_st0_hdr_parity              (uio2ip_tx_st0_hdr_parity           ) ,                               
    .ed_tx_st0_prefix_parity           (uio2ip_tx_st0_prefix_parity        ) ,                               
    .ed_tx_st0_RSSAI_prefix            (uio2ip_tx_st0_RSSAI_prefix         ) ,                               
    .ed_tx_st0_RSSAI_prefix_parity     (uio2ip_tx_st0_RSSAI_prefix_parity  ) ,                               
    .ed_tx_st0_vfactive                (uio2ip_tx_st0_vfactive             ) ,                               
    .ed_tx_st0_vfnum                   (uio2ip_tx_st0_vfnum                ) ,                               
    .ed_tx_st0_pfnum                   (uio2ip_tx_st0_pfnum                ) ,                               
    .ed_tx_st0_chnum                   (uio2ip_tx_st0_chnum                ) ,                               
    .ed_tx_st0_empty                   (uio2ip_tx_st0_empty                ) ,                               
    .ed_tx_st0_misc_parity             (uio2ip_tx_st0_misc_parity          ) ,                               
    .ed_tx_st1_data_parity             (uio2ip_tx_st1_data_parity          ) ,                               
    .ed_tx_st1_hdr_parity              (uio2ip_tx_st1_hdr_parity           ) ,                               
    .ed_tx_st1_prefix_parity           (uio2ip_tx_st1_prefix_parity        ) ,                               
    .ed_tx_st1_RSSAI_prefix            (uio2ip_tx_st1_RSSAI_prefix         ) ,                               
    .ed_tx_st1_RSSAI_prefix_parity     (uio2ip_tx_st1_RSSAI_prefix_parity  ) ,                               
    .ed_tx_st1_vfactive                (uio2ip_tx_st1_vfactive             ) ,                               
    .ed_tx_st1_vfnum                   (uio2ip_tx_st1_vfnum                ) ,                               
    .ed_tx_st1_pfnum                   (uio2ip_tx_st1_pfnum                ) ,                               
    .ed_tx_st1_chnum                   (uio2ip_tx_st1_chnum                ) ,                               
    .ed_tx_st1_empty                   (uio2ip_tx_st1_empty                ) ,                               
    .ed_tx_st1_misc_parity             (uio2ip_tx_st1_misc_parity          ) ,                               
    .ed_tx_st2_data_parity             (uio2ip_tx_st2_data_parity          ) ,                               
    .ed_tx_st2_hdr_parity              (uio2ip_tx_st2_hdr_parity           ) ,                               
    .ed_tx_st2_prefix_parity           (uio2ip_tx_st2_prefix_parity        ) ,                               
    .ed_tx_st2_RSSAI_prefix            (uio2ip_tx_st2_RSSAI_prefix         ) ,                               
    .ed_tx_st2_RSSAI_prefix_parity     (uio2ip_tx_st2_RSSAI_prefix_parity  ) ,                               
    .ed_tx_st2_vfactive                (uio2ip_tx_st2_vfactive             ) ,                               
    .ed_tx_st2_vfnum                   (uio2ip_tx_st2_vfnum                ) ,                               
    .ed_tx_st2_pfnum                   (uio2ip_tx_st2_pfnum                ) ,                               
    .ed_tx_st2_chnum                   (uio2ip_tx_st2_chnum                ) ,                               
    .ed_tx_st2_empty                   (uio2ip_tx_st2_empty                ) ,                               
    .ed_tx_st2_misc_parity             (uio2ip_tx_st2_misc_parity          ) ,                               
    .ed_tx_st3_data_parity             (uio2ip_tx_st3_data_parity          ) ,                               
    .ed_tx_st3_hdr_parity              (uio2ip_tx_st3_hdr_parity           ) ,                               
    .ed_tx_st3_prefix_parity           (uio2ip_tx_st3_prefix_parity        ) ,                               
    .ed_tx_st3_RSSAI_prefix            (uio2ip_tx_st3_RSSAI_prefix         ) ,                               
    .ed_tx_st3_RSSAI_prefix_parity     (uio2ip_tx_st3_RSSAI_prefix_parity  ) ,                               
    .ed_tx_st3_vfactive                (uio2ip_tx_st3_vfactive             ) ,                               
    .ed_tx_st3_vfnum                   (uio2ip_tx_st3_vfnum                ) ,                               
    .ed_tx_st3_pfnum                   (uio2ip_tx_st3_pfnum                ) ,                               
    .ed_tx_st3_chnum                   (uio2ip_tx_st3_chnum                ) ,                               
    .ed_tx_st3_empty                   (uio2ip_tx_st3_empty                ) ,                               
    .ed_tx_st3_misc_parity             (uio2ip_tx_st3_misc_parity          ) ,                               
    .ed_tx_st_ready_i                  (ip2uio_tx_ready                  ) ,                             
   
    .rx_st_hcrdt_update_o              (uio2ip_rx_st_Hcrdt_update           ) ,                               
    .rx_st_hcrdt_update_cnt_o          (uio2ip_rx_st_Hcrdt_update_cnt       ) ,                               
    .rx_st_hcrdt_init_o                (uio2ip_rx_st_Hcrdt_init             ) ,                               
    .rx_st_hcrdt_init_ack_i            (ip2uio_rx_st_Hcrdt_init_ack         ) ,                               
    .rx_st_dcrdt_update_o              (uio2ip_rx_st_Dcrdt_update           ) ,                               
    .rx_st_dcrdt_update_cnt_o          (uio2ip_rx_st_Dcrdt_update_cnt       ) ,                               
    .rx_st_dcrdt_init_o                (uio2ip_rx_st_Dcrdt_init             ) ,                               
    .rx_st_dcrdt_init_ack_i            (ip2uio_rx_st_Dcrdt_init_ack         ) ,                               
   
    .tx_st_hcrdt_update_i              (ip2uio_tx_st_Hcrdt_update           ) ,                               
    .tx_st_hcrdt_update_cnt_i          (ip2uio_tx_st_Hcrdt_update_cnt       ) ,                               
    .tx_st_hcrdt_init_i                (ip2uio_tx_st_Hcrdt_init             ) ,                               
    .tx_st_hcrdt_init_ack_o            (uio2ip_tx_st_Hcrdt_init_ack         ) ,                               
    .tx_st_dcrdt_update_i              (ip2uio_tx_st_Dcrdt_update           ) ,                               
    .tx_st_dcrdt_update_cnt_i          (ip2uio_tx_st_Dcrdt_update_cnt       ) ,                               
    .tx_st_dcrdt_init_i                (ip2uio_tx_st_Dcrdt_init             ) ,                               
    .tx_st_dcrdt_init_ack_o            (uio2ip_tx_st_Dcrdt_init_ack         ) ,                               
   
    .ed_tx_st0_passthrough_o           (uio2ip_tx_st0_passthrough          ) ,                               
    .ed_tx_st1_passthrough_o           (uio2ip_tx_st1_passthrough          ) ,                               
    .ed_tx_st2_passthrough_o           (uio2ip_tx_st2_passthrough          ) ,                               
    .ed_tx_st3_passthrough_o           (uio2ip_tx_st3_passthrough          ) ,                               
    .ed_rx_st0_passthrough_i           (ip2uio_rx_st0_passthrough          ) ,                               
    .ed_rx_st1_passthrough_i           (ip2uio_rx_st1_passthrough          ) ,                               
    .ed_rx_st2_passthrough_i           (ip2uio_rx_st2_passthrough          ) ,                               
    .ed_rx_st3_passthrough_i           (ip2uio_rx_st3_passthrough          ) ,                               


  //mc_top 
    // DDRMC <--> BBS Slice
      .hdm_size_256mb                   (hdm_size_256mb  ) ,    	 
      .mc2ip_memsize                    (mc2ip_memsize   ) ,      
 
`ifndef ENABLE_4_BBS_SLICE   // MC_CHANNEL=2

    //Channel-->0	  
      .mc2ip_0_sr_status                 (mc2ip_0_sr_status                 ) ,
      .ip2hdm_avmm0_read                 (ip2hdm_avmm0_read                 ) ,
      .ip2hdm_avmm0_write                (ip2hdm_avmm0_write                ) ,
      .ip2hdm_avmm0_write_poison         (ip2hdm_avmm0_write_poison         ) ,
      .ip2hdm_avmm0_write_ras_sbe        (ip2hdm_avmm0_write_ras_sbe        ) ,
      .ip2hdm_avmm0_write_ras_dbe        (ip2hdm_avmm0_write_ras_dbe        ) ,
      .ip2hdm_avmm0_address              (ip2hdm_avmm0_address              ) ,
      .ip2hdm_avmm0_req_mdata            (ip2hdm_avmm0_req_mdata            ) ,
      .ip2hdm_avmm0_writedata            (ip2hdm_avmm0_writedata            ) ,
      .ip2hdm_avmm0_byteenable           (ip2hdm_avmm0_byteenable           ) ,
      .hdm2ip_avmm0_ready                (hdm2ip_avmm0_ready                ) ,
      .hdm2ip_avmm0_readdata             (hdm2ip_avmm0_readdata             ) ,
      .hdm2ip_avmm0_rsp_mdata            (hdm2ip_avmm0_rsp_mdata            ) ,
      .hdm2ip_avmm0_cxlmem_ready         (hdm2ip_avmm0_cxlmem_ready         ) ,
      .hdm2ip_avmm0_read_poison          (hdm2ip_avmm0_read_poison          ) ,
      .hdm2ip_avmm0_readdatavalid        (hdm2ip_avmm0_readdatavalid        ) ,
      .hdm2ip_avmm0_ecc_err_corrected    (hdm2ip_avmm0_ecc_err_corrected    ) ,
      .hdm2ip_avmm0_ecc_err_detected     (hdm2ip_avmm0_ecc_err_detected     ) ,
      .hdm2ip_avmm0_ecc_err_fatal        (hdm2ip_avmm0_ecc_err_fatal        ) ,
      .hdm2ip_avmm0_ecc_err_syn_e        (hdm2ip_avmm0_ecc_err_syn_e        ) ,
      .hdm2ip_avmm0_ecc_err_valid        (hdm2ip_avmm0_ecc_err_valid        ) ,
      .mc2ip_0_rspfifo_full              (mc2ip_0_rspfifo_full              ) ,
      .mc2ip_0_rspfifo_empty             (mc2ip_0_rspfifo_empty             ) ,
      .mc2ip_0_rspfifo_fill_level        (mc2ip_0_rspfifo_fill_level        ) ,
      .mc2ip_0_reqfifo_full              (mc2ip_0_reqfifo_full              ) ,
      .mc2ip_0_reqfifo_empty             (mc2ip_0_reqfifo_empty             ) ,
      .mc2ip_0_reqfifo_fill_level        (mc2ip_0_reqfifo_fill_level        ) ,
	  
    //Channel-->1	  
      .mc2ip_1_sr_status                 (mc2ip_1_sr_status                 ) ,
      .ip2hdm_avmm1_read                 (ip2hdm_avmm1_read                 ) ,
      .ip2hdm_avmm1_write                (ip2hdm_avmm1_write                ) ,
      .ip2hdm_avmm1_write_poison         (ip2hdm_avmm1_write_poison         ) ,
      .ip2hdm_avmm1_write_ras_sbe        (ip2hdm_avmm1_write_ras_sbe        ) ,
      .ip2hdm_avmm1_write_ras_dbe        (ip2hdm_avmm1_write_ras_dbe        ) ,
      .ip2hdm_avmm1_address              (ip2hdm_avmm1_address              ) ,
      .ip2hdm_avmm1_req_mdata            (ip2hdm_avmm1_req_mdata            ) ,
      .ip2hdm_avmm1_writedata            (ip2hdm_avmm1_writedata            ) ,
      .ip2hdm_avmm1_byteenable           (ip2hdm_avmm1_byteenable           ) ,
      .hdm2ip_avmm1_ready                (hdm2ip_avmm1_ready                ) ,
      .hdm2ip_avmm1_readdata             (hdm2ip_avmm1_readdata             ) ,
      .hdm2ip_avmm1_rsp_mdata            (hdm2ip_avmm1_rsp_mdata            ) ,
      .hdm2ip_avmm1_cxlmem_ready         (hdm2ip_avmm1_cxlmem_ready         ) ,
      .hdm2ip_avmm1_read_poison          (hdm2ip_avmm1_read_poison          ) ,
      .hdm2ip_avmm1_readdatavalid        (hdm2ip_avmm1_readdatavalid        ) ,
      .hdm2ip_avmm1_ecc_err_corrected    (hdm2ip_avmm1_ecc_err_corrected    ) ,
      .hdm2ip_avmm1_ecc_err_detected     (hdm2ip_avmm1_ecc_err_detected     ) ,
      .hdm2ip_avmm1_ecc_err_fatal        (hdm2ip_avmm1_ecc_err_fatal        ) ,
      .hdm2ip_avmm1_ecc_err_syn_e        (hdm2ip_avmm1_ecc_err_syn_e        ) ,
      .hdm2ip_avmm1_ecc_err_valid        (hdm2ip_avmm1_ecc_err_valid        ) ,
      .mc2ip_1_rspfifo_full              (mc2ip_1_rspfifo_full              ) ,
      .mc2ip_1_rspfifo_empty             (mc2ip_1_rspfifo_empty             ) ,
      .mc2ip_1_rspfifo_fill_level        (mc2ip_1_rspfifo_fill_level        ) ,
      .mc2ip_1_reqfifo_full              (mc2ip_1_reqfifo_full              ) ,
      .mc2ip_1_reqfifo_empty             (mc2ip_1_reqfifo_empty             ) ,
      .mc2ip_1_reqfifo_fill_level	     (mc2ip_1_reqfifo_fill_level	    ) ,

`else

    // DDRMC <--> BBS Slice
	  
    //Channel-->0	  
      .mc2ip_0_sr_status                 (mc2ip_0_sr_status                 ) ,
      .ip2hdm_avmm0_read                 (ip2hdm_avmm0_read                 ) ,
      .ip2hdm_avmm0_write                (ip2hdm_avmm0_write                ) ,
      .ip2hdm_avmm0_write_poison         (ip2hdm_avmm0_write_poison         ) ,
      .ip2hdm_avmm0_write_ras_sbe        (ip2hdm_avmm0_write_ras_sbe        ) ,
      .ip2hdm_avmm0_write_ras_dbe        (ip2hdm_avmm0_write_ras_dbe        ) ,
      .ip2hdm_avmm0_address              (ip2hdm_avmm0_address              ) ,
      .ip2hdm_avmm0_req_mdata            (ip2hdm_avmm0_req_mdata            ) ,
      .ip2hdm_avmm0_writedata            (ip2hdm_avmm0_writedata            ) ,
      .ip2hdm_avmm0_byteenable           (ip2hdm_avmm0_byteenable           ) ,
      .hdm2ip_avmm0_ready                (hdm2ip_avmm0_ready                ) ,
      .hdm2ip_avmm0_readdata             (hdm2ip_avmm0_readdata             ) ,
      .hdm2ip_avmm0_rsp_mdata            (hdm2ip_avmm0_rsp_mdata            ) ,
      .hdm2ip_avmm0_cxlmem_ready         (hdm2ip_avmm0_cxlmem_ready         ) ,
      .hdm2ip_avmm0_read_poison          (hdm2ip_avmm0_read_poison          ) ,
      .hdm2ip_avmm0_readdatavalid        (hdm2ip_avmm0_readdatavalid        ) ,
      .hdm2ip_avmm0_ecc_err_corrected    (hdm2ip_avmm0_ecc_err_corrected    ) ,
      .hdm2ip_avmm0_ecc_err_detected     (hdm2ip_avmm0_ecc_err_detected     ) ,
      .hdm2ip_avmm0_ecc_err_fatal        (hdm2ip_avmm0_ecc_err_fatal        ) ,
      .hdm2ip_avmm0_ecc_err_syn_e        (hdm2ip_avmm0_ecc_err_syn_e        ) ,
      .hdm2ip_avmm0_ecc_err_valid        (hdm2ip_avmm0_ecc_err_valid        ) ,
      .mc2ip_0_rspfifo_full              (mc2ip_0_rspfifo_full              ) ,
      .mc2ip_0_rspfifo_empty             (mc2ip_0_rspfifo_empty             ) ,
      .mc2ip_0_rspfifo_fill_level        (mc2ip_0_rspfifo_fill_level        ) ,
      .mc2ip_0_reqfifo_full              (mc2ip_0_reqfifo_full              ) ,
      .mc2ip_0_reqfifo_empty             (mc2ip_0_reqfifo_empty             ) ,
      .mc2ip_0_reqfifo_fill_level        (mc2ip_0_reqfifo_fill_level        ) ,
	  
    //Channel-->1	  
      .mc2ip_1_sr_status                 (mc2ip_1_sr_status                 ) ,
      .ip2hdm_avmm1_read                 (ip2hdm_avmm1_read                 ) ,
      .ip2hdm_avmm1_write                (ip2hdm_avmm1_write                ) ,
      .ip2hdm_avmm1_write_poison         (ip2hdm_avmm1_write_poison         ) ,
      .ip2hdm_avmm1_write_ras_sbe        (ip2hdm_avmm1_write_ras_sbe        ) ,
      .ip2hdm_avmm1_write_ras_dbe        (ip2hdm_avmm1_write_ras_dbe        ) ,
      .ip2hdm_avmm1_address              (ip2hdm_avmm1_address              ) ,
      .ip2hdm_avmm1_req_mdata            (ip2hdm_avmm1_req_mdata            ) ,
      .ip2hdm_avmm1_writedata            (ip2hdm_avmm1_writedata            ) ,
      .ip2hdm_avmm1_byteenable           (ip2hdm_avmm1_byteenable           ) ,
      .hdm2ip_avmm1_ready                (hdm2ip_avmm1_ready                ) ,
      .hdm2ip_avmm1_readdata             (hdm2ip_avmm1_readdata             ) ,
      .hdm2ip_avmm1_rsp_mdata            (hdm2ip_avmm1_rsp_mdata            ) ,
      .hdm2ip_avmm1_cxlmem_ready         (hdm2ip_avmm1_cxlmem_ready         ) ,
      .hdm2ip_avmm1_read_poison          (hdm2ip_avmm1_read_poison          ) ,
      .hdm2ip_avmm1_readdatavalid        (hdm2ip_avmm1_readdatavalid        ) ,
      .hdm2ip_avmm1_ecc_err_corrected    (hdm2ip_avmm1_ecc_err_corrected    ) ,
      .hdm2ip_avmm1_ecc_err_detected     (hdm2ip_avmm1_ecc_err_detected     ) ,
      .hdm2ip_avmm1_ecc_err_fatal        (hdm2ip_avmm1_ecc_err_fatal        ) ,
      .hdm2ip_avmm1_ecc_err_syn_e        (hdm2ip_avmm1_ecc_err_syn_e        ) ,
      .hdm2ip_avmm1_ecc_err_valid        (hdm2ip_avmm1_ecc_err_valid        ) ,
      .mc2ip_1_rspfifo_full              (mc2ip_1_rspfifo_full              ) ,
      .mc2ip_1_rspfifo_empty             (mc2ip_1_rspfifo_empty             ) ,
      .mc2ip_1_rspfifo_fill_level        (mc2ip_1_rspfifo_fill_level        ) ,
      .mc2ip_1_reqfifo_full              (mc2ip_1_reqfifo_full              ) ,
      .mc2ip_1_reqfifo_empty             (mc2ip_1_reqfifo_empty             ) ,
      .mc2ip_1_reqfifo_fill_level	     (mc2ip_1_reqfifo_fill_level	    ) ,
	  
 

 //Channel-->2	  
      .mc2ip_2_sr_status                 (mc2ip_2_sr_status                 ) ,
      .ip2hdm_avmm2_read                 (ip2hdm_avmm2_read                 ) ,
      .ip2hdm_avmm2_write                (ip2hdm_avmm2_write                ) ,
      .ip2hdm_avmm2_write_poison         (ip2hdm_avmm2_write_poison         ) ,
      .ip2hdm_avmm2_write_ras_sbe        (ip2hdm_avmm2_write_ras_sbe        ) ,
      .ip2hdm_avmm2_write_ras_dbe        (ip2hdm_avmm2_write_ras_dbe        ) ,
      .ip2hdm_avmm2_address              (ip2hdm_avmm2_address              ) ,
      .ip2hdm_avmm2_req_mdata            (ip2hdm_avmm2_req_mdata            ) ,
      .ip2hdm_avmm2_writedata            (ip2hdm_avmm2_writedata            ) ,
      .ip2hdm_avmm2_byteenable           (ip2hdm_avmm2_byteenable           ) ,
      .hdm2ip_avmm2_ready                (hdm2ip_avmm2_ready                ) ,
      .hdm2ip_avmm2_readdata             (hdm2ip_avmm2_readdata             ) ,
      .hdm2ip_avmm2_rsp_mdata            (hdm2ip_avmm2_rsp_mdata            ) ,
      .hdm2ip_avmm2_cxlmem_ready         (hdm2ip_avmm2_cxlmem_ready         ) ,
      .hdm2ip_avmm2_read_poison          (hdm2ip_avmm2_read_poison          ) ,
      .hdm2ip_avmm2_readdatavalid        (hdm2ip_avmm2_readdatavalid        ) ,
      .hdm2ip_avmm2_ecc_err_corrected    (hdm2ip_avmm2_ecc_err_corrected    ) ,
      .hdm2ip_avmm2_ecc_err_detected     (hdm2ip_avmm2_ecc_err_detected     ) ,
      .hdm2ip_avmm2_ecc_err_fatal        (hdm2ip_avmm2_ecc_err_fatal        ) ,
      .hdm2ip_avmm2_ecc_err_syn_e        (hdm2ip_avmm2_ecc_err_syn_e        ) ,
      .hdm2ip_avmm2_ecc_err_valid        (hdm2ip_avmm2_ecc_err_valid        ) ,
      .mc2ip_2_rspfifo_full              (mc2ip_2_rspfifo_full              ) ,
      .mc2ip_2_rspfifo_empty             (mc2ip_2_rspfifo_empty             ) ,
      .mc2ip_2_rspfifo_fill_level        (mc2ip_2_rspfifo_fill_level        ) ,
      .mc2ip_2_reqfifo_full              (mc2ip_2_reqfifo_full              ) ,
      .mc2ip_2_reqfifo_empty             (mc2ip_2_reqfifo_empty             ) ,
      .mc2ip_2_reqfifo_fill_level        (mc2ip_2_reqfifo_fill_level        ) ,
	  
    //Channel-->3	  
      .mc2ip_3_sr_status                 (mc2ip_3_sr_status                 ) ,
      .ip2hdm_avmm3_read                 (ip2hdm_avmm3_read                 ) ,
      .ip2hdm_avmm3_write                (ip2hdm_avmm3_write                ) ,
      .ip2hdm_avmm3_write_poison         (ip2hdm_avmm3_write_poison         ) ,
      .ip2hdm_avmm3_write_ras_sbe        (ip2hdm_avmm3_write_ras_sbe        ) ,
      .ip2hdm_avmm3_write_ras_dbe        (ip2hdm_avmm3_write_ras_dbe        ) ,
      .ip2hdm_avmm3_address              (ip2hdm_avmm3_address              ) ,
      .ip2hdm_avmm3_req_mdata            (ip2hdm_avmm3_req_mdata            ) ,
      .ip2hdm_avmm3_writedata            (ip2hdm_avmm3_writedata            ) ,
      .ip2hdm_avmm3_byteenable           (ip2hdm_avmm3_byteenable           ) ,
      .hdm2ip_avmm3_ready                (hdm2ip_avmm3_ready                ) ,
      .hdm2ip_avmm3_readdata             (hdm2ip_avmm3_readdata             ) ,
      .hdm2ip_avmm3_rsp_mdata            (hdm2ip_avmm3_rsp_mdata            ) ,
      .hdm2ip_avmm3_cxlmem_ready         (hdm2ip_avmm3_cxlmem_ready         ) ,
      .hdm2ip_avmm3_read_poison          (hdm2ip_avmm3_read_poison          ) ,
      .hdm2ip_avmm3_readdatavalid        (hdm2ip_avmm3_readdatavalid        ) ,
      .hdm2ip_avmm3_ecc_err_corrected    (hdm2ip_avmm3_ecc_err_corrected    ) ,
      .hdm2ip_avmm3_ecc_err_detected     (hdm2ip_avmm3_ecc_err_detected     ) ,
      .hdm2ip_avmm3_ecc_err_fatal        (hdm2ip_avmm3_ecc_err_fatal        ) ,
      .hdm2ip_avmm3_ecc_err_syn_e        (hdm2ip_avmm3_ecc_err_syn_e        ) ,
      .hdm2ip_avmm3_ecc_err_valid        (hdm2ip_avmm3_ecc_err_valid        ) ,
      .mc2ip_3_rspfifo_full              (mc2ip_3_rspfifo_full              ) ,
      .mc2ip_3_rspfifo_empty             (mc2ip_3_rspfifo_empty             ) ,
      .mc2ip_3_rspfifo_fill_level        (mc2ip_3_rspfifo_fill_level        ) ,
      .mc2ip_3_reqfifo_full              (mc2ip_3_reqfifo_full              ) ,
      .mc2ip_3_reqfifo_empty             (mc2ip_3_reqfifo_empty             ) ,
      .mc2ip_3_reqfifo_fill_level	 (mc2ip_3_reqfifo_fill_level	    ) ,
	  

`endif	


    // == DDR4 Interface ==
    .mem_refclk,                                                          // input,  EMIF PLL reference clock
    .mem_ck,                                                              // output, DDR4 interface signals
    .mem_ck_n,                                                            // output
    .mem_a,                                                               // output
    .mem_act_n,                                                           // output
    .mem_ba,                                                              // output
    .mem_bg,                                                              // output
    .mem_cke,                                                             // output
    .mem_cs_n,                                                            // output
    .mem_odt,                                                             // output
    .mem_reset_n,                                                         // output
    .mem_par,                                                             // output
    .mem_oct_rzqin,                                                       // input
    .mem_alert_n,                                                         // input
    .mem_dqs,                                                             // inout
    .mem_dqs_n,                                                           // inout
    .mem_dq                                                              // inout
    `ifdef ENABLE_DDR_DBI_PINS
    ,.mem_dbi_n                       // inout
    `endif

  );


//<<<

  
endmodule
//------------------------------------------------------------------------------------
//
//
// End cxltyp2_ed.sv
//
//------------------------------------------------------------------------------------
 
