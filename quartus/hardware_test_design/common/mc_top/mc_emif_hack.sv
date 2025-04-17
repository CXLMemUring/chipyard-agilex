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

module mc_emif_hack #(
   parameter MC_CHANNEL                 = 2, // valid options are 1 and 2

   parameter MC_HA_DDR4_ADDR_WIDTH      = 17,
   parameter MC_HA_DDR4_BA_WIDTH        = 2,
   parameter MC_HA_DDR4_BG_WIDTH        = 2,
   parameter MC_HA_DDR4_CK_WIDTH        = 1,
   parameter MC_HA_DDR4_CKE_WIDTH       = 2,
   parameter MC_HA_DDR4_CS_WIDTH        = 2,
   parameter MC_HA_DDR4_ODT_WIDTH       = 2,
   parameter MC_HA_DDR4_DQS_WIDTH       = 9,
   parameter MC_HA_DDR4_DQ_WIDTH        = 72,
   parameter MC_HA_DDR4_DBI_WIDTH       = 9,
   parameter EMIF_AMM_ADDR_WIDTH        = 27,
   parameter EMIF_AMM_DATA_WIDTH        = 576,
   parameter EMIF_AMM_BURST_WIDTH       = 7,
   parameter EMIF_AMM_BE_WIDTH          = 72
)
(
output logic [63:0]  mc_chan_memsize [MC_CHANNEL-1:0], // Size (in bytes) of memory channels

output logic [MC_CHANNEL-1:0]             emif_usr_clk                 ,  // EMIF User Clock
output logic [MC_CHANNEL-1:0]             emif_usr_reset_n             ,  // EMIF reset
output logic [MC_CHANNEL-1:0]             emif_pll_locked              ,  // width = 1,
output logic [MC_CHANNEL-1:0]             emif_reset_done              ,
output logic [MC_CHANNEL-1:0]             emif_cal_success             ,  // width = 1,
output logic [MC_CHANNEL-1:0]             emif_cal_fail                ,  // width = 1,

output logic [MC_CHANNEL-1:0]             emif_amm_ready            ,  //  width = 1,
input  logic [MC_CHANNEL-1:0]             emif_amm_read             ,  //  width = 1,
input  logic [MC_CHANNEL-1:0]             emif_amm_write            ,  //  width = 1,
input  logic [EMIF_AMM_ADDR_WIDTH-1:0]    emif_amm_address     [MC_CHANNEL-1:0],  //  width = 27,
input  logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_writedata   [MC_CHANNEL-1:0],  //  width = 576,
input  logic [EMIF_AMM_BURST_WIDTH-1:0]   emif_amm_burstcount  [MC_CHANNEL-1:0],  //  width = 7,
input  logic [EMIF_AMM_BE_WIDTH-1:0]      emif_amm_byteenable  [MC_CHANNEL-1:0],  //  width = 72,
output logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_readdata    [MC_CHANNEL-1:0],  //  width = 576,
output logic [MC_CHANNEL-1:0]             emif_amm_readdatavalid    ,  //  width = 1,
//output logic [MC_CHANNEL-1:0]             emif_amm_rddata_error     ,  //  width = 1,
//output logic [MC_CHANNEL-1:0]             emif_amm_ecc_interrupt    ,  //  width = 1,

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

wire                  emif_cal_0_calbus_clk;                             // emif_cal_0:calbus_clk -> [emif_fm_0:calbus_clk, emif_fm_1:calbus_clk]
wire           [31:0] emif_cal_0_calbus_wdata         [MC_CHANNEL-1:0];                      // emif_cal_0:calbus_wdata_0 -> emif_fm_0:calbus_wdata
wire           [19:0] emif_cal_0_calbus_address       [MC_CHANNEL-1:0];                    // emif_cal_0:calbus_address_0 -> emif_fm_0:calbus_address
wire         [4095:0] emif_cal_0_calbus_seq_param_tbl [MC_CHANNEL-1:0];                 // emif_fm_0:calbus_seq_param_tbl -> emif_cal_0:calbus_seq_param_tbl_0
wire [MC_CHANNEL-1:0] emif_cal_0_calbus_read;                       // emif_cal_0:calbus_read_0 -> emif_fm_0:calbus_read
wire [MC_CHANNEL-1:0] emif_cal_0_calbus_write;                      // emif_cal_0:calbus_write_0 -> emif_fm_0:calbus_write
wire           [31:0] emif_cal_0_calbus_rdata         [MC_CHANNEL-1:0];                         // emif_fm_0:calbus_rdata -> emif_cal_0:calbus_rdata_0

logic [EMIF_AMM_DATA_WIDTH-1:0] ddr_ram [2**EMIF_AMM_ADDR_WIDTH-1:0];

generate
genvar n;
for(n=0; n<MC_CHANNEL; n=n+1)
begin: MEM_CHANNEL // GENERATE_CHANNEL

    // == memory channel size in bytes ==
//    assign mc_chan_memsize[n] = 64'h20_0000_0000;  // 128 GB
//    assign mc_chan_memsize[n] = 64'h8_0000_0000;  // 32 GB
    assign mc_chan_memsize[n] = 64'h2_0000_0000;  // 8 GB
/*
    ed_synth_emif_fm_0 emif_inst (
        .local_reset_req      (1'b0), //   input,     width = 1,    local_reset_req.local_reset_req
        .local_reset_done     (emif_reset_done[n]),              //  output,     width = 1, local_reset_status.local_reset_done
        .pll_ref_clk          (mem_refclk[n]),                                  //   input,     width = 1,        pll_ref_clk.clk
        .pll_ref_clk_out      (),                                                           //  output,     width = 1,    pll_ref_clk_out.clk
        .pll_locked           (emif_pll_locked[n]),                                                           //  output,     width = 1,         pll_locked.pll_locked
        .oct_rzqin            (mem_oct_rzqin[n]),                                    //   input,     width = 1,                oct.oct_rzqin
        .mem_ck               (mem_ck[n]),                                       //  output,     width = 1,                mem.mem_ck
        .mem_ck_n             (mem_ck_n[n]),                                     //  output,     width = 1,                   .mem_ck_n
        .mem_a                (mem_a[n]),                                        //  output,    width = 17,                   .mem_a
        .mem_act_n            (mem_act_n[n]),                                    //  output,     width = 1,                   .mem_act_n
        .mem_ba               (mem_ba[n]),                                       //  output,     width = 2,                   .mem_ba
        .mem_bg               (mem_bg[n]),                                       //  output,     width = 2,                   .mem_bg
        .mem_cke              (mem_cke[n]),                                      //  output,     width = 2,                   .mem_cke
        .mem_cs_n             (mem_cs_n[n]),                                     //  output,     width = 2,                   .mem_cs_n
        .mem_odt              (mem_odt[n]),                                      //  output,     width = 2,                   .mem_odt
        .mem_reset_n          (mem_reset_n[n]),                                  //  output,     width = 1,                   .mem_reset_n
        .mem_par              (mem_par[n]),                                      //  output,     width = 1,                   .mem_par
        .mem_alert_n          (mem_alert_n[n]),                                  //   input,     width = 1,                   .mem_alert_n
        .mem_dqs              (mem_dqs[n]),                                      //   inout,     width = 9,                   .mem_dqs
        .mem_dqs_n            (mem_dqs_n[n]),                                    //   inout,     width = 9,                   .mem_dqs_n
        .mem_dq               (mem_dq[n]),                                       //   inout,    width = 72,                   .mem_dq
        .mem_dbi_n            (mem_dbi_n[n]),                                    //   inout,     width = 9,                   .mem_dbi_n
        .local_cal_success    (emif_cal_success[n]),                         //  output,     width = 1,             status.local_cal_success
        .local_cal_fail       (emif_cal_fail[n]),                            //  output,     width = 1,                   .local_cal_fail
        .emif_usr_reset_n     (emif_usr_reset_n[n]),                           //  output,     width = 1,   emif_usr_reset_n.reset_n
        .emif_usr_clk         (emif_usr_clk[n]),                                 //  output,     width = 1,       emif_usr_clk.clk
        .amm_ready_0          (emif_amm_ready[n]),         //  output,     width = 1,         ctrl_amm_0.waitrequest_n
        .amm_read_0           (emif_amm_read[n]),                //   input,     width = 1,                   .read
        .amm_write_0          (emif_amm_write[n]),               //   input,     width = 1,                   .write
        .amm_address_0        (emif_amm_address[n]),             //   input,    width = 27,                   .address
        .amm_readdata_0       (emif_amm_readdata[n]),            //  output,   width = 576,                   .readdata
        .amm_writedata_0      (emif_amm_writedata[n]),           //   input,   width = 576,                   .writedata
        .amm_burstcount_0     (emif_amm_burstcount[n]),          //   input,     width = 7,                   .burstcount
        .amm_byteenable_0     (emif_amm_byteenable[n]),          //   input,    width = 72,                   .byteenable
        .amm_readdatavalid_0  (emif_amm_readdatavalid[n]),       //  output,     width = 1,                   .readdatavalid
        .calbus_read          (emif_cal_0_calbus_read[n]),                       //   input,     width = 1,        emif_calbus.calbus_read
        .calbus_write         (emif_cal_0_calbus_write[n]),                      //   input,     width = 1,                   .calbus_write
        .calbus_address       (emif_cal_0_calbus_address[n]),                    //   input,    width = 20,                   .calbus_address
        .calbus_wdata         (emif_cal_0_calbus_wdata[n]),                      //   input,    width = 32,                   .calbus_wdata
        .calbus_rdata         (emif_cal_0_calbus_rdata[n]),                         //  output,    width = 32,                   .calbus_rdata
        .calbus_seq_param_tbl (emif_cal_0_calbus_seq_param_tbl[n]),                 //  output,  width = 4096,                   .calbus_seq_param_tbl
        .calbus_clk           (emif_cal_0_calbus_clk)                              //   input,     width = 1,    emif_calbus_clk.clk
    );
*/
end
endgenerate

generate
/*
    if (MC_CHANNEL == 1) begin : one_mem_ch
        ed_synth_emif_cal_0 emif_cal_0 (
            .calbus_read_0          (emif_cal_0_calbus_read[0]),       //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (emif_cal_0_calbus_write[0]),      //  output,     width = 1,                .calbus_write
            .calbus_address_0       (emif_cal_0_calbus_address[0]),    //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (emif_cal_0_calbus_wdata[0]),      //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (emif_cal_0_calbus_rdata[0]),         //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (emif_cal_0_calbus_seq_param_tbl[0]), //   input,  width = 4096,                .calbus_seq_param_tbl
            .calbus_read_1          (),       //  output,     width = 1,   emif_calbus_1.calbus_read
            .calbus_write_1         (),      //  output,     width = 1,                .calbus_write
            .calbus_address_1       (),    //  output,    width = 20,                .calbus_address
            .calbus_wdata_1         (),      //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_1         (32'b0),         //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_1 (4096'b0), //   input,  width = 4096,                .calbus_seq_param_tbl
            .calbus_clk             (emif_cal_0_calbus_clk)              //  output,     width = 1, emif_calbus_clk.clk
        );
    end
    else begin : two_mem_ch
        ed_synth_emif_cal_0 emif_cal_0 (
            .calbus_read_0          (emif_cal_0_calbus_read[0]),       //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (emif_cal_0_calbus_write[0]),      //  output,     width = 1,                .calbus_write
            .calbus_address_0       (emif_cal_0_calbus_address[0]),    //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (emif_cal_0_calbus_wdata[0]),      //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (emif_cal_0_calbus_rdata[0]),         //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (emif_cal_0_calbus_seq_param_tbl[0]), //   input,  width = 4096,                .calbus_seq_param_tbl
            .calbus_read_1          (emif_cal_0_calbus_read[1]),       //  output,     width = 1,   emif_calbus_1.calbus_read
            .calbus_write_1         (emif_cal_0_calbus_write[1]),      //  output,     width = 1,                .calbus_write
            .calbus_address_1       (emif_cal_0_calbus_address[1]),    //  output,    width = 20,                .calbus_address
            .calbus_wdata_1         (emif_cal_0_calbus_wdata[1]),      //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_1         (emif_cal_0_calbus_rdata[1]),         //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_1 (emif_cal_0_calbus_seq_param_tbl[1]), //   input,  width = 4096,                .calbus_seq_param_tbl
            .calbus_clk             (emif_cal_0_calbus_clk)              //  output,     width = 1, emif_calbus_clk.clk
        );
    end
*/
endgenerate


initial begin
  emif_usr_clk = '0;
end

always begin
  #2000 emif_usr_clk = ~emif_usr_clk; // match fpga fabric clock
//  #20000 emif_usr_clk = ~emif_usr_clk;
end

initial begin
  emif_pll_locked  = '0;
  emif_reset_done  = '0;
  emif_cal_success = '0;
  emif_cal_fail    = '0;
  emif_usr_reset_n = '0;
  emif_amm_ready   = '0;

  #10000 emif_pll_locked  = '1;
  #10000 emif_reset_done  = '1;
         emif_cal_success = '1;
  #10000 emif_usr_reset_n = '1;
         emif_amm_ready   = '1;
end

always_ff @(posedge emif_usr_clk) begin
  if (emif_amm_write) begin
    ddr_ram[emif_amm_address[0]] <= emif_amm_writedata[0];
  end

  if (emif_amm_read) begin
    emif_amm_readdata[0] <= ddr_ram[emif_amm_address[0]];
    emif_amm_readdatavalid[0] <= 1'b1;
  end
  else begin
    emif_amm_readdatavalid[0] <= 1'b0;
  end
end


endmodule
