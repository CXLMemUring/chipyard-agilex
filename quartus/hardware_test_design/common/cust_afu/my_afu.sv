// my_afu.sv
// 一个简单的 “TL→AVM” 转换 AFU 核心
module my_afu (
  input  logic         clk,
  input  logic         rst_n,

  // --------------------------------------------------
  // 1) Avalon‑MM Master 接口 (挂到 cust_afu_wrapper 的 avm_*)
  // --------------------------------------------------
  output logic [15:0]  avm_awid,
  output logic [51:0]  avm_awaddr,
  output logic [9:0]   avm_awlen,
  output logic [2:0]   avm_awsize,
  output logic [1:0]   avm_awburst,
  output logic [2:0]   avm_awprot,
  output logic [3:0]   avm_awcache,
  output logic [3:0]   avm_awuser,
  output logic [3:0]   avm_awqos,
  output logic         avm_awvalid,
  input  logic         avm_awready,

  output logic [511:0] avm_writedata,
  output logic [63:0]  avm_byteenable,
  output logic         avm_wlast,
  output logic         avm_wvalid,
  input  logic         avm_wready,

  input  logic [15:0]  avm_bid,
  input  logic [3:0]   avm_bresp,
  input  logic         avm_bvalid,
  output logic         avm_bready,

  output logic [15:0]  avm_arid,
  output logic [51:0]  avm_araddr,
  output logic [9:0]   avm_arlen,
  output logic [2:0]   avm_arsize,
  output logic [1:0]   avm_arburst,
  output logic [2:0]   avm_arprot,
  output logic [3:0]   avm_arcache,
  output logic [3:0]   avm_aruser,
  output logic         avm_arvalid,
  input  logic         avm_arready,

  input  logic [15:0]  avm_rid,
  input  logic [511:0] avm_rdata,
  input  logic [3:0]   avm_rresp,
  input  logic         avm_rlast,
  input  logic         avm_rvalid,
  output logic         avm_rready,

  // --------------------------------------------------
  // 2) TileLink Slave 接口 (挂到 cust_afu_wrapper 的 tl_*)
  // --------------------------------------------------
  input  logic         tl_clk,
  input  logic         tl_rst_n,
  input  logic         tl_req_valid,
  output logic         tl_req_ready,
  input  logic [63:0]  tl_req_addr,
  input  logic [7:0]   tl_req_len,
  input  logic [1:0]   tl_req_op,      // 2'b00=Read,2'b01=Write
  input  logic [511:0] tl_req_wdata,
  input  logic [63:0]  tl_req_wstrb,

  output logic         tl_resp_valid,
  input  logic         tl_resp_ready,
  output logic [511:0] tl_resp_rdata,
  output logic [1:0]   tl_resp_code    // e.g. 00=OKAY, 10=SLVERR
);

  // 状态机
  typedef enum logic [2:0] {
    S_IDLE,   // 等 TL 请求
    S_AR,     // 发起 AVM read-address
    S_R,      // 等待 AVM read-data
    S_AW,     // 发起 AVM write-address
    S_W,      // 发起 AVM write-data
    S_B,      // 等待 AVM write-response
    S_RESP    // 发 TL 响应
  } state_t;

  state_t state, next_state;

  // 请求寄存器 & 响应寄存器
  logic [63:0]  rq_addr;
  logic [7:0]   rq_len;
  logic [1:0]   rq_op;
  logic [511:0] rq_wdata;
  logic [63:0]  rq_wstrb;
  logic [511:0] rs_data;
  logic [1:0]   rs_code;

  // State 转移
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S_IDLE;
    else         state <= next_state;
  end

  // 主逻辑
  always_comb begin
    //—— 默认信号
    avm_awvalid   = 1'b0;
    avm_awid      = 0;
    avm_awaddr    = 0;
    avm_awlen     = 0;
    avm_awsize    = 3'd6;    // 2^6=64B
    avm_awburst   = 2'b01;   // INCR
    avm_awprot    = 3'b000;
    avm_awcache   = 4'b0011; // Inner‑shared cacheable
    avm_awuser    = 4'b0;
    avm_awqos     = 4'b0;

    avm_writedata = rq_wdata;
    avm_byteenable= rq_wstrb;
    avm_wlast     = 1'b1;
    avm_wvalid    = 1'b0;

    avm_bready    = 1'b0;

    avm_arvalid   = 1'b0;
    avm_arid      = 0;
    avm_araddr    = 0;
    avm_arlen     = rq_len;
    avm_arsize    = 3'd6;
    avm_arburst   = 2'b01;
    avm_arprot    = 3'b000;
    avm_arcache   = 4'b0011;
    avm_aruser    = 4'b0;

    avm_rready    = 1'b0;

    tl_req_ready  = 1'b0;
    tl_resp_valid = 1'b0;
    tl_resp_rdata = rs_data;
    tl_resp_code  = rs_code;

    next_state = state;

    case (state)
      //----------------------------------
      S_IDLE: begin
        tl_req_ready = 1'b1;
        if (tl_req_valid) begin
          // 捕获请求
          rq_addr   = tl_req_addr;
          rq_len    = tl_req_len;
          rq_op     = tl_req_op;
          rq_wdata  = tl_req_wdata;
          rq_wstrb  = tl_req_wstrb;
          if (tl_req_op == 2'b00) next_state = S_AR;
          else                     next_state = S_AW;
        end
      end

      //----------------------------------
      S_AR: begin
        avm_arvalid = 1'b1;
        avm_araddr  = rq_addr;
        if (avm_arready) next_state = S_R;
      end

      S_R: begin
        avm_rready = 1'b1;
        if (avm_rvalid && avm_rlast) begin
          rs_data = avm_rdata;
          rs_code = 2'b00;  // OKAY
          next_state = S_RESP;
        end
      end

      //----------------------------------
      S_AW: begin
        avm_awvalid = 1'b1;
        avm_awaddr  = rq_addr;
        if (avm_awready) next_state = S_W;
      end

      S_W: begin
        avm_wvalid = 1'b1;
        if (avm_wready) next_state = S_B;
      end

      S_B: begin
        avm_bready = 1'b1;
        if (avm_bvalid) begin
          rs_data = 512'b0;
          rs_code = avm_bresp[1:0];
          next_state = S_RESP;
        end
      end

      //----------------------------------
      S_RESP: begin
        tl_resp_valid = 1'b1;
        if (tl_resp_ready) next_state = S_IDLE;
      end

      default: next_state = S_IDLE;
    endcase
  end
endmodule