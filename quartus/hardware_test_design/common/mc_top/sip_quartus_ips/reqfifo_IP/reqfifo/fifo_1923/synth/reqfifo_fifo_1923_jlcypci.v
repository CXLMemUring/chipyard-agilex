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
module  reqfifo_fifo_1923_jlcypci  (
    aclr,
    data,
    rdclk,
    rdreq,
    wrclk,
    wrreq,
    q,
    rdempty,
    wrempty,
    wrfull,
    wrusedw);

    input    aclr;
    input  [639:0]  data;
    input    rdclk;
    input    rdreq;
    input    wrclk;
    input    wrreq;
    output [639:0]  q;
    output   rdempty;
    output   wrempty;
    output   wrfull;
    output [5:0]  wrusedw;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri0     aclr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [639:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire  sub_wire3;
    wire [5:0] sub_wire4;
    wire [639:0] q = sub_wire0[639:0];
    wire  rdempty = sub_wire1;
    wire  wrempty = sub_wire2;
    wire  wrfull = sub_wire3;
    wire [5:0] wrusedw = sub_wire4[5:0];

    dcfifo  dcfifo_component (
                .aclr (aclr),
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .wrempty (sub_wire2),
                .wrfull (sub_wire3),
                .wrusedw (sub_wire4),
                .eccstatus (),
                .rdfull (),
                .rdusedw ());
    defparam
        dcfifo_component.enable_ecc  = "FALSE",
        dcfifo_component.intended_device_family  = "Agilex",
        dcfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        dcfifo_component.lpm_numwords  = 64,
        dcfifo_component.lpm_showahead  = "ON",
        dcfifo_component.lpm_type  = "dcfifo",
        dcfifo_component.lpm_width  = 640,
        dcfifo_component.lpm_widthu  = 6,
        dcfifo_component.overflow_checking  = "OFF",
        dcfifo_component.rdsync_delaypipe  = 4,
        dcfifo_component.read_aclr_synch  = "ON",
        dcfifo_component.underflow_checking  = "OFF",
        dcfifo_component.use_eab  = "ON",
        dcfifo_component.write_aclr_synch  = "ON",
        dcfifo_component.wrsync_delaypipe  = 4;


endmodule


