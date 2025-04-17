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

module mwae_config_check
    import ccv_afu_pkg::*;
(
  input clk,
  input reset_n,
  input i_enable,  // active high, from mwae top level fsm

  /*  signals from configuration and debug registersre
  */
  input [2:0]  algorithm_reg,
  input [2:0]  execute_read_semantics_cache_reg,
  input [2:0]  interface_protocol_reg,
  input [2:0]  pattern_size_reg,
  input [51:0] start_address_reg,
  input [2:0]  verify_read_semantics_cache_reg,
  input [3:0]  write_semantics_cache_reg,

  output config_check_t  o_config_errors
);

logic illegal_protocol_broken;

always_comb
begin
  case( interface_protocol_reg )
    `ifdef SUPPORT_CXL_IO
           3'b001 :      illegal_protocol_broken = 1'b0;
    `endif
    `ifdef SUPPORT_CXL_CACHE
           3'b010 :      illegal_protocol_broken = 1'b0;
    `endif
    `ifdef SUPPORT_CXL_IO
      `ifdef SUPPORT_CXL_CACHE
              3'b100 :   illegal_protocol_broken = 1'b0;
      `endif
    `endif
    default :            illegal_protocol_broken = 1'b1;
  endcase
end

logic illegal_protocol;

always_comb
begin
       if( reset_n == 1'b0 )                illegal_protocol = 1'b0;
  else if( interface_protocol_reg == 3'd0 ) illegal_protocol = 1'b1;  // PCIe mode
  else if( interface_protocol_reg == 3'd1 ) illegal_protocol = 1'b1;  // CXL.io only
  else if( interface_protocol_reg == 3'd2 ) illegal_protocol = 1'b0;  // CXL.cache only
  else if( interface_protocol_reg == 3'd4 ) illegal_protocol = 1'b1;  // CXL.cache & CXL.io
  else                                      illegal_protocol = 1'b1;  // not supported
end

logic illegal_wsc_broken;

always_comb
begin
  case( write_semantics_cache_reg )
    `ifdef INC_AC_WSC_0
           4'h0 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_1
           4'h1 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_2
           4'h2 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_3
           4'h3 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_4
           4'h4 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_5
           4'h5 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_6
           4'h6 :    illegal_wsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_WSC_7
           4'h7 :    illegal_wsc_broken = 1'b0;
    `endif
           default : illegal_wsc_broken = 1'b1;
  endcase
end

logic illegal_wsc;

always_comb
begin
       if( reset_n == 1'b0 )                   illegal_wsc = 1'b0;
  else if( write_semantics_cache_reg == 4'd0 ) illegal_wsc = 1'b0;  // ItoMWr with CleanEvict
  else if( write_semantics_cache_reg == 4'd1 ) illegal_wsc = 1'b1;  // MemWr with CleanEvictNoData
  else if( write_semantics_cache_reg == 4'd2 ) illegal_wsc = 1'b0;  // DirtyEvict
  else if( write_semantics_cache_reg == 4'd3 ) illegal_wsc = 1'b0;  // WOWrInv
  else if( write_semantics_cache_reg == 4'd4 ) illegal_wsc = 1'b0;  // WOWrInVF
  else if( write_semantics_cache_reg == 4'd5 ) illegal_wsc = 1'b0;  // WrInv
  else if( write_semantics_cache_reg == 4'd6 ) illegal_wsc = 1'b1;  // ClFlush
  else if( write_semantics_cache_reg == 4'd7 ) illegal_wsc = 1'b0;  // any CXL.cache supported opcode
  else                                         illegal_wsc = 1'b1;  // not supported
end

logic illegal_rsec_broken;

always_comb
begin
  case( execute_read_semantics_cache_reg )
    `ifdef INC_AC_ERSC_0
           3'b000 :     illegal_rsec_broken = 1'b0;
    `endif
    `ifdef INC_AC_ERSC_1
           3'b001 :     illegal_rsec_broken = 1'b0;
    `endif
    `ifdef INC_AC_ERSC_2
           3'b010 :     illegal_rsec_broken = 1'b0;
    `endif
    `ifdef INC_AC_ERSC_4
           3'b100 :     illegal_rsec_broken = 1'b0;
    `endif
           default :    illegal_rsec_broken = 1'b1;
  endcase
end

logic illegal_rsec;

always_comb
begin
       if( reset_n == 1'b0 )                          illegal_rsec = 1'b0;
  else if( execute_read_semantics_cache_reg == 4'd0 ) illegal_rsec = 1'b0;  // RdOwn
  else if( execute_read_semantics_cache_reg == 4'd1 ) illegal_rsec = 1'b1;  // RdAny
  else if( execute_read_semantics_cache_reg == 4'd2 ) illegal_rsec = 1'b0;  // RdOwnNoData
  else if( execute_read_semantics_cache_reg == 4'd4 ) illegal_rsec = 1'b0;  // any CXL.cache supported opcode
  else                                                illegal_rsec = 1'b1;  // not supported
end

logic illegal_vrsc_broken;

always_comb
begin
  case( verify_read_semantics_cache_reg )
    `ifdef INC_AC_VRSC_0
           3'b000 :    illegal_vrsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_VRSC_1
           3'b001 :    illegal_vrsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_VRSC_2
           3'b010 :    illegal_vrsc_broken = 1'b0;
    `endif
    `ifdef INC_AC_VRSC_4
           3'b100 :    illegal_vrsc_broken = 1'b0;
    `endif
           default :   illegal_vrsc_broken = 1'b1;
  endcase
end

logic illegal_vrsc;

always_comb
begin
       if( reset_n == 1'b0 )                         illegal_vrsc = 1'b0;
  else if( verify_read_semantics_cache_reg == 4'd0 ) illegal_vrsc = 1'b0;  // RdCurr
  else if( verify_read_semantics_cache_reg == 4'd1 ) illegal_vrsc = 1'b0;  // RdShared
  else if( verify_read_semantics_cache_reg == 4'd2 ) illegal_vrsc = 1'b0;  // RdOwn
  else if( verify_read_semantics_cache_reg == 4'd4 ) illegal_vrsc = 1'b1;  // RdAny
  else                                               illegal_vrsc = 1'b1;  // not supported
end

logic illegal_pattern_size;

always_comb
begin
  case( pattern_size_reg )
        3'd1 :       illegal_pattern_size = 1'b0;
        3'd2 :       illegal_pattern_size = 1'b0;
        3'd4 :       illegal_pattern_size = 1'b0;
        default :    illegal_pattern_size = 1'b1;
  endcase
end

logic illegal_addr;

always_comb
begin
  case( pattern_size_reg )
        3'd2 :    illegal_addr = (start_address_reg[0]   != 1'b0);
        3'd4 :    illegal_addr = (start_address_reg[1:0] != 2'b00);
        default : illegal_addr = 1'b0;
  endcase
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )  o_config_errors <= 'd0;
  else if( i_enable == 1'b0 ) o_config_errors <= o_config_errors;
  else begin
       o_config_errors.illegal_pattern_size_value           <= illegal_pattern_size;
       o_config_errors.illegal_read_semantics_verify_value  <= illegal_vrsc;
       o_config_errors.illegal_read_semantics_execute_value <= illegal_rsec;
       o_config_errors.illegal_write_semantics_value        <= illegal_wsc;
       o_config_errors.illegal_protocol_value               <= illegal_protocol;
       o_config_errors.illegal_base_address                 <= illegal_addr;
  end
end


endmodule
