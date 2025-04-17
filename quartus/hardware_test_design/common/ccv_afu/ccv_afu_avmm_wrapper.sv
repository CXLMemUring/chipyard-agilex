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
/*                COHERENCE-COMPLIANCE VALIDATION AFU

  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder

  initial -> 07/12/2022 -> Antony Mathew
*/


module ccv_afu_avmm_wrapper
    import CCV_AFU_GLOBAL_PKG::*;
//    import ccv_afu_package::*;
//    import afu_axi_if_pkg::*;
//    import ccv_afu_cfg_pkg::*;
    import rtlgen_pkg_v12::*;
(
      // Clocks
  input logic  csr_avmm_clk, // AVMM clock : 125MHz
  input logic  rtl_clk, //450 SIP clk
  input logic  axi4_mm_clk, 

    // Resets
  input logic  csr_avmm_rstn,
  input logic  rst_n,
  input logic  axi4_mm_rst_n,

  /*
    AXI-MM interface - write address channel
  */
  output logic [15:0]               awid,
  output logic [51:0]               awaddr, 
  output logic [9:0]                awlen,
  output logic [2:0]                awsize,
  output logic [1:0]                awburst,
  output logic [2:0]                awprot,
  output logic [3:0]                awqos,
  output logic [3:0]                awuser,
  output logic                      awvalid,
  output logic [3:0]                awcache,
  output logic [1:0]                awlock,
  output logic [3:0]                awregion,
   input                            awready,
  
  /*
    AXI-MM interface - write data channel
  */
  output logic [511:0]              wdata,
  output logic [(512/8)-1:0]        wstrb,
  output logic                      wlast,
  output logic [3:0]                wuser,
  output logic                      wvalid,
  output logic [15:0]               wid,
   input                            wready,
  
  /*
    AXI-MM interface - write response channel
  */ 
   input [15:0]                     bid,
   input [3:0]                      bresp,
   input [3:0]                      buser,
   input                            bvalid,
  output logic                      bready,
  
  /*
    AXI-MM interface - read address channel
  */
  output logic [15:0]               arid,
  output logic [51:0]               araddr,
  output logic [9:0]                arlen,
  output logic [2:0]                arsize,
  output logic [1:0]                arburst,
  output logic [2:0]                arprot,
  output logic [3:0]                arqos,
  output logic [3:0]                aruser,
  output logic                      arvalid,
  output logic [3:0]                arcache,
  output logic [1:0]                arlock,
  output logic [3:0]                arregion,
   input                            arready,

  /*
    AXI-MM interface - read response channel
  */ 
   input [15:0]                     rid,
   input [511:0]                    rdata,
   input [3:0]                      rresp,
   input                            rlast,
   input [3:0]                      ruser,
   input                            rvalid,
  output logic                      rready,
  
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
  input logic                   resetprep_en,
  input logic                   bfe_afu_quiesce_req,
  output logic                  afu_bfe_quiesce_ack,


  // SC <--> AVMM-INTERCONNECT

// bios based memory base address
input  logic [31:0] ccv_afu_conf_base_addr_high ,
input  logic        ccv_afu_conf_base_addr_high_valid,
input  logic [27:0] ccv_afu_conf_base_addr_low ,
input  logic        ccv_afu_conf_base_addr_low_valid,

  
  //CSR Access AVMM Bus
 
  output logic        csr_avmm_waitrequest,  
  output logic [63:0] csr_avmm_readdata,
  output logic        csr_avmm_readdatavalid,
  input  logic [63:0] csr_avmm_writedata,
  input  logic [21:0] csr_avmm_address,
  input  logic        csr_avmm_write,
  input  logic        csr_avmm_read, 
  input  logic [7:0]  csr_avmm_byteenable
   
);

cfg_req_64bit_t   treg_req;
cfg_ack_64bit_t   treg_ack;

cfg_req_64bit_t                    treg_req_fifo;   //from FIFO
cfg_ack_64bit_t                    treg_ack_fifo;   //from FIFO



   ccv_afu_csr_avmm_slave ccv_afu_csr_avmm_slave_inst(
       .clk          (csr_avmm_clk),
       .reset_n      (csr_avmm_rstn),
       .writedata    (csr_avmm_writedata),
       .read         (csr_avmm_read),
       .write        (csr_avmm_write),
       .byteenable   (csr_avmm_byteenable),
       .readdata     (csr_avmm_readdata),
       .readdatavalid(csr_avmm_readdatavalid),
       .address      (csr_avmm_address),
       .waitrequest  (csr_avmm_waitrequest),
       .treg_req     (treg_req                ),
       .treg_ack     (treg_ack_fifo           )
   );

//AVMM Interconnect (125Mhz) <-> ccv_afu_csr_avmm_slave (125MHz) <-> Need CDC(125MHz to 450MHz) <-> ccv_afu_wrapper (450MHz)

//Need to implement CDC Bridge 125 to 450MHz


ccv_afu_cdc_fifo ccv_afu_cdc_fifo_inst (

    //Inputs
    .rst(~rst_n),
    .clk(rtl_clk),
    .sbr_clk_i(csr_avmm_clk),
    .sbr_rstb_i(csr_avmm_rstn),
    .treg_np('d0),
    .treg_req,                         // Request from avmm interconnect
    .treg_ack (treg_ack),              // Ack from cfg

    //Outputs
    .treg_req_fifo,                    // Request from FIFO
    .treg_ack_fifo                     // Ack from FIFO
);


ccv_afu_wrapper    inst_ccv_afu_wrapper
(
  /*
    assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
    domain crossing.
  */
      // Clocks
  .gated_clk   ( rtl_clk ),
  .rtl_clk     ( rtl_clk ),
 // .axi4_mm_clk ( axi4_mm_clk ),

    // Resets
  .rst_n         ( rst_n ),
//  .axi4_mm_rst_n ( axi4_mm_rst_n ),

  /*
    AXI-MM interface - write address channel
  */
  .awid         ( awid ),
  .awaddr       ( awaddr ),
  .awlen        ( awlen ),
  .awsize       ( awsize ),
  .awburst      ( awburst ),
  .awprot       ( awprot ),
  .awqos        ( awqos ),
  .awuser       ( awuser ),
  .awvalid      ( awvalid ),
  .awcache      ( awcache ),
  .awlock       ( awlock ),
  .awregion     ( awregion ),
  .awready      ( awready ),
  
  /*
    AXI-MM interface - write data channel
  */
  .wdata        ( wdata ),
  .wstrb        ( wstrb ),
  .wlast        ( wlast ),
  .wuser        ( wuser ),
  .wvalid       ( wvalid ),
 // .wid          ( wid ),
  .wready       ( wready ),
  
  /*
    AXI-MM interface - write response channel
  */ 
  .bid          ( bid ),
  .bresp        ( bresp ),
  .buser        ( buser ),
  .bvalid       ( bvalid ),
  .bready       ( bready ),
  
  /*
    AXI-MM interface - read address channel
  */
  .arid         ( arid ),
  .araddr       ( araddr ),
  .arlen        ( arlen ),
  .arsize       ( arsize ),
  .arburst      ( arburst ),
  .arprot       ( arprot ),
  .arqos        ( arqos ),
  .aruser       ( aruser ),
  .arvalid      ( arvalid ),
  .arcache      ( arcache ),
  .arlock       ( arlock ),
  .arregion     ( arregion ),
  .arready      ( arready ),
  
  /*
    AXI-MM interface - read response channel
  */ 
  .rid          ( rid ),
  .rdata        ( rdata ),
  .rlast        ( rlast ),
  .rresp        ( rresp ),
  .ruser        ( ruser ),
  .rvalid       ( rvalid ),
  .rready       ( rready ),

 .ccv_afu_conf_base_addr_high       ( ccv_afu_conf_base_addr_high       ),
 .ccv_afu_conf_base_addr_high_valid ( ccv_afu_conf_base_addr_high_valid ),
 .ccv_afu_conf_base_addr_low        ( ccv_afu_conf_base_addr_low        ),
 .ccv_afu_conf_base_addr_low_valid  ( ccv_afu_conf_base_addr_low_valid  ),
  
  /*
     to config registers
  */
  .treg_req ( treg_req_fifo ),
  .treg_ack ( treg_ack ),

  // SC <--> Cambria
  // copied over from sc_afu_wrapper
  .afu_cam_ext5 ( afu_cam_ext5 ),
  .afu_cam_ext6 ( afu_cam_ext6 ),
  .cam_afu_ext5 ( cam_afu_ext5 ),
  .cam_afu_ext6 ( cam_afu_ext6 ),

  // BBS <--> AFU quiesce interface
  // copied over from sc_afu_wrapper
  .resetprep_en        ( resetprep_en ),
  .bfe_afu_quiesce_req ( bfe_afu_quiesce_req ),
  .afu_bfe_quiesce_ack ( afu_bfe_quiesce_ack )
);



endmodule


