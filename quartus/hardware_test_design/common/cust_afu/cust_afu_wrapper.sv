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


module cust_afu_wrapper
(
      // Clocks
  input logic  axi4_mm_clk, 

    // Resets
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
 // output logic [7:0]                wid,
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
   output logic                     rready,
  /*
    TileLink Cached interface
  */
  input logic                       tl_clk,
  input  logic                      tl_rst_n,
  // TL 请求通道
  input  logic                      tl_req_valid,
  output logic                      tl_req_ready,
  input  logic [63:0]               tl_req_addr,
  input  logic [7:0]                tl_req_len,
  input  logic [1:0]                tl_req_op,      // 00=Read,01=Write
  input  logic [511:0]              tl_req_wdata,
  input  logic [63:0]               tl_req_wstrb,
  // TL 响应通道
  output logic                      tl_resp_valid,
  input  logic                      tl_resp_ready,
  output logic [511:0]              tl_resp_rdata,
  output logic [1:0]                tl_resp_code

  // =============================
  // 3) 实例化真正的 AFU 核心
  // =============================
  // 我们假设已经在同目录下编写了 my_afu.sv，并且它的接口是：
  //   • Avalon‑MM Master: avm_*
  //   • TileLink Slave:    tl_*

   
);

// Tied to Zero for all inputs. USER Can Modify

//assign awready = 1'b0;
//assign wready  = 1'b0;
//assign arready = 1'b0;
//assign bid     = 16'h0;
//assign bresp   = 4'h0;  
//assign buser   = 4'h0;
//assign bvalid  = 1'b0;
//
//assign rid     = 16'h0; 
//assign rdata   = 512'h0;
//assign rresp   = 4'h0;
//assign rlast   = 1'b0;
//assign ruser   = 4'h0;
//assign rvalid  = 1'b0;


  assign  awid         = '0   ;
  assign  awaddr       = '0   ; 
  assign  awlen        = '0   ;
  assign  awsize       = '0   ;
  assign  awburst      = '0   ;
  assign  awprot       = '0   ;
  assign  awqos        = '0   ;
  assign  awuser       = '0   ;
  assign  awvalid      = '0   ;
  assign  awcache      = '0   ;
  assign  awlock       = '0   ;
  assign  awregion     = '0   ;
  assign  wdata        = '0   ;
  assign  wstrb        = '0   ;
  assign  wlast        = '0   ;
  assign  wuser        = '0   ;
  assign  wvalid       = '0   ;
//  assign  wid          = '0   ;
  assign  bready       = '0   ;
  assign  arid         = '0   ;
  assign  araddr       = '0   ;
  assign  arlen        = '0   ;
  assign  arsize       = '0   ;
  assign  arburst      = '0   ;
  assign  arprot       = '0   ;
  assign  arqos        = '0   ;
  assign  aruser       = '0   ;
  assign  arvalid      = '0   ;
  assign  arcache      = '0   ;
  assign  arlock       = '0   ;
  assign  arregion     = '0   ;
  assign  rready       = '0   ;

  // 实例化 Custom AFU 核心
  my_afu u_my_afu (
    // 时钟复位
    .clk             (axi4_mm_clk),
    .rst_n           (axi4_mm_rst_n),

    //——————————————
    // Avalon‑MM Master 接口（对应原来的 AXI‑MM 端口）
    //——————————————
    .avm_awid        (awid      ),  // write address channel
    .avm_awaddr      (awaddr    ),
    .avm_awlen       (awlen     ),
    .avm_awsize      (awsize    ),
    .avm_awburst     (awburst   ),
    .avm_awprot      (awprot    ),
    .avm_awcache     (awcache   ),
    .avm_awuser      (awuser    ),
    .avm_awqos       (awqos     ),
    .avm_awvalid     (awvalid   ),
    .avm_awready     (awready   ),

    .avm_writedata   (wdata     ),  // write data channel
    .avm_byteenable  (wstrb     ),
    .avm_wlast       (wlast     ),
    .avm_wvalid      (wvalid    ),
    .avm_wready      (wready    ),

    .avm_bid         (bid       ),  // write response channel
    .avm_bresp       (bresp     ),
    .avm_bvalid      (bvalid    ),
    .avm_bready      (bready    ),

    .avm_arid        (arid      ),  // read address channel
    .avm_araddr      (araddr    ),
    .avm_arlen       (arlen     ),
    .avm_arsize      (arsize    ),
    .avm_arburst     (arburst   ),
    .avm_arprot      (arprot    ),
    .avm_arcache     (arcache   ),
    .avm_aruser      (aruser    ),
    .avm_arvalid     (arvalid   ),
    .avm_arready     (arready   ),

    .avm_rid         (rid       ),  // read response channel
    .avm_rdata       (rdata     ),
    .avm_rresp       (rresp     ),
    .avm_rlast       (rlast     ),
    .avm_rvalid      (rvalid    ),
    .avm_rready      (rready    ),

    //——————————————
    // TileLink Slave 接口
    //——————————————
    .tl_clk          (tl_clk       ),
    .tl_rst_n        (tl_rst_n     ),
    .tl_req_valid    (tl_req_valid ),
    .tl_req_ready    (tl_req_ready ),
    .tl_req_addr     (tl_req_addr  ),
    .tl_req_len      (tl_req_len   ),
    .tl_req_op       (tl_req_op    ),
    .tl_req_wdata    (tl_req_wdata ),
    .tl_req_wstrb    (tl_req_wstrb ),

    .tl_resp_valid   (tl_resp_valid),
    .tl_resp_ready   (tl_resp_ready),
    .tl_resp_rdata   (tl_resp_rdata),
    .tl_resp_code    (tl_resp_code )
  );
endmodule


