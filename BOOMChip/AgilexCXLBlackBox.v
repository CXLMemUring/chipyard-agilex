// AgilexCXLBlackBox.v
// Blackbox stub for Intel Agilex CXL IP
// Implements AXI4 Slave interface driving CXL memory

`timescale 1ns/1ps

module intel_agilex_cxl_ip #(
  parameter ADDR_WIDTH = 64,
  parameter DATA_WIDTH = 64,
  parameter ID_WIDTH   = 4
)(
  input  wire                   clock,
  input  wire                   reset,
  // AXI4 Slave Write Address Channel
  input  wire [ID_WIDTH-1:0]    axi4_awid,
  input  wire [ADDR_WIDTH-1:0]  axi4_awaddr,
  input  wire [7:0]             axi4_awlen,
  input  wire [2:0]             axi4_awsize,
  input  wire [1:0]             axi4_awburst,
  input  wire [2:0]             axi4_awprot,
  input  wire [3:0]             axi4_awcache,
  input  wire [3:0]             axi4_awuser,
  input  wire [3:0]             axi4_awqos,
  input  wire                   axi4_awvalid,
  output wire                   axi4_awready,

  // AXI4 Slave Write Data Channel
  input  wire [DATA_WIDTH-1:0]  axi4_wdata,
  input  wire [DATA_WIDTH/8-1:0] axi4_wstrb,
  input  wire                   axi4_wlast,
  input  wire [3:0]             axi4_wuser,
  input  wire                   axi4_wvalid,
  output wire                   axi4_wready,

  // AXI4 Slave Write Response Channel
  output wire [ID_WIDTH-1:0]    axi4_bid,
  output wire [1:0]             axi4_bresp,
  output wire [3:0]             axi4_buser,
  output wire                   axi4_bvalid,
  input  wire                   axi4_bready,

  // AXI4 Slave Read Address Channel
  input  wire [ID_WIDTH-1:0]    axi4_arid,
  input  wire [ADDR_WIDTH-1:0]  axi4_araddr,
  input  wire [7:0]             axi4_arlen,
  input  wire [2:0]             axi4_arsize,
  input  wire [1:0]             axi4_arburst,
  input  wire [2:0]             axi4_arprot,
  input  wire [3:0]             axi4_arcache,
  input  wire [3:0]             axi4_aruser,
  input  wire                   axi4_arvalid,
  output wire                   axi4_arready,

  // AXI4 Slave Read Data Channel
  output wire [ID_WIDTH-1:0]    axi4_rid,
  output wire [DATA_WIDTH-1:0]  axi4_rdata,
  output wire [1:0]             axi4_rresp,
  output wire                   axi4_rlast,
  output wire                   axi4_rvalid,
  input  wire                   axi4_rready,

  // CXL-specific status
  output wire                   cxl_link_up
);

  // synthesis syn_black_box

endmodule
