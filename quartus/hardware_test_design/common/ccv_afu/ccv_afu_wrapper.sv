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
///////////////////////////////////////////////////////////////////////
`include "ccv_afu_globals.vh.iv"

module ccv_afu_wrapper
    import ccv_afu_pkg::*;
    import afu_axi_if_pkg::*;
    import ccv_afu_cfg_pkg::*;
    import rtlgen_pkg_v12::*;
(
  /*
    assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
    domain crossing.
  */
      // Clocks
  input logic  gated_clk,
  input logic  rtl_clk,

    // Resets
  input logic  rst_n,
  
  /*
    AXI-MM interface - write address channel
  */
  output logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]         awaddr, 
  output logic [AFU_AXI_BURST_WIDTH-1:0]            awburst,
  output logic [AFU_AXI_CACHE_WIDTH-1:0]            awcache,
  output logic [AFU_AXI_MAX_ID_WIDTH-1:0]           awid,
  output logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] awlen,
  output logic [AFU_AXI_LOCK_WIDTH-1:0]             awlock,
  output logic [AFU_AXI_QOS_WIDTH-1:0]              awqos,
  output logic [AFU_AXI_PROT_WIDTH-1:0]             awprot,
   input                                            awready,
  output logic [AFU_AXI_REGION_WIDTH-1:0]           awregion,
  output logic [AFU_AXI_SIZE_WIDTH-1:0]             awsize,
  output logic [AFU_AXI_AWUSER_WIDTH-1:0]           awuser,
  output logic                                      awvalid,
  
  /*
    AXI-MM interface - write data channel
  */
  output logic [AFU_AXI_MAX_DATA_WIDTH-1:0]      wdata,
//  output logic [AFU_AXI_MAX_ID_WIDTH-1:0]        wid,
  output logic                                   wlast,
   input                                         wready,
  output logic [(AFU_AXI_MAX_DATA_WIDTH/8)-1:0]  wstrb,
  output logic [AFU_AXI_WUSER_WIDTH-1:0]         wuser,
  output logic                                   wvalid,
  
  /*
    AXI-MM interface - write response channel
  */ 
   input [AFU_AXI_MAX_ID_WIDTH-1:0] bid,
  output logic                      bready,
   input [AFU_AXI_RESP_WIDTH-1:0]   bresp,
   input [AFU_AXI_BUSER_WIDTH-1:0]  buser,
   input                            bvalid,
  
  /*
    AXI-MM interface - read address channel
  */
  output logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]         araddr,
  output logic [AFU_AXI_BURST_WIDTH-1:0]            arburst,
  output logic [AFU_AXI_CACHE_WIDTH-1:0]            arcache,
  output logic [AFU_AXI_MAX_ID_WIDTH-1:0]           arid,
  output logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] arlen,
  output logic [AFU_AXI_LOCK_WIDTH-1:0]             arlock,
  output logic [AFU_AXI_PROT_WIDTH-1:0]             arprot,
  output logic [AFU_AXI_QOS_WIDTH-1:0]              arqos,
   input                                            arready,
  output logic [AFU_AXI_REGION_WIDTH-1:0]           arregion,
  output logic [AFU_AXI_SIZE_WIDTH-1:0]             arsize,
  output logic [AFU_AXI_ARUSER_WIDTH-1:0]           aruser,
  output logic                                      arvalid,

  /*
    AXI-MM interface - read response channel
  */ 
   input [AFU_AXI_MAX_DATA_WIDTH-1:0] rdata,
   input [AFU_AXI_MAX_ID_WIDTH-1:0]   rid,
   input                              rlast,
  output logic                        rready,
   input [AFU_AXI_RESP_WIDTH-1:0]     rresp,
   input [AFU_AXI_RUSER_WIDTH-1:0]    ruser,
   input                              rvalid,

  /* bios based memory base address
  */
  input [31:0] ccv_afu_conf_base_addr_high,
  input        ccv_afu_conf_base_addr_high_valid,
  input [27:0] ccv_afu_conf_base_addr_low,
  input        ccv_afu_conf_base_addr_low_valid,

  /*
   *   register access ports
   */
   input ccv_afu_cfg_cr_req_t   treg_req,
  output ccv_afu_cfg_cr_ack_t   treg_ack,
   
  // SC <--> Cambria
  // copied over from sc_afu_wrapper
  output logic                  afu_cam_ext5,
  output logic                  afu_cam_ext6,

  //input logic [APP_CORES-1:0]   cam_afu_ext5,
  //input logic [APP_CORES-1:0]   cam_afu_ext6,
  input logic [2-1:0]   cam_afu_ext5,
  input logic [2-1:0]   cam_afu_ext6,
  
  // BBS <--> AFU quiesce interface
  // copied over from sc_afu_wrapper
  // if quiesce comes in, stop sending traffic - could be used for cache flush
  input logic                   bfe_afu_quiesce_req,
  output logic                  afu_bfe_quiesce_ack,

  // copied over from sc_afu_wrapper
  input logic                   resetprep_en
);


assign afu_cam_ext5        = 1'b0;
assign afu_cam_ext6        = 1'b0;
assign afu_bfe_quiesce_ack = 1'b0; // bfe_afu_quiesce_req;


/* config registers interface to/from registers to multi-write-algorithm-engine
*/
// intf_ccv_afu_cfg_regs   config_regs_intf();   // collage does not support interfaces

CONFIG_TEST_START_ADDR_t        start_address_reg;
CONFIG_TEST_WR_BACK_ADDR_t      write_back_address_reg;
CONFIG_TEST_ADDR_INCRE_t        increment_reg;
CONFIG_TEST_PATTERN_t           pattern_reg;
CONFIG_TEST_BYTEMASK_t          byte_mask_reg;
CONFIG_TEST_PATTERN_PARAM_t     pattern_config_reg;
CONFIG_ALGO_SETTING_t           algorithm_config_reg;
DEVICE_ERROR_LOG3_t             device_error_log3_reg;
DEVICE_FORCE_DISABLE_t          device_force_disable_reg;
DEVICE_ERROR_INJECTION_t        device_error_injection_reg;

new_DEVICE_ERROR_LOG1_t         error_log_1_reg;
new_DEVICE_ERROR_LOG2_t         error_log_2_reg;
new_DEVICE_ERROR_LOG3_t         error_log_3_reg;
new_DEVICE_ERROR_LOG4_t         error_log_4_reg;
new_DEVICE_ERROR_LOG5_t         error_log_5_reg;
new_DEVICE_AFU_STATUS1_t        device_afu_status_1_reg;
new_DEVICE_AFU_STATUS2_t        device_afu_status_2_reg;
new_CONFIG_CXL_ERRORS_t         config_and_cxl_errors_reg;
new_DEVICE_ERROR_INJECTION_t    new_device_error_injection_reg;

/*  map the axi signals to the interface
*/
t_axi4_wr_addr_ch      axi_aw;
t_axi4_wr_data_ch      axi_w;
t_axi4_wr_resp_ch      axi_b;
t_axi4_rd_addr_ch      axi_ar;
t_axi4_rd_resp_ch      axi_r;
    
t_axi4_wr_addr_ready   axi_awready;
t_axi4_wr_data_ready   axi_wready;    
t_axi4_wr_resp_ready   axi_bready;
t_axi4_rd_addr_ready   axi_arready;
t_axi4_rd_resp_ready   axi_rready;

/* flag from mwae indicating that HW wants to set the error status field of the
   ERROR_LOG3 cfg reg.
   Software will then set this field to zero to clear all error log registers.
*/
logic mwae_to_cfg_enable_new_error_log3_error_status;


always_comb
begin
    awid                    =   axi_aw.awid;
    awaddr                  =   axi_aw.awaddr;
    awlen                   =   axi_aw.awlen;
    awsize                  =   axi_aw.awsize;
    awburst                 =   axi_aw.awburst;
    awprot                  =   axi_aw.awprot;
    awqos                   =   axi_aw.awqos;
    awuser                  =   axi_aw.awuser;
    awvalid                 =   axi_aw.awvalid;
    awcache                 =   axi_aw.awcache;
    awlock                  =   axi_aw.awlock;
    awregion                =   axi_aw.awregion;
    axi_awready             =   awready;
    
    wdata                   =   axi_w.wdata;
    wstrb                   =   axi_w.wstrb;
    wlast                   =   axi_w.wlast;
    wuser                   =   axi_w.wuser;
    wvalid                  =   axi_w.wvalid;
//    wid                     =   axi_w.wid;
    axi_wready              =   wready;
    
    axi_b.bid               =   bid;
    axi_b.bresp             =   t_axi4_resp_encoding'(bresp);
    axi_b.buser             =   buser;   //t_axi4_buser_opcode'(buser);
    axi_b.bvalid            =   bvalid;
    bready                  =   axi_bready;
    
    arid                    =   axi_ar.arid;
    araddr                  =   axi_ar.araddr;
    arlen                   =   axi_ar.arlen;
    arsize                  =   axi_ar.arsize;
    arburst                 =   axi_ar.arburst;
    arprot                  =   axi_ar.arprot;
    arqos                   =   axi_ar.arqos;
    aruser                  =   axi_ar.aruser;
    arvalid                 =   axi_ar.arvalid;
    arcache                 =   axi_ar.arcache;
    arlock                  =   axi_ar.arlock;
    arregion                =   axi_ar.arregion;
    axi_arready             =   arready;
    
    axi_r.rid               =   rid;
    axi_r.rdata             =   rdata;
    axi_r.rresp             =   t_axi4_resp_encoding'(rresp);
    axi_r.rlast             =   rlast;
    axi_r.ruser             =   t_axi4_ruser'(ruser); //t_axi4_ruser_opcode'(ruser);
    axi_r.rvalid            =   rvalid;
    rready                  =   axi_rready;
end

/*
 *   instance of the multi-write-algorithm-engine module
 */
mwae_top       inst_mwae_top
(
    .rtl_clk        ( rtl_clk ),
    .reset_n        ( rst_n ),
    
    /*
       AXI-MM interface - this afu is the initator
    */
    .o_axi_wr_addr_chan ( axi_aw      ),
    .i_axi_awready      ( axi_awready ),

    .o_axi_wr_data_chan ( axi_w      ),
    .i_axi_wready       ( axi_wready ),

    .i_axi_wr_resp_chan ( axi_b      ),
    .o_axi_bready       ( axi_bready ),

    .o_axi_rd_addr_chan ( axi_ar      ),
    .i_axi_arready      ( axi_arready ),

    .i_axi_rd_resp_chan ( axi_r      ),
    .o_axi_rready       ( axi_rready ),

    /*
     * temporary place holds for config registers interface
    */   
    .start_address_reg        ( start_address_reg ),
    .write_back_address_reg   ( write_back_address_reg ),
    .increment_reg            ( increment_reg ),
    .pattern_reg              ( pattern_reg ),
    .bytemask_reg             ( byte_mask_reg ),
    .pattern_config_reg       ( pattern_config_reg ),
    .algorithm_config_reg     ( algorithm_config_reg ),
    .device_error_log3_reg    ( device_error_log3_reg ),
    .device_force_disable_reg ( device_force_disable_reg ),

    .config_and_cxl_errors_reg  ( config_and_cxl_errors_reg  ),
    .device_afu_status_1_reg    ( device_afu_status_1_reg    ),
    .device_afu_status_2_reg    ( device_afu_status_2_reg    ),

    .new_device_error_injection_reg ( new_device_error_injection_reg ), 
    .device_error_injection_reg     ( device_error_injection_reg     ), 

    .error_log_1_reg ( error_log_1_reg ),
    .error_log_2_reg ( error_log_2_reg ),
    .error_log_3_reg ( error_log_3_reg ),
    .error_log_4_reg ( error_log_4_reg ),
    .error_log_5_reg ( error_log_5_reg ),

    .record_error_out ( mwae_to_cfg_enable_new_error_log3_error_status )
);

/*
 *   instance of the config registers 
 */
ccv_afu_cfg     inst_ccv_afu_cfg
( //lintra s-2096
    .gated_clk ( gated_clk ),
    .rtl_clk   ( rtl_clk   ),
    .rst_n     ( rst_n     ),
    .req       ( treg_req  ),
    .ack       ( treg_ack  ),

    .load_CXL_DVSEC_TEST_CNF_BASE_HIGH ( ccv_afu_conf_base_addr_high_valid ),
    .new_CXL_DVSEC_TEST_CNF_BASE_HIGH  ( ccv_afu_conf_base_addr_high       ),
    .load_CXL_DVSEC_TEST_CNF_BASE_LOW  ( ccv_afu_conf_base_addr_low_valid  ),
    .new_CXL_DVSEC_TEST_CNF_BASE_LOW   ( ccv_afu_conf_base_addr_low        ),

  // error_status field in DEVICE_ERROR_LOG3 is RW/0C/V
  // seems to serve as an enable for selecting hardware over software
    .load_DEVICE_ERROR_LOG3 ( mwae_to_cfg_enable_new_error_log3_error_status ),

  // event count field in DEVICE_EVENT_COUNT is RW/V
  // seems to serve as an enable for selecting hardware over software
    .load_DEVICE_EVENT_COUNT ( 1'b0 ),
     .new_DEVICE_EVENT_COUNT ( 64'h0000_0000 ),

  // DEVICE ERROR LOG1, LOG2, LOG3, LOG4, LOG5 are RO/V
    .new_DEVICE_ERROR_LOG1  ( error_log_1_reg  ),
    .new_DEVICE_ERROR_LOG2  ( error_log_2_reg  ),
    .new_DEVICE_ERROR_LOG3  ( error_log_3_reg  ),
    .new_DEVICE_ERROR_LOG4  ( error_log_4_reg  ),
    .new_DEVICE_ERROR_LOG5  ( error_log_5_reg  ),

    .new_DEVICE_ERROR_INJECTION ( new_device_error_injection_reg ),
    .DEVICE_ERROR_INJECTION     ( device_error_injection_reg     ),

    .new_CONFIG_CXL_ERRORS  ( config_and_cxl_errors_reg ),
    .new_DEVICE_AFU_STATUS1 ( device_afu_status_1_reg   ),
    .new_DEVICE_AFU_STATUS2 ( device_afu_status_2_reg   ),

    .CXL_DVSEC_TEST_CAP2_cache_size_device ( 14'h0147  ),
    .CXL_DVSEC_TEST_CAP2_cache_size_unit   ( 2'b01     ),

    .new_CONFIG_DEVICE_INJECTION ( 2'd0 ),
    .CONFIG_DEVICE_INJECTION     ( ),

    .CONFIG_ALGO_SETTING        ( algorithm_config_reg   ),
    .CONFIG_TEST_ADDR_INCRE     ( increment_reg          ),
    .CONFIG_TEST_BYTEMASK       ( byte_mask_reg          ),
    .CONFIG_TEST_PATTERN        ( pattern_reg            ),
    .CONFIG_TEST_PATTERN_PARAM  ( pattern_config_reg     ),
    .CONFIG_TEST_START_ADDR     ( start_address_reg      ),
    .CONFIG_TEST_WR_BACK_ADDR   ( write_back_address_reg ),

    .DEVICE_ERROR_LOG1 (),
    .DEVICE_ERROR_LOG2 (),
    .DEVICE_ERROR_LOG3 ( device_error_log3_reg ),
    .DEVICE_ERROR_LOG4 (),
    .DEVICE_ERROR_LOG5 (),

    .CONFIG_CXL_ERRORS    (),
    .DEVICE_AFU_STATUS1   (),
    .DEVICE_AFU_STATUS2   (),
    .DEVICE_FORCE_DISABLE ( device_force_disable_reg ),

    .DEVICE_EVENT_COUNT (),
    .DEVICE_EVENT_CTRL  (),
    .CXL_DVSEC_HEADER_1 (),
    .CXL_DVSEC_HEADER_2 (),
        .DVSEC_TEST_CAP  (),
    .CXL_DVSEC_TEST_CAP1 (),
    .CXL_DVSEC_TEST_CAP2 (),
    .CXL_DVSEC_TEST_CNF_BASE_HIGH (),
    .CXL_DVSEC_TEST_CNF_BASE_LOW  (),
    .CXL_DVSEC_TEST_LOCK ()
);













endmodule

