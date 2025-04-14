// (C) 2001-2023 Intel Corporation. All rights reserved.
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


// Copyright 2023 Intel Corporation.
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
//
// Logic Owner   : Josh Schabel
// Creation Date : April 2023
// Project       : T2IP
// Description   : convert axi to avmm
//
// Module exists under the assumption that LVF2 and OOORSP are defined
//    and OOORSP_MC_AXI2AVMM
//

module axi2avmm_bridge
  import afu_axi_if_pkg::*;
  import mc_axi_if_pkg::*;
  import cxlip_top_pkg::*;
#(
   parameter NUM_MC_CHANS = 2,
   parameter REQ_MDATA_BW = 512,
   parameter DATA_BW      = 512,
   parameter DATA_BE_BW   = 64,
  
   parameter FULL_ADDR_MSB = 51,
   parameter FULL_ADDR_LSB = 6,
   parameter CHAN_ADDR_MSB = 51,
   parameter CHAN_ADDR_LSB = 6,

   parameter REQFIFO_DEPTH_BW = 6,
   parameter ALTECC_INST_BW   = 32
)
(
  input logic ip_clk,    // coming from mc_top
  input logic ip_rst_n,  // active low
 
  /* AXI4 signals
   */
   input mc_axi_if_pkg::t_to_mc_axi4   [NUM_MC_CHANS-1:0] i_to_mc_axi4,
  output mc_axi_if_pkg::t_from_mc_axi4 [NUM_MC_CHANS-1:0] o_from_mc_axi4,

  /* AVMM signals to MC logic
   */
  output logic [NUM_MC_CHANS-1:0] o_avmm_read,
  output logic [NUM_MC_CHANS-1:0] o_avmm_write,
  output logic [NUM_MC_CHANS-1:0] o_avmm_write_poison,
  output logic [NUM_MC_CHANS-1:0] o_avmm_write_ras_sbe,
  output logic [NUM_MC_CHANS-1:0] o_avmm_write_ras_dbe,

  output logic [NUM_MC_CHANS-1:0][REQ_MDATA_BW-1:0]  o_avmm_req_mdata,
  output logic [NUM_MC_CHANS-1:0][DATA_BW-1:0]       o_avmm_writedata,
  output logic [NUM_MC_CHANS-1:0][DATA_BE_BW-1:0]    o_avmm_byteenable,
 
//`ifdef T2IP_ZSC7     // address aliasing needed for multi-slice & emif
`ifndef SINGLE_SLICE_ENV     // address aliasing needed for multi-slice & emif
  //output logic [NUM_MC_CHANS-1:0][CHAN_ADDR_MSB:CHAN_ADDR_LSB] o_avmm_address,
  output logic [NUM_MC_CHANS-1:0][FULL_ADDR_MSB:FULL_ADDR_LSB] o_avmm_address, 
`else
  output logic [NUM_MC_CHANS-1:0][FULL_ADDR_MSB:FULL_ADDR_LSB] o_avmm_address, 
`endif
 
  /* AVMM signals from MC logic
     Error Correction Code (ECC)
     Note *ecc_err_* are valid when iafu2cxlip_readdatavalid_eclk is active
   */
  input logic [NUM_MC_CHANS-1:0] i_avmm_read_poison,
  input logic [NUM_MC_CHANS-1:0] i_avmm_ecc_err_valid,
  input logic [NUM_MC_CHANS-1:0] i_avmm_readdatavalid,
  input logic [NUM_MC_CHANS-1:0] i_avmm_ready,
  //input logic [NUM_MC_CHANS-1:0] i_avmm_reqfifo_full,

  input logic [NUM_MC_CHANS-1:0][REQ_MDATA_BW-1:0]     i_avmm_rsp_mdata,
  input logic [NUM_MC_CHANS-1:0][DATA_BW-1:0]          i_avmm_readdata,
  //input logic [NUM_MC_CHANS-1:0][REQFIFO_DEPTH_BW-1:0] i_avmm_reqfifo_fill_level,

  input logic [NUM_MC_CHANS-1:0][ALTECC_INST_BW-1:0] i_avmm_ecc_err_corrected,
  input logic [NUM_MC_CHANS-1:0][ALTECC_INST_BW-1:0] i_avmm_ecc_err_syn_e,
  input logic [NUM_MC_CHANS-1:0][ALTECC_INST_BW-1:0] i_avmm_ecc_err_fatal,
  input logic [NUM_MC_CHANS-1:0][ALTECC_INST_BW-1:0] i_avmm_ecc_err_detected
);

// ================================================================================================
logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_RAC_ID_BW-1:0] rd_id_fifo_din;
logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_RAC_ID_BW-1:0] rd_id_fifo_dout;

logic [NUM_MC_CHANS-1:0][6:0] rd_id_fifo_usedw;

logic [NUM_MC_CHANS-1:0] rd_id_fifo_rd_enable;
logic [NUM_MC_CHANS-1:0] rd_id_fifo_wr_enable;
logic [NUM_MC_CHANS-1:0] rd_id_fifo_full;
logic [NUM_MC_CHANS-1:0] rd_id_fifo_almost_full;

logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_WAC_ID_BW-1:0] wr_id_in;
logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_WAC_ID_BW-1:0] wr_id_staged;

logic [NUM_MC_CHANS-1:0] wr_id_write_enable;

logic [NUM_MC_CHANS-1:0] send_write_response;

afu_axi_if_pkg::t_axi4_wr_addr_ready [NUM_MC_CHANS-1:0] awready;
afu_axi_if_pkg::t_axi4_wr_data_ready [NUM_MC_CHANS-1:0] wready;
afu_axi_if_pkg::t_axi4_rd_addr_ready [NUM_MC_CHANS-1:0] arready;
afu_axi_if_pkg::t_axi4_resp_encoding [NUM_MC_CHANS-1:0] bresp;	
afu_axi_if_pkg::t_axi4_resp_encoding [NUM_MC_CHANS-1:0] rresp;

// 定义b_resp和r_resp的结构
typedef struct packed {
    logic [mc_axi_if_pkg::MC_AXI_WRC_ID_BW-1:0] id;
    afu_axi_if_pkg::t_axi4_resp_encoding resp;
    logic valid;
    logic [mc_axi_if_pkg::MC_AXI_WRC_USER_BW-1:0] user;
} t_b_resp;

typedef struct packed {
    logic [mc_axi_if_pkg::MC_AXI_RRC_ID_BW-1:0] id;
    logic [mc_axi_if_pkg::MC_AXI_RRC_DATA_BW-1:0] data;
    afu_axi_if_pkg::t_axi4_resp_encoding resp;
    logic valid;
    logic last;
    logic [mc_axi_if_pkg::MC_AXI_WRC_USER_BW-1:0] user;
} t_r_resp;

// 使用自定义结构体类型
t_b_resp [NUM_MC_CHANS-1:0] b_resp;
t_r_resp [NUM_MC_CHANS-1:0] r_resp;

// 删除未使用的变量声明
//logic [NUM_MC_CHANS-1:0] bvalid;
//logic [NUM_MC_CHANS-1:0] rvalid;
//logic [NUM_MC_CHANS-1:0] rlast;

logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_WAC_ID_BW-1:0] awid;
logic [NUM_MC_CHANS-1:0][mc_axi_if_pkg::MC_AXI_RAC_ID_BW-1:0] arid;

// ================================================================================================
genvar outsigs;
generate for( outsigs = 0 ; outsigs < NUM_MC_CHANS ; outsigs=outsigs+1 )
begin : gen_axi_output_signals
  always_comb
  begin
    b_resp[outsigs].id = awid[outsigs];
    b_resp[outsigs].resp = bresp[outsigs];
    b_resp[outsigs].user = 'd0;
    
    o_from_mc_axi4[outsigs].ready = awready[outsigs];
    
    o_from_mc_axi4[outsigs].b = b_resp[outsigs];
  end
end
endgenerate

// ================================================================================================
/* handle the axi request channel ready signals - always ready unless there's no room n the request fifo
 */
genvar genarready;
generate for( genarready = 0 ; genarready < NUM_MC_CHANS ; genarready=genarready+1 )
begin : gen_axi4_arready
  always_comb
  begin
         if( rd_id_fifo_almost_full[genarready] == 1'b1 ) arready[genarready] = 1'b0;
    else if( i_avmm_ready[genarready] == 1'b0 )           arready[genarready] = 1'b0; // mc not ready
    else                                                  arready[genarready] = 1'b1;
  end
end
endgenerate

genvar genawready;
generate for( genawready = 0 ; genawready < NUM_MC_CHANS ; genawready=genawready+1 )
begin : gen_axi4_awready
  always_comb
  begin
    if( i_avmm_ready[genawready] == 1'b0 ) awready[genawready] = 1'b0; // mc not ready
    else                                   awready[genawready] = 1'b1;  
  end
end
endgenerate

genvar genwready;
generate for( genwready = 0 ; genwready < NUM_MC_CHANS ; genwready=genwready+1 )
begin : gen_axi4_wready
  always_comb
  begin
    if( i_avmm_ready[genwready] == 1'b0 ) wready[genwready] = 1'b0; // mc not ready
    else                                  wready[genwready] = 1'b1;  
  end
end
endgenerate

genvar genid;
generate for( genid = 0 ; genid < NUM_MC_CHANS ; genid=genid+1 )
begin : gen_axi4_ids
  always_ff @( posedge ip_clk )
  begin
    awid[genid] <= i_to_mc_axi4[genid].aw.id;
    arid[genid] <= i_to_mc_axi4[genid].aw.id;
  end
end
endgenerate

// ================================================================================================
/* map the AXI4 request channels to AVMM with no staging
 */
genvar genavmm;
generate for( genavmm = 0 ; genavmm < NUM_MC_CHANS ; genavmm=genavmm+1 )
begin : gen_avmm_out
  always_comb
  begin
          o_avmm_address[genavmm] =  'd0;
            o_avmm_write[genavmm] = 1'b0;
     o_avmm_write_poison[genavmm] = 1'b0;
    o_avmm_write_ras_sbe[genavmm] = 1'b0;
    o_avmm_write_ras_dbe[genavmm] = 1'b0;
        o_avmm_writedata[genavmm] =  'd0;
       o_avmm_byteenable[genavmm] =  'd0;
        o_avmm_req_mdata[genavmm] =  'd0;
		     o_avmm_read[genavmm] = 1'b0;		
			 
                wr_id_in[genavmm] =  'd0;
      wr_id_write_enable[genavmm] = 1'b0;
          rd_id_fifo_din[genavmm] =  'd0;
    rd_id_fifo_wr_enable[genavmm] = 1'b0;    

    if( i_avmm_ready[genavmm] == 1'b1 ) // the mc is ready
	begin
	  if( ( i_to_mc_axi4[genavmm].aw.valid == 1'b1 ) // there's a write request && awready
		& ( awready[genavmm] == 1'b1 )
		)
      begin
                o_avmm_write[genavmm] = 1'b1;
        o_avmm_write_ras_sbe[genavmm] = 1'b0;
        o_avmm_write_ras_dbe[genavmm] = 1'b0;
            o_avmm_writedata[genavmm] = i_to_mc_axi4[genavmm].w.data;
           o_avmm_byteenable[genavmm] = i_to_mc_axi4[genavmm].w.strb;
         o_avmm_write_poison[genavmm] = i_to_mc_axi4[genavmm].w.user;
                    wr_id_in[genavmm] = i_to_mc_axi4[genavmm].aw.id;
          wr_id_write_enable[genavmm] = 1'b1;			
				  
        //`ifdef T2IP_ZSC7   // address aliasing needed for multi-slice & emif
        `ifndef SINGLE_SLICE_ENV     // address aliasing needed for multi-slice & emif
          // o_avmm_address[genavmm] = i_to_mc_axi4[genavmm].awaddr[CHAN_ADDR_MSB:CHAN_ADDR_LSB];
           o_avmm_address[genavmm] = {'0, i_to_mc_axi4[genavmm].aw.addr[(cxlip_top_pkg::CXLIP_CHAN_ADDR_MSB):(cxlip_top_pkg::CXLIP_CHAN_ADDR_LSB)] }; //[ADDR_MSB:ADDR_LSB]; // ???
           	   
        `else  
           o_avmm_address[genavmm] = i_to_mc_axi4[genavmm].aw.addr[FULL_ADDR_MSB:FULL_ADDR_LSB];
        `endif         
      end
      /* there's a read request && arready 
	     arready can be deasserted if rd_id_fifo_almost_full (too many read ids outstanding)
	   */
      else if( ( i_to_mc_axi4[genavmm].aw.valid == 1'b1 )
		     & (arready[genavmm] == 1'b1 )
		     )
      begin   
	             o_avmm_read[genavmm] = 1'b1;
	          rd_id_fifo_din[genavmm] = i_to_mc_axi4[genavmm].aw.id;
	    rd_id_fifo_wr_enable[genavmm] = 1'b1;
				
        //`ifdef T2IP_ZSC7   // address aliasing needed for multi-slice & emif
        `ifndef SINGLE_SLICE_ENV     // address aliasing needed for multi-slice & emif
          // o_avmm_address[genavmm] = i_to_mc_axi4[genavmm].araddr[CHAN_ADDR_MSB:CHAN_ADDR_LSB];
	     o_avmm_address[genavmm] = {'0, i_to_mc_axi4[genavmm].aw.addr[(cxlip_top_pkg::CXLIP_CHAN_ADDR_MSB):(cxlip_top_pkg::CXLIP_CHAN_ADDR_LSB)] }; //[ADDR_MSB:ADDR_LSB]; // ???
  
        `else  
           o_avmm_address[genavmm] = i_to_mc_axi4[genavmm].aw.addr[FULL_ADDR_MSB:FULL_ADDR_LSB];
        `endif  
      end
    end   // end if i_avmm_ready
  end     // end always
end       // end for
endgenerate

// ================================================================================================
genvar genwrid;
generate for( genwrid = 0 ; genwrid < NUM_MC_CHANS ; genwrid=genwrid+1 )
begin : gen_wr_id_staging
  always_ff @( posedge ip_clk )
  begin
           if( ip_rst_n == 1'b0 )                    wr_id_staged[genwrid] <= 'd0;
      else if( wr_id_write_enable[genwrid] == 1'b1 ) wr_id_staged[genwrid] <= wr_id_in[genwrid];
      else                                           wr_id_staged[genwrid] <= wr_id_staged[genwrid];
  end
end
endgenerate

// ================================================================================================
genvar gensendwr;
generate for( gensendwr = 0 ; gensendwr < NUM_MC_CHANS ; gensendwr=gensendwr+1 )
begin : gen_wr_rsp_staging
  always_ff @( posedge ip_clk )
  begin
           if( ip_rst_n == 1'b0 )                      send_write_response[gensendwr] <= 1'b0;
      else if( wr_id_write_enable[gensendwr] == 1'b1 ) send_write_response[gensendwr] <= 1'b1;
      else                                             send_write_response[gensendwr] <= 1'b0;
  end
end
endgenerate

// ================================================================================================
genvar genwrrsp;
generate for( genwrrsp = 0 ; genwrrsp < NUM_MC_CHANS ; genwrrsp=genwrrsp+1 )
begin : gen_axi_signals_to_ip_wr  // map the AVMM signals to AXI write response
  always_comb
  begin
    // 初始化b_resp结构体
    b_resp[genwrrsp].id = 'd0;
    b_resp[genwrrsp].resp = eresp_OKAY;
    b_resp[genwrrsp].valid = 1'b0;
    b_resp[genwrrsp].user = 'd0;

    if( send_write_response[genwrrsp] == 1'b1 )
    begin
        b_resp[genwrrsp].id = wr_id_staged[genwrrsp];
        b_resp[genwrrsp].valid = 1'b1;
    end
  end
end
endgenerate

// ================================================================================================
genvar genrdrsp;
generate for( genrdrsp = 0 ; genrdrsp < NUM_MC_CHANS ; genrdrsp=genrdrsp+1 )
begin : gen_axi_signals_to_ip_rd  // map the AVMM signals to AXI read response
  always_comb
  begin
    // 初始化r_resp结构体
    r_resp[genrdrsp].id = rd_id_fifo_dout[genrdrsp];
    r_resp[genrdrsp].data = i_avmm_readdata[genrdrsp];
    r_resp[genrdrsp].resp = eresp_OKAY;
    r_resp[genrdrsp].valid = 1'b0;
    r_resp[genrdrsp].user = 'd0;
    r_resp[genrdrsp].last = 1'b0;

    rd_id_fifo_rd_enable[genrdrsp] = 1'b0;

    if( i_avmm_readdatavalid[genrdrsp] == 1'b1 )
    begin
        r_resp[genrdrsp].valid = 1'b1;
        r_resp[genrdrsp].last = 1'b1;
        r_resp[genrdrsp].user = i_avmm_read_poison[genrdrsp];

        rd_id_fifo_rd_enable[genrdrsp] = 1'b1;
    end
  end  // end always
end    // end for
endgenerate

// ================================================================================================
/* Handle the read IDs - for AVMM, all transactions go out in-order of arrival
 */
genvar genfifo;
generate for( genfifo = 0 ; genfifo < NUM_MC_CHANS ; genfifo=genfifo+1 )
begin : gen_mc0_readID_fifo

  assign rd_id_fifo_almost_full[genfifo] = ( rd_id_fifo_usedw[genfifo] >= 'd120 );

  fifo_12b_128w_show_ahead     HdmReadIDAttrFifo
  (
     .clock( ip_clk ),
     .aclr( ~ip_rst_n ),
     .rdreq( rd_id_fifo_rd_enable[genfifo] ),
     .wrreq( rd_id_fifo_wr_enable[genfifo] ),
     .data(  rd_id_fifo_din[genfifo] ),
     .q(     rd_id_fifo_dout[genfifo] ),
     .full(  rd_id_fifo_full[genfifo] ),
     .usedw( rd_id_fifo_usedw[genfifo] ),
     .empty( )
  );

end
endgenerate

// ================================================================================================
endmodule
