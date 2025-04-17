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
/*                COHERENCE-COMPLIANCE VALIDATION AFU

  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder

  initial -> 07/07/2022 -> joshuasc
*/

module ccv_afu_cfg_reg_access
    import afu_axi_if_pkg::*;
    import rtlgen_pkg_v12::*;
    import ccv_afu_cfg_pkg::*;
(
    // Clocks
    input  gated_clk,
    input  rtl_clk,

    // Resets
    input  rst_n,

    // Config Access  from iosf-sb or AVMM
    input ccv_afu_cfg_cr_req_t  req,
    output ccv_afu_cfg_cr_ack_t  ack,

    /* config registers interface to/from registers to multi-write-algorithm-engine
    */
    intf_ccv_afu_cfg_regs.CFG_REGS_SIDE   config_regs_intf
);



ccv_afu_cfg     inst_ccv_afu_cfg
( //lintra s-2096
    .gated_clk ( gated_clk ),
    .rtl_clk   ( rtl_clk   ),
    .rst_n     ( rst_n     ),
    .req       ( req       ),
    .ack       ( ack       ),

    .new_DEVICE_ERROR_LOG4  ( config_regs_intf.error_log_4_reg  ),
    .new_DEVICE_ERROR_LOG5  ( config_regs_intf.error_log_5_reg  ),
    .new_DEVICE_STATUS_LOG1 ( config_regs_intf.status_log_1_reg ),

    .CONFIG_ALGO_SETTING        ( config_regs_intf.algorithm_config_reg   ),
    .CONFIG_TEST_ADDR_INCRE     ( config_regs_intf.increment_reg          ),
    .CONFIG_TEST_BYTEMASK       ( config_regs_intf.byte_mask_reg          ),
    .CONFIG_TEST_PATTERN        ( config_regs_intf.pattern_reg            ),
    .CONFIG_TEST_PATTERN_PARAM  ( config_regs_intf.pattern_config_reg     ),
    .CONFIG_TEST_START_ADDR     ( config_regs_intf.start_address_reg      ),
    .CONFIG_TEST_WR_BACK_ADDR   ( config_regs_intf.write_back_address_reg ),

    .DEVICE_STATUS_LOG2 ( config_regs_intf.status_log_2_reg ),

    .load_DEVICE_EVENT_COUNT ( 'd0 ),

    .new_CONFIG_DEVICE_INJECTION ( 'd0 ),
    .new_DEVICE_EVENT_COUNT      ( 'd0 ),

    .CONFIG_DEVICE_INJECTION     ( ),

    .DEVICE_ERROR_LOG1 (),
    .DEVICE_ERROR_LOG2 (),
    .DEVICE_ERROR_LOG3 (),
    .DEVICE_ERROR_LOG4 (),
    .DEVICE_ERROR_LOG5 (),

    .DEVICE_EVENT_COUNT (),
    .DEVICE_EVENT_CTRL  (),

    .DEVICE_STATUS_LOG1 (),

    .CXL_DVSEC_HEADER_1  (),
    .CXL_DVSEC_HEADER_2  (),
    .CXL_DVSEC_TEST_CAP1 (),
    .CXL_DVSEC_TEST_CAP2 (),

    .CXL_DVSEC_TEST_CNF_BASE_HIGH (),
    .CXL_DVSEC_TEST_CNF_BASE_LOW  (),

    .DVSEC_TEST_CAP (),

    // Misc Inputs
    .CXL_DVSEC_HEADER_1_dvsec_vend_id  ( 16'h1e98 ),
    .CXL_DVSEC_HEADER_1_dvsec_revision ( 4'h0     ),
    .CXL_DVSEC_HEADER_1_dvsec_length   ( 12'h022  ),
    .CXL_DVSEC_HEADER_2_dvsec_id       ( 16'h000a ),

    .CXL_DVSEC_TEST_CAP1_algo_selfcheck_enb              ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_algotype_1a                     ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_algotype_1b                     ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_algotype_2                      ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_rdcurrent                 ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_rdown                     ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_rdshared                  ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_rdany                     ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_rdown_data                ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_ito_mwr                   ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_mem_wr                    ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_cl_flush                  ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_clean_evict               ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_dirty_evict               ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_clean_evict_nodata        ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_wow_inv                   ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_wow_invf                  ( 1'b1 ),
    .CXL_DVSEC_TEST_CAP1_cache_wr_inv                    ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cache_flushed                   ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_unexpect_cmpletion              ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_cmplte_timeout_injection        ( 1'b0 ),
    .CXL_DVSEC_TEST_CAP1_test_config_size                ( 8'd142 ),

    .CXL_DVSEC_TEST_CAP2_cache_size_device               ( 14'd0 ),   // need correct value
    .CXL_DVSEC_TEST_CAP2_cache_size_unit                 ( 2'd0 ),    // need correct value 

    .CXL_DVSEC_TEST_CNF_BASE_LOW_mem_space_indicator     ( 1'b0  ),
    .CXL_DVSEC_TEST_CNF_BASE_LOW_base_reg_type           ( 2'b10 ),
    .CXL_DVSEC_TEST_CNF_BASE_LOW_test_config_base_low    ( 28'd0 ),   // need correct value 

    .CXL_DVSEC_TEST_CNF_BASE_HIGH_test_config_base_high  ( 32'd0 )    // need correct value 

);


endmodule
