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

module alg_1a_create_packet
    import ccv_afu_pkg::*;
    import ccv_afu_alg1a_pkg::*;
(
  input clk,
  input reset_n,    // active low reset

  /* signals to/from ccv afu top-level FSM
  */
  input        enable,       // active high
  input [31:0] current_P,
  input [51:0] current_X,

  input alg1a_mode_enum mode,

  output logic busy,
  output logic set_to_busy,
  output logic set_to_not_busy,

  /*  signals to/from the execute response phase
  */
  input        execute_response_busy,      // active high

  output logic execute_response_start,

  /*  signals to/from the verify response phase
  */
  input        verify_response_busy,      // active high

  output logic verify_response_start,

  /*  signals from configuration and debug registers
  */
  input        force_disable_afu,                  // active high
  input [8:0]  NAI,                                // number address increments per set
  input [2:0]  pattern_size_reg,
  input [37:0] RAI,                                // address increment << 6
  input        single_transaction_per_set,         // active high

  /*  signals to/from FIFO
  */
  input        fifo_thresh,

  output logic [92:0] data_to_fifo,
  output logic        write_enable_to_fifo
);

/*   ================================================================================================
*/
typedef enum logic [2:0] {
  IDLE               = 3'd0,
  START              = 3'd1,
  WAIT_ON_N          = 3'd2,
  WAIT_ON_RESPONSES  = 3'd3,
  COMPLETE           = 3'd4
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

/*   ================================================================================================
*/
logic pipe_1_valid;
logic pipe_2_valid;
logic pipe_3_valid;

logic [8:0] pipe_1_N;
logic [8:0] pipe_2_N;
logic [8:0] pipe_3_N;

logic [31:0] pipe_1_P;
logic [51:0] pipe_2_YN;
logic [51:0] pipe_3_addr;
logic [31:0] pipe_2_RP;
logic [31:0] pipe_3_RP;

logic [31:0]  RP;
logic [511:0] ERP;

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= COMPLETE;
  else                                  state <= next_state;
end

/*   ================================================================================================
*/
always_comb
begin
  set_to_busy            = 1'b0;
  set_to_not_busy        = 1'b0;
  execute_response_start = 1'b0;
  verify_response_start  = 1'b0;

  case( state )
    IDLE :
    begin
      if( enable == 1'b1 )                  next_state = START;
      else                                  next_state = IDLE;

      if( enable == 1'b1 )                 set_to_busy = 1'b1;
    end

    START :
    begin
        if( mode == MODE_EXECUTE )
        begin
                                execute_response_start = 1'b1;
                                            next_state = WAIT_ON_N;
        end
        else if( mode == MODE_VERIFY_SC )
        begin
                                 verify_response_start = 1'b1;
                                            next_state = WAIT_ON_N;
        end
        else begin
                                            next_state = COMPLETE;
        end        
    end

    WAIT_ON_N :
    begin
        if( force_disable_afu == 1'b1 )     next_state = COMPLETE;
        else if( pipe_1_N < NAI )           next_state = WAIT_ON_N;
        else                                next_state = WAIT_ON_RESPONSES;
    end

    WAIT_ON_RESPONSES :
    begin
      if( force_disable_afu == 1'b1 )       next_state = COMPLETE;
      else if( mode == MODE_EXECUTE )
      begin
        if( execute_response_busy == 1'b1 ) next_state = WAIT_ON_RESPONSES;
        else                                next_state = COMPLETE;
      end
      else if( mode == MODE_VERIFY_SC )
      begin
        if( verify_response_busy == 1'b1 )  next_state = WAIT_ON_RESPONSES;
        else                                next_state = COMPLETE;
      end
      else                                  next_state = COMPLETE;
    end

    COMPLETE :
    begin
                                       set_to_not_busy = 1'b1;
                                            next_state = IDLE;
    end

    default :                               next_state = IDLE;
  endcase
end

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          busy <= 1'b0;
  else if( set_to_busy == 1'b1 )      busy <= 1'b1;
  else if( set_to_not_busy == 1'b1 )  busy <= 1'b0;
  else                                busy <= busy;
end

/*   ================================================================================================  pipe stage 1
*/
/*
 *  valid that starts the "packet is valid" through the pipeline
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid <= 1'b1;
  else if( busy == 1'b0 )                       pipe_1_valid <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid <= 1'b0; // only pulse valid once
  else if( fifo_thresh == 1'b1 )                pipe_1_valid <= 1'b0;
  else if( pipe_1_N < NAI )                     pipe_1_valid <= 1'b1;
  else                                          pipe_1_valid <= 1'b0;
end

/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_1_N <= 'd0;
  else if( set_to_busy == 1'b1 )      pipe_1_N <= 'd0;
  else if( busy == 1'b0 )             pipe_1_N <= 'd0;
  else if( fifo_thresh == 1 )         pipe_1_N <= pipe_1_N;
  else if( pipe_1_N < NAI )           pipe_1_N <= pipe_1_N + 'd1;
  else                                pipe_1_N <= pipe_1_N;
end

/* P is the pattern to be written. it increments by one for each address increment
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )     pipe_1_P  <= 'd0;
  else if( set_to_busy == 1'b1 ) pipe_1_P  <= current_P;
  else if( busy == 1'b0 )        pipe_1_P  <= 'd0;
  else if( fifo_thresh == 1'b1 ) pipe_1_P  <= pipe_1_P;
  else if( pipe_1_N < (NAI) )    pipe_1_P  <= pipe_1_P + 'd1;
  else                           pipe_1_P  <= pipe_1_P;
end

/*   ================================================================================================  pipe stage 2
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )   pipe_2_valid <= 1'b0;
  else if( busy == 1'b0 )      pipe_2_valid <= 1'b0;
  else                         pipe_2_valid <= pipe_1_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_2_N <= 'd0;
  else if( busy == 1'b0 )         pipe_2_N <= 'd0;
  else if( pipe_1_valid == 1'b0 ) pipe_2_N <= pipe_2_N;
  else                            pipe_2_N <= pipe_1_N;
end

/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_2_YN <= 'd0;
  else if( busy == 1'b0 )         pipe_2_YN <= 'd0;
  else if( pipe_1_valid == 1'b0 ) pipe_2_YN <= pipe_2_YN;
  else if( pipe_1_N == 'd0 )      pipe_2_YN <= 'd0;
  else                            pipe_2_YN <= pipe_2_YN + RAI;
end

/* PatternSize: Defines what size (in bytes) of P or Bto use starting from least 
   significant byte. As an example, if this is programmed to 3b011, only the lower 3 
   bytes of P and B registers will be used as the pattern. This will be programmed 
   consistently with the ByteMask field, for example, in the given example, the ByteMask 
   would always be in sets of three consecutive bytes
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_2_RP  <= 'd0;
  else if( busy == 1'b0 )              pipe_2_RP  <= 'd0;
  else if( pipe_1_valid == 1'b0 )      pipe_2_RP  <= pipe_2_RP;
  else if( pattern_size_reg == 3'd4 )  pipe_2_RP  <= pipe_1_P;
  else if( pattern_size_reg == 3'd2 )  pipe_2_RP  <= pipe_1_P[15:0];
  else if( pattern_size_reg == 3'd1 )  pipe_2_RP  <= pipe_1_P[7:0];
  else if( pattern_size_reg == 3'd0 )  pipe_2_RP  <= 'd0;
  else                                 pipe_2_RP  <= pipe_2_RP;
end

/*   ================================================================================================  pipe stage 3
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )   pipe_3_valid <= 1'b0;
  else if( busy == 1'b0 )      pipe_3_valid <= 1'b0;
  else                         pipe_3_valid <= pipe_2_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_3_N <= 'd0;
  else if( busy == 1'b0 )         pipe_3_N <= 'd0;
  else if( pipe_2_valid == 1'b0 ) pipe_3_N <= pipe_3_N;
  else                            pipe_3_N <= pipe_2_N;
end

/*
 *   add the ongoing address increment to the base address for the set
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_3_addr <= 'd0;
  else if( busy == 1'b0 )         pipe_3_addr <= 'd0;
  else if( pipe_2_valid == 1'b0 ) pipe_3_addr <= pipe_3_addr;
  else                            pipe_3_addr <= pipe_2_YN + current_X;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_3_RP  <= 'd0;
  else if( busy == 1'b0 )         pipe_3_RP  <= 'd0;
  else if( pipe_2_valid == 1'b0 ) pipe_3_RP  <= pipe_3_RP;
  else                            pipe_3_RP  <= pipe_2_RP;
end

/*   ================================================================================================
*/

//assign data_to_fifo = (mode == MODE_EXECUTE)    ? {pipe_3_N, pipe_3_addr, pipe_3_RP} :
//                     ((mode == MODE_VERIFY_SC ) ? {pipe_3_N, pipe_3_addr, 32'd0}     : 'd0 );

assign data_to_fifo = {pipe_3_N, pipe_3_addr, pipe_3_RP};

assign write_enable_to_fifo = pipe_3_valid;

endmodule



/*
typedef enum logic [1:0] {
  P1_IDLE          = 2'd0,
  P1_INCR          = 2'd1,
  P1_N_MET         = 2'd2,
  P1_HOLD_HIGH     = 2'd3
} pipe_1_fsm_enum;

pipe_1_fsm_enum   pipe_1_state;
pipe_1_fsm_enum   pipe_1_next_state;

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            pipe_1_state <= P1_IDLE;
  else if( force_disable_afu == 1'b1 )  pipe_1_state <= P1_IDLE;
  else                                  pipe_1_state <= pipe_1_next_state;
end

always_comb
begin
  case( pipe_1_state )
    P1_IDLE :
    begin
      if( set_to_busy == 1'b0 ) pipe_1_next_state <= P1_IDLE;
      else                      pipe_1_next_state <= P1_INCR;
    end

    P1_INCR :
    begin
           if( single_transaction_per_set == 1'b1 ) pipe_1_next_state <= P1_IDLE;
      else if( pipe_1_N < NAI )                     pipe_1_next_state <= P1_INCR;
      else                                          pipe_1_next_state <= P1_N_MET;
    end

    P1_N_MET :
    begin
           if( set_to_not_busy == 1'b1 ) pipe_1_next_state <= P1_IDLE;
      else if( fifo_full == 1'b0 )       pipe_1_next_state <= P1_N_MET;
      else                               pipe_1_next_state <= P1_HOLD_HIGH;
    end

    P1_HOLD_HIGH :
    begin
           if( set_to_not_busy == 1'b1 ) pipe_1_next_state <= P1_IDLE;
      else if( fifo_full == 1'b0 )       pipe_1_next_state <= P1_N_MET;
      else                               pipe_1_next_state <= P1_HOLD_HIGH;
    end

    default : pipe_1_next_state <= P1_IDLE;
  endcase
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )              pipe_1_valid <= 1'b0;
  else if( pipe_1_state == P1_INCR )      pipe_1_valid <= 1'b1;
  else if( pipe_1_state == P1_N_MET )     pipe_1_valid <= 1'b0;
  else if( pipe_1_state == P1_HOLD_HIGH ) pipe_1_valid <= 1'b1;
  else                                    pipe_1_valid <= pipe_1_valid;
end
*/
