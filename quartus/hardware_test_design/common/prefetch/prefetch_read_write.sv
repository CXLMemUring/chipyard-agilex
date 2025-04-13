/*
Module: prefetch_read_write
Version: 0.0
Last Modified: March 5, 2024
Description: Modified based on packet generator 0.0.1
Workflow: 
    1. set prefetch_page_addr to cxl mem address
    2. trigger start_prefetch, nc-read + nc-p-write
    3. wait for end_prefetch, finish
*/

module prefetch_read_write (

    input logic axi4_mm_clk,
    input logic axi4_mm_rst_n,

    // control logic 
    // set physical address of target cache line to prefetch_page_addr
    input logic [63:0] prefetch_page_addr, // byte level address
    input logic start_prefetch,
    output logic end_prefetch,
    output logic [511:0] prefetch_page_data,
    input logic [63:0] cxl_start_pa, // CDC issue?
    input logic [63:0] cxl_addr_offset,

    input logic [5:0] csr_aruser,
    input logic [5:0] csr_awuser,

    // read address channel
    output logic [11:0]               arid,
    output logic [63:0]               araddr,
    output logic [9:0]                arlen,    // must tie to 10'd0
    output logic [2:0]                arsize,   // must tie to 3'b110
    output logic [1:0]                arburst,  // must tie to 2'b00
    output logic [2:0]                arprot,   // must tie to 3'b000
    output logic [3:0]                arqos,    // must tie to 4'b0000
    output logic [5:0]                aruser,   // 4'b0000": non-cacheable, 4'b0001: cacheable shared, 4'b0010: cachebale owned
    output logic                      arvalid,
    output logic [3:0]                arcache,  // must tie to 4'b0000
    output logic [1:0]                arlock,   // must tie to 2'b00
    output logic [3:0]                arregion, // must tie to 4'b0000
    input                             arready,

    // read response channel
    input [11:0]                      rid,    // no use
    input [511:0]                     rdata,  
    input [1:0]                       rresp,  // no use: 2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
    input                             rlast,  // no use
    input                             ruser,  // no use
    input                             rvalid,
    output logic                      rready,


    // write address channel
    output logic [11:0]               awid,
    output logic [63:0]               awaddr, 
    output logic [9:0]                awlen,    // must tie to 10'd0
    output logic [2:0]                awsize,   // must tie to 3'b110 (64B/T)
    output logic [1:0]                awburst,  // must tie to 2'b00
    output logic [2:0]                awprot,   // must tie to 3'b000
    output logic [3:0]                awqos,    // must tie to 4'b0000
    output logic [5:0]                awuser,
    output logic                      awvalid,
    output logic [3:0]                awcache,  // must tie to 4'b0000
    output logic [1:0]                awlock,   // must tie to 2'b00
    output logic [3:0]                awregion, // must tie to 4'b0000
    output logic [5:0]                awatop,   // must tie to 6'b000000
    input                             awready,

    // write data channel
    output logic [511:0]              wdata,
    output logic [(512/8)-1:0]        wstrb,
    output logic                      wlast,
    output logic                      wuser,  // must tie to 1'b0
    output logic                      wvalid,
    input                             wready,

    // write response channel
    input [11:0]                      bid,    // no use
    input [1:0]                       bresp,  // no use: 2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
    input [3:0]                       buser,  // must tie to 4'b0000
    input                             bvalid,
    output logic                      bready
);



assign  awlen        = '0   ;
assign  awsize       = 3'b110   ; // must tie to 3'b110
assign  awburst      = '0   ;
assign  awprot       = '0   ;
assign  awqos        = '0   ;

assign  awcache      = '0   ;
assign  awlock       = '0   ;
assign  awregion     = '0   ;
assign  awatop       = '0   ; 

assign  wuser        = '0   ;

assign  arlen        = '0   ;
assign  arsize       = 3'b110   ; // must tie to 3'b110
assign  arburst      = '0   ;
assign  arprot       = '0   ;
assign  arqos        = '0   ;

assign  arcache      = '0   ;
assign  arlock       = '0   ;
assign  arregion     = '0   ;


logic start_prefetch_guarded;
logic [511:0] rdata_reg;
logic [63:0] prefetch_page_addr_r, output_addr_r;
logic [63:0] address_convertor_before_modulo, address_convertor;
logic [63:0] cxl_start_pa_r, cxl_addr_offset_r;
logic start_prefetch_r;
assign prefetch_page_data = rdata_reg;
logic w_handshake;
logic aw_handshake;

assign start_prefetch_guarded = start_prefetch & (prefetch_page_addr[33:6] != '1);
assign address_convertor_before_modulo = (prefetch_page_addr + cxl_addr_offset_r); // adding current address by 8GB - offset; this will make any address map to the first CPU PA 8GB address. 
assign address_convertor = {31'h0, address_convertor_before_modulo[32:0]}; // modulo by 8GB

enum logic [4:0] {
    STATE_RESET,
    STATE_RD_ADDR,
    STATE_RD_DATA,
    STATE_WR_SUB,
    STATE_WR_SUB_RESP
} state, next_state;

/*---------------------------------
functions
-----------------------------------*/
function void set_default();
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;
    arvalid = 1'b0;
    rready = 1'b0;
    arid = 'b0;
    araddr = 'b0;
    wdata = rdata_reg;  
    aruser = 'b0;
    awaddr = 'b0;
    awid = 'b0;
    awuser = 'b0; 
    wlast = 1'b0;
    wstrb = 64'h0;
endfunction

// queue one prefetch for TOP-2 tracker
task queue_prefetch();
    // store the second address
    if (start_prefetch_guarded && state != STATE_RESET) begin
        start_prefetch_r <= 1'b1;
        prefetch_page_addr_r <= address_convertor + cxl_start_pa_r;
    end

    // upon an valid issue 
    if (state == STATE_RESET) begin
        // put the proper address into "output_addr_r"
        if (start_prefetch_guarded) begin
            output_addr_r <= address_convertor + cxl_start_pa_r;
        end else if (start_prefetch_r) begin
            start_prefetch_r <= 1'b0;
            output_addr_r <= prefetch_page_addr_r;
        end
    end
endtask

always_ff @(posedge axi4_mm_clk) begin
    if (!axi4_mm_rst_n) begin
        state <= STATE_RESET;
        rdata_reg <= 512'b0;
        end_prefetch <= 1'b0;

        start_prefetch_r <= 1'b0;
        prefetch_page_addr_r <= 'b0;
        output_addr_r <= 'b0;
        cxl_start_pa_r <= 'b0;
        cxl_addr_offset_r <= 'b0;

        w_handshake <= 1'b0;
        aw_handshake <= 1'b0;
    end
    else begin
        queue_prefetch();
        state <= next_state;
        cxl_start_pa_r <= cxl_start_pa;
        cxl_addr_offset_r <= cxl_addr_offset;
        unique case(state) 
            STATE_RD_DATA: begin
                if (rready & rvalid) begin
                    rdata_reg <= rdata;
                    aw_handshake <= 1'b0;
                    w_handshake <= 1'b0;
                end
            end

            STATE_WR_SUB: begin
                if (awvalid & awready) begin
                    aw_handshake <= 1'b1;
                end
                if (wvalid & wready) begin  // nc-p-write can start, otherwise wait 
                    w_handshake <= 1'b1;
                end
            end

            STATE_WR_SUB_RESP: begin
                if (bvalid & bready) begin  // nc-p-write done
                    aw_handshake <= 1'b0;
                    w_handshake <= 1'b0;
                    end_prefetch <= 1'b1;
                end
            end

            default: begin
                end_prefetch <= 1'b0;
            end
        endcase
    end
end




/*---------------------------------
FSM
-----------------------------------*/

always_comb begin
    next_state = state;
    unique case(state)
        STATE_RESET: begin
            // guard for prefetching wrong address
            if (start_prefetch_guarded) begin
                next_state = STATE_RD_ADDR;
            end else if (start_prefetch_r) begin
                next_state = STATE_RD_ADDR;
            end else begin
                next_state = STATE_RESET;
            end
        end

        STATE_RD_ADDR: begin
            if (arready & arvalid) begin
                next_state = STATE_RD_DATA;
            end
            else begin
                next_state = STATE_RD_ADDR;
            end
        end

        STATE_RD_DATA: begin
            if (rready & rvalid) begin
                next_state = STATE_WR_SUB;
            end
            else begin
                next_state = STATE_RD_DATA;
            end
        end

        STATE_WR_SUB: begin
            if (awready & wready) begin
                next_state = STATE_WR_SUB_RESP;
            end
            else if (wvalid == 1'b0) begin
                if (awready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else if (awvalid == 1'b0) begin
                if (wready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else begin
                next_state = STATE_WR_SUB;
            end
        end

        STATE_WR_SUB_RESP: begin
            if (bvalid & bready) begin
                next_state = STATE_RESET; 
            end
            else begin
                next_state = STATE_WR_SUB_RESP;
            end
        end

        default: begin
            next_state = STATE_RESET;
        end
    endcase
end

always_comb begin
    set_default();
    unique case(state)
        STATE_RD_ADDR: begin
            arvalid = 1'b1;
            arid = 12'd2; // id can be any value within 2^12 as you want
            aruser = csr_aruser; // own, host-bias, hdm 
            // aruser = 6'b100000; // may need to change to host bias 
            araddr = output_addr_r;
        end

        STATE_RD_DATA: begin
            rready = 1'b1;
        end

        STATE_WR_SUB: begin
            if (aw_handshake == 1'b0) begin
                awvalid = 1'b1;
            end
            else begin
                awvalid = 1'b0;
            end
            awid = 12'd2;
            awuser = csr_awuser; // non-cacheable push, d2d, host bias
            awaddr = output_addr_r;

            if (w_handshake == 1'b0) begin
                wvalid = 1'b1;
            end
            else begin
                wvalid = 1'b0;
            end
            wlast = 1'b1;
            wstrb = 64'hffffffffffffffff;
        end

        STATE_WR_SUB_RESP: begin
            bready = 1'b1;
        end

        default: begin

        end
    endcase
end
    

endmodule
