// (C) 2001-2023 Intel Corporation. All rights reserved.
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



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  fifo_cdc_to_mc_axi4_fifo_1923_jz4pbri  (
    data,
    rdclk,
    rdreq,
    wrclk,
    wrreq,
    q,
    rdempty,
    wrfull);

    input  [1023:0]  data;
    input    rdclk;
    input    rdreq;
    input    wrclk;
    input    wrreq;
    output [1023:0]  q;
    output   rdempty;
    output   wrfull;

    wire [1023:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [1023:0] q = sub_wire0[1023:0];
    wire  rdempty = sub_wire1;
    wire  wrfull = sub_wire2;

    dcfifo  dcfifo_component (
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .wrfull (sub_wire2),
                .aclr (1'b0),
                .eccstatus (),
                .rdfull (),
                .rdusedw (),
                .wrempty (),
                .wrusedw ());
    defparam
        dcfifo_component.enable_ecc  = "FALSE",
        dcfifo_component.intended_device_family  = "Agilex",
        dcfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        dcfifo_component.lpm_numwords  = 8,
        dcfifo_component.lpm_showahead  = "OFF",
        dcfifo_component.lpm_type  = "dcfifo",
        dcfifo_component.lpm_width  = 1024,
        dcfifo_component.lpm_widthu  = 3,
        dcfifo_component.overflow_checking  = "ON",
        dcfifo_component.rdsync_delaypipe  = 4,
        dcfifo_component.underflow_checking  = "ON",
        dcfifo_component.use_eab  = "ON",
        dcfifo_component.wrsync_delaypipe  = 4;


endmodule


