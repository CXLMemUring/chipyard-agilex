`timescale 1ns/1ps

module intel_agilex_cxl_ip #(
  parameter ADDR_WIDTH     = 64,
  parameter DATA_WIDTH     = 64,
  parameter ID_WIDTH       = 4,
  parameter MEM_DEPTH      = 1024
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
  output reg                    axi4_awready,

  // AXI4 Slave Write Data Channel
  input  wire [DATA_WIDTH-1:0]  axi4_wdata,
  input  wire [DATA_WIDTH/8-1:0] axi4_wstrb,
  input  wire                   axi4_wlast,
  input  wire [3:0]             axi4_wuser,
  input  wire                   axi4_wvalid,
  output reg                    axi4_wready,

  // AXI4 Slave Write Response Channel
  output reg [ID_WIDTH-1:0]     axi4_bid,
  output reg [1:0]              axi4_bresp,
  output reg [3:0]              axi4_buser,
  output reg                    axi4_bvalid,
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
  output reg                    axi4_arready,

  // AXI4 Slave Read Data Channel
  output reg [ID_WIDTH-1:0]     axi4_rid,
  output reg [DATA_WIDTH-1:0]   axi4_rdata,
  output reg [1:0]              axi4_rresp,
  output reg                    axi4_rlast,
  output reg                    axi4_rvalid,
  input  wire                   axi4_rready,

  // CXL-specific status
  output wire                   cxl_link_up
);

  // Local parameters for memory indexing
  localparam C_ADDR_LSB         = $clog2(DATA_WIDTH/8);
  localparam C_MEM_ADDR_WIDTH   = $clog2(MEM_DEPTH);

  // Simple memory array for AXI transactions
  reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

  // --------------------------------------------------
  // Write Address Channel
  // --------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      axi4_awready <= 1'b0;
    end else begin
      // Always ready to accept address when not in a write
      axi4_awready <= ~axi4_bvalid;
    end
  end

  // --------------------------------------------------
  // Write Data Channel
  // --------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      axi4_wready <= 1'b0;
    end else begin
      // Accept write data when AW accepted and no outstanding write response
      axi4_wready <= axi4_awready;
    end
  end

  // --------------------------------------------------
  // Write Response Channel
  // --------------------------------------------------
  wire aw_fire = axi4_awvalid & axi4_awready;
  wire w_fire  = axi4_wvalid  & axi4_wready;

  reg [ID_WIDTH-1:0] awid_reg;
  reg [ADDR_WIDTH-1:0] awaddr_reg;

  always @(posedge clock) begin
    if (reset) begin
      axi4_bvalid <= 1'b0;
      axi4_bid    <= {ID_WIDTH{1'b0}};
      axi4_bresp  <= 2'b00;
      axi4_buser  <= 4'b0;
      awid_reg    <= {ID_WIDTH{1'b0}};
      awaddr_reg  <= {ADDR_WIDTH{1'b0}};
    end else begin
      if (aw_fire) begin
        awid_reg   <= axi4_awid;
        awaddr_reg <= axi4_awaddr;
      end
      if (w_fire) begin
        // Perform the write (single-beat only)
        mem[axi4_awaddr[C_ADDR_LSB +: C_MEM_ADDR_WIDTH]] <= axi4_wdata;
        // Issue write response
        axi4_bid   <= awid_reg;
        axi4_bresp <= 2'b00;
        axi4_buser <= 4'b0;
        axi4_bvalid <= 1'b1;
      end else if (axi4_bvalid & axi4_bready) begin
        axi4_bvalid <= 1'b0;
      end
    end
  end

  // --------------------------------------------------
  // Read Address Channel
  // --------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      axi4_arready <= 1'b0;
    end else begin
      // Ready to accept next read when no read data pending
      axi4_arready <= ~axi4_rvalid;
    end
  end

  // --------------------------------------------------
  // Read Data Channel
  // --------------------------------------------------
  wire ar_fire = axi4_arvalid & axi4_arready;

  reg [ID_WIDTH-1:0] arid_reg;
  reg [ADDR_WIDTH-1:0] araddr_reg;

  always @(posedge clock) begin
    if (reset) begin
      axi4_rvalid <= 1'b0;
      axi4_rid    <= {ID_WIDTH{1'b0}};
      axi4_rresp  <= 2'b00;
      axi4_rlast  <= 1'b0;
      arid_reg    <= {ID_WIDTH{1'b0}};
      araddr_reg  <= {ADDR_WIDTH{1'b0}};
      axi4_rdata  <= {DATA_WIDTH{1'b0}};
    end else begin
      if (ar_fire) begin
        arid_reg   <= axi4_arid;
        araddr_reg <= axi4_araddr;
        // Issue read data (single-beat only)
        axi4_rid    <= axi4_arid;
        axi4_rdata  <= mem[axi4_araddr[C_ADDR_LSB +: C_MEM_ADDR_WIDTH]];
        axi4_rresp  <= 2'b00;
        axi4_rlast  <= 1'b1;
        axi4_rvalid <= 1'b1;
      end else if (axi4_rvalid & axi4_rready) begin
        axi4_rvalid <= 1'b0;
      end
    end
  end

  // --------------------------------------------------
  // CXL link status
  // --------------------------------------------------
  assign cxl_link_up = 1'b1;

endmodule
