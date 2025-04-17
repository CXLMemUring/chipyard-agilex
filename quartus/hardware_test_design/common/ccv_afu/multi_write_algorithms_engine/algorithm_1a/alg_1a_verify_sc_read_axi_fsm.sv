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
`include "ccv_afu_globals.vh.iv"

module alg_1a_verify_sc_read_axi_fsm
    import afu_axi_if_pkg::*;
#(
   parameter FIFO_PTR_WIDTH = 4
)
(
  input clk,
  input reset_n,    // active low reset

  input         force_disable_afu,                 // active high
  input         set_to_busy,
  input         set_to_not_busy,
  input [2:0]   verify_semantics_cache_reg,
  
  input [FIFO_PTR_WIDTH-1:0]  fifo_count,
  input                       fifo_empty,
  input [8:0]                 fifo_out_N,
  input [51:0]                fifo_out_addr,
  output logic                fifo_pop,

  /* signals for AXI-MM read address channel
  */
  output t_axi4_rd_addr_ch          read_addr_chan,
  input  t_axi4_rd_addr_ready       arready
);


typedef enum logic [3:0] {
  AXI_RD_IDLE            = 4'd0,
// AXI_RD_WAIT_TIL_4      = 4'd1,
  AXI_RD_WAIT_TIL_NOT_EMPTY      = 4'd1,
  AXI_RD_FIRST_POP       = 4'd2,
  AXI_RD_FIRST_ARVALID   = 4'd3,
  AXI_RD_FIRST_ARREADY   = 4'd4,
  AXI_RD_NEXT_ARVALID    = 4'd5,
  AXI_RD_NEXT_ARREADY    = 4'd6,
  AXI_RD_LAST_ARVALID    = 4'd7,
  AXI_RD_LAST_ARREADY    = 4'd8,
  AXI_RD_FIRST_WAIT      = 4'd9
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

logic clock_addr_chan;
logic clear_addr_chan;


/*
 handle the state register
*/
always_ff @( posedge clk )
begin : register_axi_state
       if( reset_n == 1'b0 )            state <= AXI_RD_IDLE;
  else if( force_disable_afu == 1'b1 )  state <= AXI_RD_IDLE;
  else                                  state <= next_state;
end

/*
 handle the next state logic
*/
always_comb
begin : comb_axi_next_state
           fifo_pop = 1'b0;
    clock_addr_chan = 1'b0;
    clear_addr_chan = 1'b0;




  case( state )
    AXI_RD_IDLE :
    begin
      if( set_to_busy == 1'b1 ) next_state = AXI_RD_WAIT_TIL_NOT_EMPTY;  //AXI_RD_WAIT_TIL_4;
      else                      next_state = AXI_RD_IDLE;
    end

//    AXI_RD_WAIT_TIL_4 :
    AXI_RD_WAIT_TIL_NOT_EMPTY :
    begin
           if( set_to_not_busy == 1'b1 ) next_state = AXI_RD_IDLE;
//      else if( fifo_count < 'd4 )        next_state = AXI_RD_WAIT_TIL_4;
//      else                               next_state = AXI_RD_FIRST_POP;
      else if( fifo_count > 'd0 )        next_state = AXI_RD_FIRST_WAIT;
      else                               next_state = AXI_RD_WAIT_TIL_NOT_EMPTY;
    end

    AXI_RD_FIRST_WAIT :
    begin 
      /*   needed because fifo's count updates cycle before avialable for pop
      */
                          next_state = AXI_RD_FIRST_POP;
    end

    AXI_RD_FIRST_POP :
    begin
      /* fifo had at least 4 entries, so pop fifo
      */
                          next_state = AXI_RD_FIRST_ARVALID;
                            fifo_pop = 1'b1;
    end

//    AXI_RD_FIRST_ARVALID :
//    begin
      /* assign the first fifo popped entry arriving to the axi addr channel
      */
/*                          next_state = AXI_RD_FIRST_ARREADY;
                     clock_addr_chan = 1'b1;

      if( fifo_empty == 1'b0 ) 
      begin
                            fifo_pop = 1'b1;
      end
    end
*/

    AXI_RD_FIRST_ARVALID :
    begin
      /* assign the first fifo popped entry arriving to the axi addr channel
      */
                     clock_addr_chan = 1'b1;

      if( fifo_empty == 1'b0 ) 
      begin
                          next_state = AXI_RD_FIRST_ARREADY;
                            fifo_pop = 1'b1;
      end
     else begin             // only one packet in the fifo
                          next_state = AXI_RD_LAST_ARREADY;
     end
    end

/*    AXI_RD_FIRST_ARREADY :
    begin
      if( arready == 1'b0 )
      begin
                          next_state = AXI_RD_FIRST_ARREADY;
      end
      else begin
	             clear_addr_chan = 1'b1;
                          next_state = AXI_RD_NEXT_ARVALID;
      end
    end
*/

    AXI_RD_FIRST_ARREADY :
    begin
      /* here because more than one packet is in the fifo
      */
      if( arready == 1'b0 )    // wait on the arready for the first packet
      begin
                          next_state = AXI_RD_FIRST_ARREADY;
      end
      else begin
           if( fifo_empty == 1'b0 )  // clock the second packet and pop for the third
           begin
                          next_state = AXI_RD_NEXT_ARREADY;
	             clock_addr_chan = 1'b1;
                            fifo_pop = 1'b1;
           end
           else begin    // clock the second and final packet
                          next_state = AXI_RD_LAST_ARREADY;
	             clock_addr_chan = 1'b1;
           end
      end
    end

    AXI_RD_NEXT_ARVALID :
    begin
      /*  assumes pop already occured
      */
                          next_state = AXI_RD_NEXT_ARREADY;
                     clock_addr_chan = 1'b1;

      if( fifo_empty == 1'b0 ) 
      begin
                            fifo_pop = 1'b1;
      end
    end

/*    AXI_RD_NEXT_ARREADY :
    begin
      if( arready == 1'b0 )
      begin
                          next_state = AXI_RD_NEXT_ARREADY;
      end
      else begin
	            clear_addr_chan = 1'b1;

           if( fifo_count > 0 )
                          next_state = AXI_RD_NEXT_ARVALID;
           else
                          next_state = AXI_RD_LAST_ARVALID;
      end
    end
*/

    AXI_RD_NEXT_ARREADY :
    begin
      if( arready == 1'b0 )   // wait for the next arready
      begin
                          next_state = AXI_RD_NEXT_ARREADY;
      end
      else begin
           if( fifo_empty == 1'b0 )  // clock next packet, pop packet after it
           begin
                          next_state = AXI_RD_NEXT_ARREADY;
                     clock_addr_chan = 1'b1;
                            fifo_pop = 1'b1;
           end
           else begin      // clock the next and final packet
                          next_state = AXI_RD_LAST_ARREADY;
                     clock_addr_chan = 1'b1;
           end
      end
    end

    AXI_RD_LAST_ARVALID :
    begin
      /*  assumes pop already occured
      */
                          next_state = AXI_RD_LAST_ARREADY;
                     clock_addr_chan = 1'b1;
    end

    AXI_RD_LAST_ARREADY :
    begin
      if( arready == 1'b0 )
      begin
                          next_state = AXI_RD_LAST_ARREADY;
      end
      else begin
	             clear_addr_chan = 1'b1;
                          next_state = AXI_RD_WAIT_TIL_NOT_EMPTY;  //AXI_RD_WAIT_TIL_4;
      end
    end

    default : next_state = AXI_RD_IDLE;
  endcase
end

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          read_addr_chan.arvalid <= 1'b0;
  else if( clear_addr_chan == 1'b1 )  read_addr_chan.arvalid <= 1'b0;
  else if( clock_addr_chan == 1'b1 )  read_addr_chan.arvalid <= 1'b1;
  else                                read_addr_chan.arvalid <= read_addr_chan.arvalid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          read_addr_chan.arid <= 'd0;
  else if( clear_addr_chan == 1'b1 )  read_addr_chan.arid <= 'd0;
  else if( clock_addr_chan == 1'b1 )  read_addr_chan.arid <= fifo_out_N;
  else                                read_addr_chan.arid <= read_addr_chan.arid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          read_addr_chan.araddr <= 'd0;
  else if( clear_addr_chan == 1'b1 )  read_addr_chan.araddr <= 'd0;
  else if( clock_addr_chan == 1'b1 )  read_addr_chan.araddr <= fifo_out_addr;
  else                                read_addr_chan.araddr <= read_addr_chan.araddr;
end

/*
always_comb
begin
    case( verify_semantics_cache_reg )
        3'h0 :                          read_addr_chan.aruser <= eRD_N_RDLINEI_RDCURR;
        3'h1 :                          read_addr_chan.aruser <= eRD_S_RDLINES_RDSHARED;
        3'H2 :                          read_addr_chan.aruser <= eRD_EM_RDLINEEM_RDOWN;
        default :                       read_addr_chan.aruser <= eRD_N_RDLINEI_RDCURR;
    endcase
end
*/

always_comb
begin
                                        read_addr_chan.aruser.do_not_send_d2hreq = 1'b0;

    case( verify_semantics_cache_reg )
        3'h0 :                          read_addr_chan.aruser.opcode <= eRD_I;
        3'h1 :                          read_addr_chan.aruser.opcode <= eRD_S;
        3'H2 :                          read_addr_chan.aruser.opcode <= eRD_EM;
        default :                       read_addr_chan.aruser.opcode <= eRD_I;
    endcase
end

always_comb
begin
    read_addr_chan.arlen        = 0;
    read_addr_chan.arsize       = esize_512;
    read_addr_chan.arburst      = eburst_INCR;
    read_addr_chan.arprot       = eprot_UNPRIV_NONSEC_DATA;    // ??????????
    read_addr_chan.arqos        = eqos_BEST_EFFORT;            // ??????????
    read_addr_chan.arcache      = ecache_ar_DEVICE_BUFFERABLE; // ??????????
    read_addr_chan.arlock       = elock_NORMAL;                // ??????????
    read_addr_chan.arregion     = 'd0;                         // ??????????
end



endmodule

