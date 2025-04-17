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



`include "ccv_afu_globals.vh.iv"

/*
   grabbing from the environment variables
      ERROR_PATTERN_ENABLE
      ERROR_PATTERN_LOOP
      ERROR_PATTERN_SET
      ERROR_PATTERN_N
      ERROR_PATTERN_BYTE
      ERROR_PATTERN_BIT
   set by sourcing the script error_patterns_script.sh
*/

//import "DPI-C" function string getenv(input string env_name);

import "DPI-C" function string getenv(input string env_name);


module testing_inject_pattern
(
  input clk,
  input reset_n,

  input [7:0] i_loop,
  input [3:0] i_set,

  input [511:0] i_data,
  input [7:0]   i_id,
  input         i_valid,

  output logic [511:0] o_data
);

string env;

logic flip_bit;

int enable;
int loop;
int set;
int N;
int byte_i;
int bit_i;
int index;

`ifdef TJBB_SVUNIT
  initial
  begin
    env = getenv("ERROR_PATTERN_ENABLE");
    enable = env.atoi();
    env = getenv("ERROR_PATTERN_LOOP");
    loop = env.atoi();
    env = getenv("ERROR_PATTERN_SET");
    set = env.atoi();
    env = getenv("ERROR_PATTERN_N");
    N = env.atoi();
    env = getenv("ERROR_PATTERN_BYTE");
    byte_i = env.atoi();
    env = getenv("ERROR_PATTERN_BIT");
    bit_i = env.atoi();
    index = (byte_i * 8) + bit_i;
  end
`else
  initial
  begin
    if( $value$plusargs("ERROR_PATTERN_ENABLE=%d", enable) )
    begin
        if( $value$plusargs("ERROR_PATTERN_LOOP=%d", loop)   == 0 )  loop   = 0;
        if( $value$plusargs("ERROR_PATTERN_SET=%d",  set)    == 0 )  set    = 0;
        if( $value$plusargs("ERROR_PATTERN_N=%d",    N)      == 0 )  N      = 0;
        if( $value$plusargs("ERROR_PATTERN_BYTE=%d", byte_i) == 0 )  byte_i = 0;
        if( $value$plusargs("ERROR_PATTERN_BIT=%d",  bit_i)  == 0 )  bit_i  = 0;
    end
    else begin
      enable = 0;
      loop   = 0;
      set    = 0;
      N      = 0;
      byte_i = 0;
      bit_i  = 0;
    end
    index    = (byte_i * 8) + bit_i;
  end
`endif

assign flip_bit = i_data[index] ^ 1'b1;

always_comb
begin
         if( enable == 1'b0 )  o_data = i_data;
    else if( i_valid == 1'b0 ) o_data = i_data;
    else if( loop != i_loop )  o_data = i_data;
    else if( set != i_set )    o_data = i_data;
    else if( N != i_id )       o_data = i_data;
    else begin
      for( int i = 0 ; i < 512 ; i=i+1 )
      begin
        if( i == index )  o_data[i] = flip_bit;
        else              o_data[i] = i_data[i];
      end

/*              if( index == 10'd0 )   o_data = {i_data[511:1], flip_bit};
         else if( index == 10'd1 )   o_data = {i_data[511:2], flip_bit, i_data[0]};
         else if( index == 10'd511 ) o_data = {flip_bit, i_data[510:0]};
         else if( index == 10'd510 ) o_data = {i_data[511], flip_bit, i_data[509:0]};
         else                        o_data = {i_data[511:(index+1)], flip_bit, i_data[(index-1):0]};
*/
    end
end


logic done;

always_comb
begin
         if( reset_n == 1'b0 )   done <= 1'b0;
    else if( enable == 1'b0 )    done <= 1'b0;
    else if( ( i_valid == 1'b1 )
           & ( i_loop  == loop )
           & ( i_set   == set  )
           & ( i_id    == N    )
           )                     done <= 1'b1;
    else                         done <= 1'b0;
end




logic [511:0] data_changed;

always_comb
begin
       if( reset_n == 1'b0 ) data_changed <= 'd0;
  else if( done == 1'b1 )    data_changed <= i_data;
  else                       data_changed <= data_changed;
end


endmodule
