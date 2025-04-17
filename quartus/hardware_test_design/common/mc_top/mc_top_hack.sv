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


/*-----------------------------------------------------------------------------
 * INTEL CONFIDENTIAL
 *
 * Copyright 2021-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and
 * your use of them is governed by the express license under which they were
 * provided to you ("License"). Unless the License provides otherwise, you may
 * not use, modify, copy, publish, distribute, disclose or transmit this
 * software or the related documents without Intel's prior written permission.
 * This software and the related documents are provided as is, with no express
 * or implied warranties, other than those that are expressly stated in the
 * License.
 * ----------------------------------------------------------------------------
 */

module mc_top_hack #(
   parameter MC_CHANNEL                = 2, // valid options are 1 and 2

   parameter MC_HA_DDR4_ADDR_WIDTH     = 17,
   parameter MC_HA_DDR4_BA_WIDTH       = 2,
   parameter MC_HA_DDR4_BG_WIDTH       = 2,
   parameter MC_HA_DDR4_CK_WIDTH       = 1,
   parameter MC_HA_DDR4_CKE_WIDTH      = 2,
   parameter MC_HA_DDR4_CS_WIDTH       = 2,
   parameter MC_HA_DDR4_ODT_WIDTH      = 2,
   parameter MC_HA_DDR4_DQS_WIDTH      = 9,
   parameter MC_HA_DDR4_DQ_WIDTH       = 72,
   parameter MC_HA_DDR4_DBI_WIDTH      = 9,
   parameter EMIF_AMM_ADDR_WIDTH       = 27,
   parameter EMIF_AMM_DATA_WIDTH       = 576,
   parameter EMIF_AMM_BURST_WIDTH      = 7,
   parameter EMIF_AMM_BE_WIDTH         = 72,

   parameter MC_HA_DP_ADDR_WIDTH       = 46,
   parameter MC_HA_DP_DATA_WIDTH       = 512,
   parameter MC_MDATA_WIDTH            = 18,
   parameter MC_MDATA_Q_DEPTH          = 8,
   parameter  MC_RAM_INIT_W_ZERO_EN    = 0, // 0 - OFF; 1 - ON

   localparam MC_SR_STAT_WIDTH          = 4,
   localparam MC_HA_DP_BITS_PER_SYMBOL  = 8,
   localparam MC_HA_DP_BE_WIDTH = MC_HA_DP_DATA_WIDTH / MC_HA_DP_BITS_PER_SYMBOL,
   localparam reqfifo_depth_width       = 6
)
(
input  logic         clk                       ,
input  logic         reset_n                   ,

output logic [63:0]                    mc2ha_memsize       , // Size (in bytes) of memory exposed to BIOS
output logic [MC_SR_STAT_WIDTH-1:0]    mc_sr_status_eclk      [MC_CHANNEL-1:0] ,  // Memory Controller Status
// == MC <--> iAFU signals ==
output logic [MC_CHANNEL-1:0]          mc2iafu_ready_eclk                         , // AVMM ready to iAFU
input  logic [MC_CHANNEL-1:0]          iafu2mc_read_eclk                          , // AVMM read request from iAFU
input  logic [MC_CHANNEL-1:0]          iafu2mc_write_eclk                         , // AVMM write request from iAFU
input  logic [MC_CHANNEL-1:0]          iafu2mc_write_poison_eclk                  , // AVMM write poison from iAFU
input  logic [MC_HA_DP_ADDR_WIDTH-1:0] iafu2mc_address_eclk        [MC_CHANNEL-1:0]  , // AVMM address from iAFU
input  logic [MC_MDATA_WIDTH-1:0]      iafu2mc_req_mdata_eclk      [MC_CHANNEL-1:0]  , // AVMM reqeust MDATA  from iAFU
output logic [MC_HA_DP_DATA_WIDTH-1:0] mc2iafu_readdata_eclk       [MC_CHANNEL-1:0]  , // AVMM read data to iAFU
output logic [MC_MDATA_WIDTH-1:0]      mc2iafu_rsp_mdata_eclk      [MC_CHANNEL-1:0]  , // AVMM response MDATA to iAFU
input  logic [MC_HA_DP_DATA_WIDTH-1:0] iafu2mc_writedata_eclk      [MC_CHANNEL-1:0]  , // AVMM write data from iAFU
input  logic [MC_HA_DP_BE_WIDTH-1:0]   iafu2mc_byteenable_eclk     [MC_CHANNEL-1:0]  , // AVMM byte enable from iAFU
output logic [MC_CHANNEL-1:0]          mc2iafu_read_poison_eclk                     ,  //  width = 1,
output logic [MC_CHANNEL-1:0]          mc2iafu_readdatavalid_eclk                 , // AVMM read data valid to iAFU
output logic [MC_CHANNEL-1:0]          mc2iafu_rddata_error_eclk                  , // AVMM read data error to iAFU

output logic [reqfifo_depth_width-1:0] reqfifo_fill_level_eclk     [MC_CHANNEL-1:0],

//`ifdef ENABLE_DDRT
//inout  wire                                 i2c_sda                     ,  // inout,  width = 1,
//output logic                                i2c_scl                     ,  // output, width = 1,
//`endif

// == DDR4 Interface ==
input  logic [MC_CHANNEL-1:0]                 mem_refclk                       ,  // EMIF PLL reference clock
output logic [MC_HA_DDR4_CK_WIDTH-1:0]        mem_ck         [MC_CHANNEL-1:0]  ,  // DDR4 interface signals
output logic [MC_HA_DDR4_CK_WIDTH-1:0]        mem_ck_n       [MC_CHANNEL-1:0]  ,  //
output logic [MC_HA_DDR4_ADDR_WIDTH-1:0]      mem_a          [MC_CHANNEL-1:0]  ,  //
output logic [MC_CHANNEL-1:0]                 mem_act_n                        ,  //
output logic [MC_HA_DDR4_BA_WIDTH-1:0]        mem_ba         [MC_CHANNEL-1:0]  ,  //
output logic [MC_HA_DDR4_BG_WIDTH-1:0]        mem_bg         [MC_CHANNEL-1:0]  ,  //
output logic [MC_HA_DDR4_CKE_WIDTH-1:0]       mem_cke        [MC_CHANNEL-1:0]  ,  //
output logic [MC_HA_DDR4_CS_WIDTH-1:0]        mem_cs_n       [MC_CHANNEL-1:0]  ,  //
//`ifdef ENABLE_DDRT
//output logic [MC_CHANNEL-1:0]                 mem_c2                           ,  //
//input  logic [MC_CHANNEL-1:0]                 mem_err_n                        ,  //
//input  logic [MC_CHANNEL-1:0]                 mem_req_n                        ,  //
//`endif
output logic [MC_HA_DDR4_ODT_WIDTH-1:0]       mem_odt        [MC_CHANNEL-1:0]  ,  //
output logic [MC_CHANNEL-1:0]                 mem_reset_n                      ,  //
output logic [MC_CHANNEL-1:0]                 mem_par                          ,  //
input  logic [MC_CHANNEL-1:0]                 mem_oct_rzqin                    ,  //
input  logic [MC_CHANNEL-1:0]                 mem_alert_n                      ,  //
inout  wire  [MC_HA_DDR4_DQS_WIDTH-1:0]       mem_dqs        [MC_CHANNEL-1:0]  ,  //
inout  wire  [MC_HA_DDR4_DQS_WIDTH-1:0]       mem_dqs_n      [MC_CHANNEL-1:0]  ,  //
inout  wire  [MC_HA_DDR4_DQ_WIDTH-1:0]        mem_dq         [MC_CHANNEL-1:0]  ,  //
inout  wire  [MC_HA_DDR4_DBI_WIDTH-1:0]       mem_dbi_n      [MC_CHANNEL-1:0]
);

logic [MC_CHANNEL-1:0]             mem_ready_rmw_mclk            ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_read_rmw_mclk             ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_write_rmw_mclk            ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_write_poison_rmw_mclk     ;  //  width = 1,
logic [MC_HA_DP_ADDR_WIDTH-1:0]    mem_address_rmw_mclk     [MC_CHANNEL-1:0];  //  width = 46,
logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_writedata_rmw_mclk   [MC_CHANNEL-1:0];  //  width = 512,
logic [MC_HA_DP_BE_WIDTH-1:0]      mem_byteenable_rmw_mclk  [MC_CHANNEL-1:0];  //  width = 64,
logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_readdata_rmw_mclk    [MC_CHANNEL-1:0];  //  width = 512,
logic [MC_CHANNEL-1:0]             mem_read_poison_rmw_mclk      ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_readdatavalid_rmw_mclk    ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_rddata_error_rmw_mclk     ;  //  width = 1,
logic [MC_CHANNEL-1:0]             mem_ecc_interrupt_rmw_mclk    ;  //  width = 1,

logic [MC_CHANNEL-1:0]             emif_usr_clk;
logic [MC_CHANNEL-1:0]             emif_usr_reset_n;
logic [MC_CHANNEL-1:0]             emif_pll_locked;
logic [MC_CHANNEL-1:0]             emif_reset_done;
logic [MC_CHANNEL-1:0]             emif_cal_success;
logic [MC_CHANNEL-1:0]             emif_cal_fail;

logic [MC_CHANNEL-1:0]             emif_amm_ready            ;  //  width = 1,
logic [MC_CHANNEL-1:0]             emif_amm_read             ;  //  width = 1,
logic [MC_CHANNEL-1:0]             emif_amm_write            ;  //  width = 1,
logic [EMIF_AMM_ADDR_WIDTH-1:0]    emif_amm_address     [MC_CHANNEL-1:0];  //  width = 27,
logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_writedata   [MC_CHANNEL-1:0];  //  width = 576,
logic [EMIF_AMM_BURST_WIDTH-1:0]   emif_amm_burstcount  [MC_CHANNEL-1:0];  //  width = 7,
logic [EMIF_AMM_BE_WIDTH-1:0]      emif_amm_byteenable  [MC_CHANNEL-1:0];  //  width = 72,
logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_readdata    [MC_CHANNEL-1:0];  //  width = 576,
logic [MC_CHANNEL-1:0]             emif_amm_readdatavalid    ;  //  width = 1,

logic [63:0]  mc_chan_memsize [MC_CHANNEL-1:0];

logic [MC_HA_DP_ADDR_WIDTH-1:0]        mc_baseaddr_cl;
logic                                  mc_baseaddr_cl_vld;

//always_comb begin
////    emif_usr_clk[0] = clk_tmp;
//    emif_usr_clk[0] = clk;
//    emif_usr_reset_n[0] = reset_n;
//    emif_pll_locked[0] = 1'b1;
//    emif_reset_done[0] = reset_n;
//    emif_cal_success[0] = 1'b1;
//    emif_cal_fail[0] = 1'b0;
//end

assign mc_baseaddr_cl = '0;
assign mc_baseaddr_cl_vld = 1'b1;

always_comb
  begin
    mc2ha_memsize = 0;
    for (int i=0; i<MC_CHANNEL; i=i+1)
      mc2ha_memsize = mc2ha_memsize + mc_chan_memsize[i];
  end

generate
genvar n;
for(n=0; n<MC_CHANNEL; n=n+1)
begin: MEM_CHANNEL // GENERATE_CHANNEL

always_comb begin
   emif_amm_read[n]    = mem_read_rmw_mclk[n];
   emif_amm_write[n]   = mem_write_rmw_mclk[n];
   emif_amm_address[n] = mem_address_rmw_mclk[n][EMIF_AMM_ADDR_WIDTH-1:0];

   emif_amm_writedata[n][MC_HA_DP_DATA_WIDTH-1:0] = mem_writedata_rmw_mclk[n];
   emif_amm_writedata[n][MC_HA_DP_DATA_WIDTH]     = mem_write_poison_rmw_mclk[n];
   emif_amm_writedata[n][EMIF_AMM_DATA_WIDTH-1:MC_HA_DP_DATA_WIDTH+1] = '0;

   emif_amm_burstcount[n][EMIF_AMM_BURST_WIDTH-1:1] = '0;
   emif_amm_burstcount[n][0] = 1'b1;

   emif_amm_byteenable[n] = '1;

   mem_ready_rmw_mclk[n]         = emif_amm_ready[n];
   mem_readdata_rmw_mclk[n]      = emif_amm_readdata[n][MC_HA_DP_DATA_WIDTH-1:0];
   mem_read_poison_rmw_mclk[n]   = emif_amm_readdata[n][MC_HA_DP_DATA_WIDTH];
   mem_readdatavalid_rmw_mclk[n] = emif_amm_readdatavalid[n];

   mem_rddata_error_rmw_mclk     = 1'b0;
   mem_ecc_interrupt_rmw_mclk    = 1'b0;
end

mc_channel_adapter #(
   .MC_HA_DP_ADDR_WIDTH        (MC_HA_DP_ADDR_WIDTH),
   .MC_HA_DP_DATA_WIDTH        (MC_HA_DP_DATA_WIDTH),
   .MC_MDATA_WIDTH             (MC_MDATA_WIDTH),
   .MC_MDATA_Q_DEPTH           (MC_MDATA_Q_DEPTH),
   .MC_RAM_INIT_W_ZERO_EN      (MC_RAM_INIT_W_ZERO_EN) // 0 - OFF; 1 - ON
)
mc_channel_adapter_inst (
   .clk                          (clk)                          ,  // input,    width = 1,
   .reset_n                      (reset_n)                         ,  // input,    width = 1,

   .mc_chan_memsize              (mc_chan_memsize[n])              ,  // outupt,   width = 64,
   .mc_baseaddr_cl               (mc_baseaddr_cl    )           ,  //                      mc_ha     : Base address of FPGA memory
   .mc_baseaddr_cl_vld           (mc_baseaddr_cl_vld)           ,  //                      mc_ha     : Base address registers have been set
//   .cr2mc_PtrlCtrl               (cr2mc_PtrlCtrl)                  ,  // input,    width = 32,

//   .emif_usr_clk               (emif_usr_clk[n]             ),
//   .emif_usr_reset_n           (emif_usr_reset_n[n]         ),
//   .emif_init_done_eclk        (emif_init_done_eclk[n]      ),

   // iAFU signals
   .mc2iafu_ready_eclk         ( mc2iafu_ready_eclk[n]         ),  //  input,   width = 1,
   .iafu2mc_read_eclk          ( iafu2mc_read_eclk[n]          ),  // output,   width = 1,
   .iafu2mc_write_eclk         ( iafu2mc_write_eclk[n]         ),  // output,   width = 1,
   .iafu2mc_write_poison_eclk  ( iafu2mc_write_poison_eclk[n]  ),  // output,   width = 1,
   .iafu2mc_address_eclk       ( iafu2mc_address_eclk[n]       ),  // output,   width = 46,
   .iafu2mc_req_mdata_eclk     ( iafu2mc_req_mdata_eclk[n]     ),  // output,   width = 46,
   .mc2iafu_readdata_eclk      ( mc2iafu_readdata_eclk[n]      ),  //  input,   width = 512,
   .mc2iafu_rsp_mdata_eclk     ( mc2iafu_rsp_mdata_eclk[n]     ),  //  input,   width = 512,
   .iafu2mc_writedata_eclk     ( iafu2mc_writedata_eclk[n]     ),  // output,   width = 512,
   .iafu2mc_byteenable_eclk    ( iafu2mc_byteenable_eclk[n]    ),  // output,   width = 64,
   .mc2iafu_read_poison_eclk   ( mc2iafu_read_poison_eclk[n]   ),  // output,   width = 1,
   .mc2iafu_readdatavalid_eclk ( mc2iafu_readdatavalid_eclk[n] ),  //  input,   width = 1,
   .mc2iafu_rddata_error_eclk  ( mc2iafu_rddata_error_eclk[n]  ),  //  input,   width = 1,

   .reqfifo_fill_level_eclk    ( reqfifo_fill_level_eclk[n]    ),

   .emif_usr_clk               (emif_usr_clk[n]    ),
   .emif_usr_reset_n           (emif_usr_reset_n[n]),
   .emif_pll_locked            (emif_pll_locked[n] ),
   .emif_reset_done            (emif_reset_done[n] ),
   .emif_cal_success           (emif_cal_success[n]),
   .emif_cal_fail              (emif_cal_fail[n]   ),

   .mc_sr_status_eclk          (mc_sr_status_eclk[n])                 ,  // output,

   .mem_ready_rmw_mclk         (mem_ready_rmw_mclk[n]        ),
   .mem_read_rmw_mclk          (mem_read_rmw_mclk[n]         ),
   .mem_write_rmw_mclk         (mem_write_rmw_mclk[n]        ),
   .mem_write_poison_rmw_mclk  (mem_write_poison_rmw_mclk[n] ),
   .mem_address_rmw_mclk       (mem_address_rmw_mclk[n]      ),
   .mem_writedata_rmw_mclk     (mem_writedata_rmw_mclk[n]    ),
   .mem_byteenable_rmw_mclk    (mem_byteenable_rmw_mclk[n]   ),
   .mem_readdata_rmw_mclk      (mem_readdata_rmw_mclk[n]     ),
   .mem_read_poison_rmw_mclk   (mem_read_poison_rmw_mclk[n]  ),
   .mem_readdatavalid_rmw_mclk (mem_readdatavalid_rmw_mclk[n]),
   .mem_rddata_error_rmw_mclk  (mem_rddata_error_rmw_mclk[n] ),
   .mem_ecc_interrupt_rmw_mclk (mem_ecc_interrupt_rmw_mclk[n])

);
end
endgenerate

mc_emif_hack #(
   .MC_CHANNEL            ( MC_CHANNEL            ),
   .MC_HA_DDR4_ADDR_WIDTH ( MC_HA_DDR4_ADDR_WIDTH ),
   .MC_HA_DDR4_BA_WIDTH   ( MC_HA_DDR4_BA_WIDTH   ),
   .MC_HA_DDR4_BG_WIDTH   ( MC_HA_DDR4_BG_WIDTH   ),
   .MC_HA_DDR4_CK_WIDTH   ( MC_HA_DDR4_CK_WIDTH   ),
   .MC_HA_DDR4_CKE_WIDTH  ( MC_HA_DDR4_CKE_WIDTH  ),
   .MC_HA_DDR4_CS_WIDTH   ( MC_HA_DDR4_CS_WIDTH   ),
   .MC_HA_DDR4_ODT_WIDTH  ( MC_HA_DDR4_ODT_WIDTH  ),
   .MC_HA_DDR4_DQS_WIDTH  ( MC_HA_DDR4_DQS_WIDTH  ),
   .MC_HA_DDR4_DQ_WIDTH   ( MC_HA_DDR4_DQ_WIDTH   ),
   .MC_HA_DDR4_DBI_WIDTH  ( MC_HA_DDR4_DBI_WIDTH  ),
   .EMIF_AMM_ADDR_WIDTH   ( EMIF_AMM_ADDR_WIDTH   ),
   .EMIF_AMM_DATA_WIDTH   ( EMIF_AMM_DATA_WIDTH   ),
   .EMIF_AMM_BURST_WIDTH  ( EMIF_AMM_BURST_WIDTH  ),
   .EMIF_AMM_BE_WIDTH     ( EMIF_AMM_BE_WIDTH     )
)
mc_emif_inst (
   .mc_chan_memsize        (mc_chan_memsize       ), // output // Size (in bytes) of memory channels

   .emif_usr_clk           (emif_usr_clk          ), // output EMIF User Clock
   .emif_usr_reset_n       (emif_usr_reset_n      ), // output EMIF reset
   .emif_pll_locked        (emif_pll_locked       ), // output width = 1,
   .emif_reset_done        (emif_reset_done       ), // output width = 1,
   .emif_cal_success       (emif_cal_success      ), // output width = 1,
   .emif_cal_fail          (emif_cal_fail         ), // output width = 1,

   .emif_amm_ready         (emif_amm_ready        ), // output width = 1,
   .emif_amm_read          (emif_amm_read         ), // input  width = 1,
   .emif_amm_write         (emif_amm_write        ), // input  width = 1,
   .emif_amm_address       (emif_amm_address      ), // input  width = 27,
   .emif_amm_writedata     (emif_amm_writedata    ), // input  width = 576,
   .emif_amm_burstcount    (emif_amm_burstcount   ), // input  width = 7,
   .emif_amm_byteenable    (emif_amm_byteenable   ), // input  width = 72,
   .emif_amm_readdata      (emif_amm_readdata     ), // output width = 576,
   .emif_amm_readdatavalid (emif_amm_readdatavalid), // output width = 1,
//   .emif_amm_rddata_error  (emif_amm_rddata_error ), // output width = 1,
//   .emif_amm_ecc_interrupt (emif_amm_ecc_interrupt), // output width = 1,
// == DDR4 Interface ==
   .mem_refclk             (mem_refclk),  // input  EMIF PLL reference clock
   .mem_ck                 (mem_ck    ),  // inout  DDR4 interface signals
   .mem_ck_n               (mem_ck_n  ),  // inout
   .mem_a                  (mem_a     ),  // output
   .mem_act_n              (mem_act_n ),  // output
   .mem_ba                 (mem_ba    ),  // output
   .mem_bg                 (mem_bg    ),  // output
   .mem_cke                (mem_cke   ),  // output
   .mem_cs_n               (mem_cs_n  ),  // output
//`ifdef ENABLE_DDRT
//   .mem_c2                  (mem_c2   ),  // output
//   .mem_err_n               (mem_err_n),  // input
//   .mem_req_n               (mem_req_n),  // input
//`endif
   .mem_odt                (mem_odt      ),  // output
   .mem_reset_n            (mem_reset_n  ),  // output
   .mem_par                (mem_par      ),  // output
   .mem_oct_rzqin          (mem_oct_rzqin),  // input
   .mem_alert_n            (mem_alert_n  ),  // input
   .mem_dqs                (mem_dqs      ),  // inout
   .mem_dqs_n              (mem_dqs_n    ),  // inout
   .mem_dq                 (mem_dq       ),  // inout
   .mem_dbi_n              (mem_dbi_n    )   // inout
);

endmodule
