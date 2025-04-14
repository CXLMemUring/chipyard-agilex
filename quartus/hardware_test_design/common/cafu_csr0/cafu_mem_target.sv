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

module cafu_mem_target 
  import afu_axi_if_pkg::*;
  import tmp_cafu_csr0_cfg_pkg::*;
  import cafu_mem_target_pkg::*;
(
        input  logic                    clk,
        input  logic                    rst,
        
        input   t_axi4_wr_addr_ch      mwae_axi_aw,
        input   t_axi4_wr_data_ch      mwae_axi_w,
        output  t_axi4_wr_resp_ch      mwae_axi_b,
        output  t_axi4_wr_addr_ready   mwae_axi_awready,
        output  t_axi4_wr_data_ready   mwae_axi_wready,
        input   t_axi4_wr_resp_ready   mwae_axi_bready,
        
        input   t_axi4_rd_addr_ch      mwae_axi_ar,
        output  t_axi4_rd_resp_ch      mwae_axi_r,
        output  t_axi4_rd_addr_ready   mwae_axi_arready,
        input   t_axi4_rd_resp_ready   mwae_axi_rready,
        
        output  t_axi4_wr_addr_ch      cafu_axi_aw,
        output  t_axi4_wr_data_ch      cafu_axi_w,
        input   t_axi4_wr_resp_ch      cafu_axi_b, 
        input   t_axi4_wr_addr_ready   cafu_axi_awready,
        input   t_axi4_wr_data_ready   cafu_axi_wready,
        output  t_axi4_wr_resp_ready   cafu_axi_bready,        
        
        output  t_axi4_rd_addr_ch      cafu_axi_ar,
        input   t_axi4_rd_resp_ch      cafu_axi_r,
        input   t_axi4_rd_addr_ready   cafu_axi_arready,
        output  t_axi4_rd_resp_ready   cafu_axi_rready,        
        
        //cafu_csr0_cfg inputs
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_GBL_CTRL_t      hdm_dec_gbl_ctrl,
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_CTRL_t          hdm_dec_ctrl,    
        input   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1HIGH_t    dvsec_fbrange1high,
        input   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1LOW_t     dvsec_fbrange1low,
        input   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZHIGH_t  fbrange1_sz_high,
        input   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZLOW_t   fbrange1_sz_low,
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASEHIGH_t      hdm_dec_basehigh,
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASELOW_t       hdm_dec_baselow,
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZEHIGH_t      hdm_dec_sizehigh,
        input   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZELOW_t       hdm_dec_sizelow
    );

/* internal signals begin */
    cafu_mem_target_pkg::hdm_mem_base_t        fme_hdm_mem_base;
    cafu_mem_target_pkg::Cl_Addr_t             axi_raddr, axi_waddr;
    logic                                      axi_rtarget_hdm, axi_wtarget_hdm;
    t_axi4_wr_addr_ch                          axi_aw, axi_awQ; 
    t_axi4_wr_data_ch                          axi_w, axi_wQ;
    t_axi4_wr_resp_ch                          axi_b, axi_bQ;    
    t_axi4_rd_addr_ch                          axi_ar, axi_arQ; 
    t_axi4_rd_resp_ch                          axi_r, axi_rQ;
    logic                                      axi_awready, axi_wready, axi_bready, axi_arready, axi_rready;
/* internal signals end */


/* Functional Logic begin */
    assign force_hardcoded = 0;
    assign axi_raddr = mwae_axi_ar.araddr[51:6];
    assign axi_waddr = mwae_axi_aw.awaddr[51:6]; 
    
    
    always_ff @(posedge clk) begin
      if (hdm_dec_gbl_ctrl.dec_enable)
        begin
          fme_hdm_mem_base.Addr <= {hdm_dec_basehigh.mem_base_high[CL_ADDR_MSB-32:0], hdm_dec_baselow.mem_base_low};
          fme_hdm_mem_base.Size <= {hdm_dec_sizehigh.mem_size_high[CL_ADDR_MSB-32:0], hdm_dec_sizelow.mem_size_low};
          fme_hdm_mem_base.IW   <= hdm_dec_ctrl.interleave_ways;
          fme_hdm_mem_base.IG   <= hdm_dec_ctrl.interleave_granularity;
        end
      else
        begin
          fme_hdm_mem_base.Addr <= {dvsec_fbrange1high.memory_base_high[CL_ADDR_MSB-32:0], dvsec_fbrange1low.memory_base_low};
          fme_hdm_mem_base.Size <= {fbrange1_sz_high.memory_size[CL_ADDR_MSB-32:0], fbrange1_sz_low.memory_size_low};
          fme_hdm_mem_base.IW   <= 4'b0000;
          fme_hdm_mem_base.IG   <= 4'b0000;
        end
    end
    
    
    //user csr to decode target for axi channels
    assign axi_rtarget_hdm = cafu_mem_target_pkg::fabric_target_dcd_f(axi_raddr,fme_hdm_mem_base);
    assign axi_wtarget_hdm = cafu_mem_target_pkg::fabric_target_dcd_f(axi_waddr,fme_hdm_mem_base);  
    
    
    //write channels begin
    always_comb
    begin
        // 临时变量存储awuser
        logic [$bits(axi_aw.awuser)-1:0] tmpuser_aw;
        tmpuser_aw = mwae_axi_aw.awuser;
        
        // 复制所有字段
        axi_aw = mwae_axi_aw;
        
        // 更新awuser值，确保target_hdm位被正确设置
        // 注意：这里假设target_hdm是结构体中的最高位
        if (axi_wtarget_hdm) begin
            tmpuser_aw |= (1 << ($bits(axi_aw.awuser)-1));
        end else begin
            tmpuser_aw &= ~(1 << ($bits(axi_aw.awuser)-1));
        end
        
        // 将修改后的值赋回
        axi_aw.awuser = tmpuser_aw;
    end

    assign axi_awready         = cafu_axi_awready;
    assign mwae_axi_awready    = (~axi_awQ.awvalid || axi_awready); //ready when empty or moving
    assign cafu_axi_aw         = axi_awQ;
    always_ff @(posedge clk) begin 
        if (rst) begin
            axi_awQ.awvalid <= 0;
        end else begin
            //if (empty or moving), accept input
            if ((~axi_awQ.awvalid && axi_aw.awvalid) || (axi_awQ.awvalid && axi_awready)) begin
                axi_awQ <= axi_aw;
            end 
        end  
    end 
  
    
    assign axi_wready          = cafu_axi_wready;
    assign mwae_axi_wready     = (~axi_wQ.wvalid || axi_wready);    //ready when empty or moving
    assign axi_w               = mwae_axi_w;
    assign cafu_axi_w          = axi_wQ; 
    always_ff @(posedge clk) begin
        if (rst) begin
            axi_wQ.wvalid   <= 0;
        end else begin
            //if (empty or moving), accept input
            if ( (~axi_wQ.wvalid && axi_w.wvalid) || (axi_wQ.wvalid && axi_wready)) begin
                axi_wQ <= axi_w;
            end 
        end  
    end   
       
    assign axi_bready          = mwae_axi_bready;
    assign cafu_axi_bready     = (~axi_bQ.bvalid || axi_bready);    //ready when empty or moving
    assign axi_b               = cafu_axi_b;
    assign mwae_axi_b          = axi_bQ;
    always_ff @(posedge clk) begin
        if (rst) begin
            axi_bQ.bvalid   <= 0;
        end else begin
            //if (empty or moving), accept input
            if ((~axi_bQ.bvalid && axi_b.bvalid) || (axi_bQ.bvalid && axi_bready)) begin
                axi_bQ <= axi_b;
            end 
        end 
    end  
    //write channels end
    
    
    //read channels begin
    always_comb
    begin
        // 临时变量存储aruser
        logic [$bits(axi_ar.aruser)-1:0] tmpuser_ar;
        tmpuser_ar = mwae_axi_ar.aruser;
        
        // 复制所有字段
        axi_ar = mwae_axi_ar;
        
        // 更新aruser值，确保target_hdm位被正确设置
        // 注意：这里假设target_hdm是结构体中的最高位
        if (axi_rtarget_hdm) begin
            tmpuser_ar |= (1 << ($bits(axi_ar.aruser)-1));
        end else begin
            tmpuser_ar &= ~(1 << ($bits(axi_ar.aruser)-1));
        end
        
        // 将修改后的值赋回
        axi_ar.aruser = tmpuser_ar;
    end

    assign axi_arready         = cafu_axi_arready;
    assign mwae_axi_arready    = (~axi_arQ.arvalid || axi_arready);   //ready when empty or moving
    assign cafu_axi_ar         = axi_arQ; 
    always_ff @(posedge clk) begin
        if (rst) begin
            axi_arQ.arvalid <= 0;
        end else begin
            //if (empty or moving), accept input
            if ((~axi_arQ.arvalid && axi_ar.arvalid) || (axi_arQ.arvalid && axi_arready)) begin
                axi_arQ <= axi_ar;
            end            
        end  
    end  
       
    assign axi_rready          = mwae_axi_rready;
    assign cafu_axi_rready     = (~axi_rQ.rvalid || axi_rready);    //ready when empty or moving
    assign axi_r               = cafu_axi_r;
    assign mwae_axi_r          = axi_rQ;
    always_ff @(posedge clk) begin
        if (rst) begin
            axi_rQ.rvalid <= 0;
        end else begin
            //if (empty or moving), accept input
            if ((~axi_rQ.rvalid && axi_r.rvalid) || (axi_rQ.rvalid && axi_rready)) begin
                axi_rQ <= axi_r;
            end 
        end 
    end  
    //read channels ends
    

/* Functional Logic end */

endmodule


