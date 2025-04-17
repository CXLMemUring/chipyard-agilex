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
import rtlgen_pkg_v12::*;

module ccv_afu_csr_avmm_slave(
 
// AVMM Slave Interface
input                 clk,
input                 reset_n,
input         [63:0]  writedata,
input                 read,
input                 write,
input         [7:0]   byteenable,
output  logic [63:0]  readdata,
output  logic         readdatavalid,
input         [21:0]  address,
output  logic         waitrequest,

//Target Register Access Interface
output         rtlgen_pkg_v12::cfg_req_64bit_t treg_req,
input          rtlgen_pkg_v12::cfg_ack_64bit_t treg_ack

);
enum int unsigned { IDLE = 0, REQ = 2, ACK = 4 } state, next_state;


logic [3:0]  treg_opcode;
logic [47:0] treg_address;
logic [7:0]  treg_be;
logic [63:0] treg_data;
logic        data_valid;
logic        data_wait  ;


always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin 
                   if( write | read) begin
                       next_state = REQ;
                   end
                   else begin
                       next_state = IDLE;
                   end 
                end
      REQ     : begin
                   if (treg_ack.read_valid | treg_ack.write_valid) begin
                      next_state = ACK;
                   end
                   else begin
                      next_state = REQ;
                   end 
                end 
      ACK     : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end



always_comb begin
   case(state)
   IDLE    : begin
               data_valid  = 1'b0;
               data_wait   = 1'b1;
               
             end
   REQ     : begin 
               data_valid  = 1'b1;
               data_wait   = 1'b1; 
             end
   ACK     : begin 
               data_valid  = 1'b0;
               data_wait   = 1'b0; 
             end
   default : begin 
                data_valid = 1'b0;
                data_wait  = 1'b1;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

always_ff@(posedge clk) begin
   if(~reset_n) begin
      treg_opcode    <= 4'h0;
      treg_address   <= 32'h0;
      treg_be        <= 8'h0;
      treg_data      <= 64'h0;
      readdata       <= 64'h0;
      readdatavalid  <= 1'b0;
   end
   else begin
      treg_opcode    <= {1'b0,address[21],1'b0,write};
      treg_address   <= {27'd0,address[20:0]};
      treg_be        <=  byteenable[7:0];
      treg_data      <=  writedata;
      readdata       <= treg_ack.data;
      readdatavalid  <= treg_ack.read_valid;
   end
end


assign treg_req.valid   = data_valid;
assign treg_req.addr    = treg_address;
assign treg_req.be      = treg_be;
assign treg_req.bar     = 3'd0;
assign treg_req.fid     = 8'd0;
assign treg_req.opcode  = rtlgen_pkg_v12::cfg_opcode_t'(treg_opcode);

assign treg_req.sai     = 8'h3f;
assign treg_req.data    = treg_data;
assign waitrequest = data_wait;

endmodule
