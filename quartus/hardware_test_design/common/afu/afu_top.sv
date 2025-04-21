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

import cxlip_top_pkg::*;

module afu_top(
    //input  logic        csr_avmm_clk,
    //input  logic        csr_avmm_rstn,  
    //output logic        csr_avmm_waitrequest,            
    //output logic [31:0] csr_avmm_readdata,               
    //output logic        csr_avmm_readdatavalid,          
    //input  logic [31:0] csr_avmm_writedata,              
    //input  logic [21:0] csr_avmm_address,                
    //input  logic        csr_avmm_write,                  
    //input  logic        csr_avmm_read,                   
    //input  logic [3:0]  csr_avmm_byteenable,
    
    input  logic                                             afu_clk,
    input  logic                                             afu_rstn,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ready_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_read_poison_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_readdatavalid_eclk,
    // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ecc_err_valid_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_cxlmem_ready,
    input  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    mc2iafu_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         mc2iafu_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    
    
    output logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2mc_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      iafu2mc_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_read_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_poison_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_sbe_eclk,    
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_dbe_eclk,    
    output logic [cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]    iafu2mc_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2mc_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],

                //CXL_IP to AFU to MC TOP Passthrough signals
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ready_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_read_poison_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_readdatavalid_eclk,
    // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ecc_err_valid_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_cxlmem_ready,
    output  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2cxlip_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2cxlip_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    
    input logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]      cxlip2iafu_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]        cxlip2iafu_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_read_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_poison_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_sbe_eclk,    
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_dbe_eclk,    
    input logic [cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]      cxlip2iafu_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]           cxlip2iafu_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0]
    
    
);


//CSR block
/*
   afu_csr_avmm_slave afu_csr_avmm_slave_inst(
       .clk          (csr_avmm_clk),
       .reset_n      (csr_avmm_rstn),
       .writedata    (csr_avmm_writedata),
       .read         (csr_avmm_read),
       .write        (csr_avmm_write),
       .byteenable   (csr_avmm_byteenable),
       .readdata     (csr_avmm_readdata),
       .readdatavalid(csr_avmm_readdatavalid),
       .address      (csr_avmm_address),
       .waitrequest  (csr_avmm_waitrequest)
   );
*/

//Passthrough User can implement the AFU logic here 

//assign iafu2cxlip_ready_eclk                = mc2iafu_ready_eclk             ;
//assign iafu2cxlip_read_poison_eclk          = mc2iafu_read_poison_eclk       ;
//assign iafu2cxlip_readdatavalid_eclk        = mc2iafu_readdatavalid_eclk     ;
//assign iafu2cxlip_ecc_err_corrected_eclk    = mc2iafu_ecc_err_corrected_eclk ;
//assign iafu2cxlip_ecc_err_detected_eclk     = mc2iafu_ecc_err_detected_eclk  ;
//assign iafu2cxlip_ecc_err_fatal_eclk        = mc2iafu_ecc_err_fatal_eclk     ;
//assign iafu2cxlip_ecc_err_syn_e_eclk        = mc2iafu_ecc_err_syn_e_eclk     ;
//assign iafu2cxlip_ecc_err_valid_eclk        = mc2iafu_ecc_err_valid_eclk     ;
//assign iafu2cxlip_cxlmem_ready              = mc2iafu_cxlmem_ready           ;
//assign iafu2cxlip_readdata_eclk             = mc2iafu_readdata_eclk          ;
//assign iafu2cxlip_rsp_mdata_eclk            = mc2iafu_rsp_mdata_eclk         ;
//
//
//assign iafu2mc_writedata_eclk               = cxlip2iafu_writedata_eclk     ;
//assign iafu2mc_byteenable_eclk              = cxlip2iafu_byteenable_eclk    ;
//assign iafu2mc_read_eclk                    = cxlip2iafu_read_eclk          ;
//assign iafu2mc_write_eclk                   = cxlip2iafu_write_eclk         ;
//assign iafu2mc_write_poison_eclk            = cxlip2iafu_write_poison_eclk  ;
//assign iafu2mc_write_ras_sbe_eclk           = cxlip2iafu_write_ras_sbe_eclk ;
//assign iafu2mc_write_ras_dbe_eclk           = cxlip2iafu_write_ras_dbe_eclk ;
//assign iafu2mc_address_eclk                 = cxlip2iafu_address_eclk       ;
//assign iafu2mc_req_mdata_eclk               = cxlip2iafu_req_mdata_eclk     ;

 //=================================================================
 // 1) 在顶层实例化 cust_afu_wrapper，让它取代简单的 passthrough
 //=================================================================

 cust_afu_wrapper u_cust_wrapper (
   .axi4_mm_clk       (afu_clk),
   .axi4_mm_rst_n     (afu_rstn),

   // --------------------------
   // 1) MC ↔ AFU 接口 (mc2iafu_* 输入)
   // --------------------------
   .mc2iafu_ready_eclk            (mc2iafu_ready_eclk),
   .mc2iafu_read_poison_eclk      (mc2iafu_read_poison_eclk),
   .mc2iafu_readdatavalid_eclk    (mc2iafu_readdatavalid_eclk),
   .mc2iafu_ecc_err_corrected_eclk(mc2iafu_ecc_err_corrected_eclk),
   .mc2iafu_ecc_err_detected_eclk (mc2iafu_ecc_err_detected_eclk),
   .mc2iafu_ecc_err_fatal_eclk    (mc2iafu_ecc_err_fatal_eclk),
   .mc2iafu_ecc_err_syn_e_eclk    (mc2iafu_ecc_err_syn_e_eclk),
   .mc2iafu_ecc_err_valid_eclk    (mc2iafu_ecc_err_valid_eclk),
   .mc2iafu_cxlmem_ready          (mc2iafu_cxlmem_ready),
   .mc2iafu_readdata_eclk         (mc2iafu_readdata_eclk),
   .mc2iafu_rsp_mdata_eclk        (mc2iafu_rsp_mdata_eclk),

   // --------------------------
   // 2) AFU → MC 接口 (iafu2mc_* 输出)
   // --------------------------
   .iafu2mc_writedata_eclk        (iafu2mc_writedata_eclk),
   .iafu2mc_byteenable_eclk       (iafu2mc_byteenable_eclk),
   .iafu2mc_read_eclk             (iafu2mc_read_eclk),
   .iafu2mc_write_eclk            (iafu2mc_write_eclk),
   .iafu2mc_write_poison_eclk     (iafu2mc_write_poison_eclk),
   .iafu2mc_write_ras_sbe_eclk    (iafu2mc_write_ras_sbe_eclk),
   .iafu2mc_write_ras_dbe_eclk    (iafu2mc_write_ras_dbe_eclk),
   .iafu2mc_address_eclk          (iafu2mc_address_eclk),
   .iafu2mc_req_mdata_eclk        (iafu2mc_req_mdata_eclk),

   // --------------------------
   // 3) CAFU Passthrough (iafu2cxlip_* 输出)
   // --------------------------
   .iafu2cxlip_ready_eclk         (iafu2cxlip_ready_eclk),
   .iafu2cxlip_read_poison_eclk   (iafu2cxlip_read_poison_eclk),
   .iafu2cxlip_readdatavalid_eclk (iafu2cxlip_readdatavalid_eclk),
   .iafu2cxlip_ecc_err_corrected_eclk (iafu2cxlip_ecc_err_corrected_eclk),
   .iafu2cxlip_ecc_err_detected_eclk  (iafu2cxlip_ecc_err_detected_eclk),
   .iafu2cxlip_ecc_err_fatal_eclk     (iafu2cxlip_ecc_err_fatal_eclk),
   .iafu2cxlip_ecc_err_syn_e_eclk     (iafu2cxlip_ecc_err_syn_e_eclk),
   .iafu2cxlip_ecc_err_valid_eclk     (iafu2cxlip_ecc_err_valid_eclk),
   .iafu2cxlip_cxlmem_ready           (iafu2cxlip_cxlmem_ready),
   .iafu2cxlip_readdata_eclk          (iafu2cxlip_readdata_eclk),
   .iafu2cxlip_rsp_mdata_eclk         (iafu2cxlip_rsp_mdata_eclk),

   // --------------------------
   // 4) CXLIP → AFU Passthrough (cxlip2iafu_* 输入)
   // --------------------------
   .cxlip2iafu_writedata_eclk     (cxlip2iafu_writedata_eclk),
   .cxlip2iafu_byteenable_eclk    (cxlip2iafu_byteenable_eclk),
   .cxlip2iafu_read_eclk          (cxlip2iafu_read_eclk),
   .cxlip2iafu_write_eclk         (cxlip2iafu_write_eclk),
   .cxlip2iafu_write_poison_eclk  (cxlip2iafu_write_poison_eclk),
   .cxlip2iafu_write_ras_sbe_eclk (cxlip2iafu_write_ras_sbe_eclk),
   .cxlip2iafu_write_ras_dbe_eclk (cxlip2iafu_write_ras_dbe_eclk),
   .cxlip2iafu_address_eclk       (cxlip2iafu_address_eclk),
   .cxlip2iafu_req_mdata_eclk     (cxlip2iafu_req_mdata_eclk),
   // TileLink Cached 总线，顶层对外暴露
   .tl_clk         (tilelink_clk),
   .tl_rst_n       (tilelink_rstn),
   .tl_req_valid   (tl_cach_req_valid),
   .tl_req_ready   (tl_cach_req_ready),
   .tl_req_addr    (tl_cach_req_addr),
   .tl_req_len     (tl_cach_req_len),
   .tl_req_op      (tl_cach_req_op),
   .tl_req_wdata   (tl_cach_req_wdata),
   .tl_req_wstrb   (tl_cach_req_wstrb),
   .tl_resp_valid  (tl_cach_resp_valid),
   .tl_resp_ready  (tl_cach_resp_ready),
   .tl_resp_rdata  (tl_cach_resp_rdata),
   .tl_resp_code   (tl_cach_resp_code)
 );

 // （原来那一堆直接 assign 都删掉了）



endmodule
