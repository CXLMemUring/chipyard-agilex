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

module alg_1a_poison_injection
    import ccv_afu_alg1a_pkg::*;
(
  input clk, 
  input reset_n,
  input poison_injection_start,
  input force_disable_afu,
  input afu_busy,
  input execute_busy,

  /*  to/from alg 1a execute phase
  */
  output logic alg_1a_inject_poison,

  input  alg1a_exe_axi_write_fsm_enum  alg_1a_axi_fsm_state,
  
  /* going to cfg registers
  */
  output logic poison_injection_busy
);

/* =======================================================================================
*/
typedef enum logic [3:0] {
  IDLE                   = 4'd0,
  START                  = 4'd1,
  CHECK_AFU_BUSY         = 4'd2,
  CHECK_EXECUTE_BUSY     = 4'd3,
  CHECK_AXI_FSM_STATE    = 4'd4,
  START_INJECTION        = 4'd5,
  STOP_INJECTION         = 4'd6,
  SET_NOT_BUSY           = 4'd7,
  WAIT_ON_SOFTWARE       = 4'd8,
  PAUSE0                 = 4'd9,
  PAUSE1                 = 4'd10,
  PAUSE2                 = 4'd11,
  PAUSE3                 = 4'd12,
  PAUSE4                 = 4'd13
} fsm_enum;

fsm_enum    state;
fsm_enum    next_state;

/* =======================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           state <= IDLE;
  else if( force_disable_afu == 1'b1 ) state <= IDLE; 
  else                                 state <= next_state;
end

/* =======================================================================================
*/
logic set_busy_high;
logic set_busy_low;
logic set_injection_high;
logic set_injection_low;


always_comb
begin
  set_busy_high = 1'b0;
  set_busy_low  = 1'b0;
  set_injection_high = 1'b0;
  set_injection_low  = 1'b0;

  case( state )
    IDLE :
    begin
      if( poison_injection_start == 1'b0 )    next_state = IDLE;
      else                                    next_state = START;
    end

    START :
    begin
                                           set_busy_high = 1'b1;
                                              next_state = CHECK_AFU_BUSY;
    end

    CHECK_AFU_BUSY : 
    begin
      if( afu_busy == 1'b0 )                  next_state = CHECK_AFU_BUSY;  // afu is not running, wait for it to
      else                                    next_state = CHECK_EXECUTE_BUSY;
    end

    CHECK_EXECUTE_BUSY :
    begin
      if( execute_busy == 1'b0 )              next_state = CHECK_EXECUTE_BUSY; // wait on execute to be busy
      else                                    next_state = CHECK_AXI_FSM_STATE;
    end

    CHECK_AXI_FSM_STATE :   // catch the axi write fsm when there is packets sending
    begin
           if( alg_1a_axi_fsm_state == AXI_WR_FIRST_AWREADY ) next_state <= START_INJECTION;
      else if( alg_1a_axi_fsm_state == AXI_WR_NEXT_AWVALID )  next_state <= START_INJECTION;
      else if( alg_1a_axi_fsm_state == AXI_WR_NEXT_AWREADY )  next_state <= START_INJECTION;
      else                                                    next_state <= CHECK_AXI_FSM_STATE;  // wait on traffic
    end

    START_INJECTION :
    begin
                                      set_injection_high = 1'b1;
                                              next_state = PAUSE0;
    end

    PAUSE0 :                                  next_state = PAUSE3;

    PAUSE1 :                                  next_state = PAUSE2;

    PAUSE2 :                                  next_state = PAUSE3;

    PAUSE3 :                                  next_state = PAUSE4;

    PAUSE4 :                                  next_state = STOP_INJECTION;

    STOP_INJECTION :
    begin
                                       set_injection_low = 1'b1;
                                              next_state = SET_NOT_BUSY;
    end

    SET_NOT_BUSY :
    begin
                                            set_busy_low = 1'b1;
                                              next_state = WAIT_ON_SOFTWARE;
    end

    WAIT_ON_SOFTWARE :
    begin
      if( poison_injection_start == 1'b1 )    next_state = WAIT_ON_SOFTWARE;
      else                                    next_state = IDLE;
    end

    default :                                 next_state = IDLE;
  endcase
end

/* =======================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )       poison_injection_busy <= 1'b0;
  else if( set_busy_high == 1'b1 ) poison_injection_busy <= 1'b1;
  else if( set_busy_low  == 1'b1 ) poison_injection_busy <= 1'b0;
  else                             poison_injection_busy <= poison_injection_busy;
end

/* =======================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            alg_1a_inject_poison <= 1'b0;
  else if( set_injection_high == 1'b1 ) alg_1a_inject_poison <= 1'b1;
  else if( set_injection_low  == 1'b1 ) alg_1a_inject_poison <= 1'b0;
  else                                  alg_1a_inject_poison <= alg_1a_inject_poison;
end


endmodule
