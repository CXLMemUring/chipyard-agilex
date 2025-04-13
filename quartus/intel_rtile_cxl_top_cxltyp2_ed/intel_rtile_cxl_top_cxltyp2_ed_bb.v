module intel_rtile_cxl_top_cxltyp2_ed (
		input  wire         refclk0,                           //             refclk0.clk
		input  wire         refclk1,                           //             refclk1.clk
		input  wire         refclk4,                           //             refclk4.clk
		input  wire         resetn,                            //              resetn.reset_n
		input  wire         nInit_done,                        //          ninit_done.ninit_done
		output wire         ip2hdm_clk,                        //          ip2hdm_clk.clk
		output wire         ip2hdm_reset_n,                    //      ip2hdm_reset_n.reset_n
		output wire         cxl_warm_rst_n,                    //      cxl_warm_rst_n.reset_n
		output wire         cxl_cold_rst_n,                    //      cxl_cold_rst_n.reset_n
		input  wire [35:0]  hdm_size_256mb,                    //            hdm_size.hdm_size_t
		input  wire [63:0]  mc2ip_memsize,                     //                    .mem_size_t
		input  wire [15:0]  cxl_rx_n,                          //              cxl_rx.cxl_rx_n
		input  wire [15:0]  cxl_rx_p,                          //                    .cxl_rx_p
		output wire [15:0]  cxl_tx_n,                          //              cxl_tx.cxl_tx_n
		output wire [15:0]  cxl_tx_p,                          //                    .cxl_tx_p
		input  wire [4:0]   mc2ip_0_sr_status,                 //             mc2ip_0.mc_sr_status
		input  wire         mc2ip_0_rspfifo_full,              //                    .rspfifo_full
		input  wire         mc2ip_0_rspfifo_empty,             //                    .rspfifo_empty
		input  wire [5:0]   mc2ip_0_rspfifo_fill_level,        //                    .rspfifo_fill_level
		input  wire         mc2ip_0_reqfifo_full,              //                    .reqfifo_full
		input  wire         mc2ip_0_reqfifo_empty,             //                    .reqfifo_empty
		input  wire [5:0]   mc2ip_0_reqfifo_fill_level,        //                    .reqfifo_fill_level
		input  wire         hdm2ip_avmm0_cxlmem_ready,         //            hdm2ip_0.cxlmem_ready
		input  wire         hdm2ip_avmm0_ready,                //                    .ready
		input  wire [511:0] hdm2ip_avmm0_readdata,             //                    .readdata
		input  wire [13:0]  hdm2ip_avmm0_rsp_mdata,            //                    .rsp_mdata
		input  wire         hdm2ip_avmm0_read_poison,          //                    .read_poison
		input  wire         hdm2ip_avmm0_readdatavalid,        //                    .readdatavalid
		input  wire [7:0]   hdm2ip_avmm0_ecc_err_corrected,    //                    .ecc_err_corrected
		input  wire [7:0]   hdm2ip_avmm0_ecc_err_detected,     //                    .ecc_err_detected
		input  wire [7:0]   hdm2ip_avmm0_ecc_err_fatal,        //                    .ecc_err_fatal
		input  wire [7:0]   hdm2ip_avmm0_ecc_err_syn_e,        //                    .ecc_err_syn_e
		input  wire         hdm2ip_avmm0_ecc_err_valid,        //                    .ecc_err_valid
		output wire         ip2hdm_avmm0_read,                 //            ip2hdm_0.read
		output wire         ip2hdm_avmm0_write,                //                    .write
		output wire         ip2hdm_avmm0_write_poison,         //                    .write_poison
		output wire         ip2hdm_avmm0_write_ras_sbe,        //                    .write_ras_sbe
		output wire         ip2hdm_avmm0_write_ras_dbe,        //                    .write_ras_dbe
		output wire [511:0] ip2hdm_avmm0_writedata,            //                    .writedata
		output wire [63:0]  ip2hdm_avmm0_byteenable,           //                    .byteenable
		output wire [45:0]  ip2hdm_avmm0_address,              //                    .address
		output wire [13:0]  ip2hdm_avmm0_req_mdata,            //                    .req_mdata
		input  wire [4:0]   mc2ip_1_sr_status,                 //             mc2ip_1.mc_sr_status
		input  wire         mc2ip_1_rspfifo_full,              //                    .rspfifo_full
		input  wire         mc2ip_1_rspfifo_empty,             //                    .rspfifo_empty
		input  wire [5:0]   mc2ip_1_rspfifo_fill_level,        //                    .rspfifo_fill_level
		input  wire         mc2ip_1_reqfifo_full,              //                    .reqfifo_full
		input  wire         mc2ip_1_reqfifo_empty,             //                    .reqfifo_empty
		input  wire [5:0]   mc2ip_1_reqfifo_fill_level,        //                    .reqfifo_fill_level
		input  wire         hdm2ip_avmm1_cxlmem_ready,         //            hdm2ip_1.cxlmem_ready
		input  wire         hdm2ip_avmm1_ready,                //                    .ready
		input  wire [511:0] hdm2ip_avmm1_readdata,             //                    .readdata
		input  wire [13:0]  hdm2ip_avmm1_rsp_mdata,            //                    .rsp_mdata
		input  wire         hdm2ip_avmm1_read_poison,          //                    .read_poison
		input  wire         hdm2ip_avmm1_readdatavalid,        //                    .readdatavalid
		input  wire [7:0]   hdm2ip_avmm1_ecc_err_corrected,    //                    .ecc_err_corrected
		input  wire [7:0]   hdm2ip_avmm1_ecc_err_detected,     //                    .ecc_err_detected
		input  wire [7:0]   hdm2ip_avmm1_ecc_err_fatal,        //                    .ecc_err_fatal
		input  wire [7:0]   hdm2ip_avmm1_ecc_err_syn_e,        //                    .ecc_err_syn_e
		input  wire         hdm2ip_avmm1_ecc_err_valid,        //                    .ecc_err_valid
		output wire         ip2hdm_avmm1_read,                 //            ip2hdm_1.read
		output wire         ip2hdm_avmm1_write,                //                    .write
		output wire         ip2hdm_avmm1_write_poison,         //                    .write_poison
		output wire         ip2hdm_avmm1_write_ras_sbe,        //                    .write_ras_sbe
		output wire         ip2hdm_avmm1_write_ras_dbe,        //                    .write_ras_dbe
		output wire [511:0] ip2hdm_avmm1_writedata,            //                    .writedata
		output wire [63:0]  ip2hdm_avmm1_byteenable,           //                    .byteenable
		output wire [45:0]  ip2hdm_avmm1_address,              //                    .address
		output wire [13:0]  ip2hdm_avmm1_req_mdata,            //                    .req_mdata
		input  wire         afu_cam_ext5,                      //         afu2cam_ext.ext5
		input  wire         afu_cam_ext6,                      //                    .ext6
		output wire         cam_afu_ext5,                      //         cam2afu_ext.ext5
		output wire         cam_afu_ext6,                      //                    .ext6
		output wire         resetprep_en,                      //             quiesce.resetprep_en
		output wire         bfe_afu_quiesce_req,               //                    .quiesce_req
		input  wire         afu_bfe_quiesce_ack,               //                    .quiesce_ack
		input  wire [11:0]  cafu2ip_aximm0_awid,               // axi2ccip_wraddr_ch0.awid
		input  wire [63:0]  cafu2ip_aximm0_awaddr,             //                    .awaddr
		input  wire [9:0]   cafu2ip_aximm0_awlen,              //                    .awlen
		input  wire [2:0]   cafu2ip_aximm0_awsize,             //                    .awsize
		input  wire [1:0]   cafu2ip_aximm0_awburst,            //                    .awburst
		input  wire [2:0]   cafu2ip_aximm0_awprot,             //                    .awprot
		input  wire [3:0]   cafu2ip_aximm0_awqos,              //                    .awqos
		input  wire [4:0]   cafu2ip_aximm0_awuser,             //                    .awuser
		input  wire         cafu2ip_aximm0_awvalid,            //                    .awvalid
		input  wire [3:0]   cafu2ip_aximm0_awcache,            //                    .awcache
		input  wire [1:0]   cafu2ip_aximm0_awlock,             //                    .awlock
		input  wire [3:0]   cafu2ip_aximm0_awregion,           //                    .awregion
		output wire         ip2cafu_aximm0_awready,            //                    .awready
		input  wire [11:0]  cafu2ip_aximm1_awid,               // axi2ccip_wraddr_ch1.awid
		input  wire [63:0]  cafu2ip_aximm1_awaddr,             //                    .awaddr
		input  wire [9:0]   cafu2ip_aximm1_awlen,              //                    .awlen
		input  wire [2:0]   cafu2ip_aximm1_awsize,             //                    .awsize
		input  wire [1:0]   cafu2ip_aximm1_awburst,            //                    .awburst
		input  wire [2:0]   cafu2ip_aximm1_awprot,             //                    .awprot
		input  wire [3:0]   cafu2ip_aximm1_awqos,              //                    .awqos
		input  wire [4:0]   cafu2ip_aximm1_awuser,             //                    .awuser
		input  wire         cafu2ip_aximm1_awvalid,            //                    .awvalid
		input  wire [3:0]   cafu2ip_aximm1_awcache,            //                    .awcache
		input  wire [1:0]   cafu2ip_aximm1_awlock,             //                    .awlock
		input  wire [3:0]   cafu2ip_aximm1_awregion,           //                    .awregion
		output wire         ip2cafu_aximm1_awready,            //                    .awready
		input  wire [511:0] cafu2ip_aximm0_wdata,              // axi2ccip_wrdata_ch0.wdata
		input  wire [63:0]  cafu2ip_aximm0_wstrb,              //                    .wstrb
		input  wire         cafu2ip_aximm0_wlast,              //                    .wlast
		input  wire         cafu2ip_aximm0_wuser,              //                    .wuser
		input  wire         cafu2ip_aximm0_wvalid,             //                    .wvalid
		output wire         ip2cafu_aximm0_wready,             //                    .wready
		input  wire [511:0] cafu2ip_aximm1_wdata,              // axi2ccip_wrdata_ch1.wdata
		input  wire [63:0]  cafu2ip_aximm1_wstrb,              //                    .wstrb
		input  wire         cafu2ip_aximm1_wlast,              //                    .wlast
		input  wire         cafu2ip_aximm1_wuser,              //                    .wuser
		input  wire         cafu2ip_aximm1_wvalid,             //                    .wvalid
		output wire         ip2cafu_aximm1_wready,             //                    .wready
		output wire [11:0]  ip2cafu_aximm0_bid,                //  axi2ccip_wrrsp_ch0.bid
		output wire [1:0]   ip2cafu_aximm0_bresp,              //                    .bresp
		output wire [3:0]   ip2cafu_aximm0_buser,              //                    .buser
		output wire         ip2cafu_aximm0_bvalid,             //                    .bvalid
		input  wire         cafu2ip_aximm0_bready,             //                    .bready
		output wire [11:0]  ip2cafu_aximm1_bid,                //  axi2ccip_wrrsp_ch1.bid
		output wire [1:0]   ip2cafu_aximm1_bresp,              //                    .bresp
		output wire [3:0]   ip2cafu_aximm1_buser,              //                    .buser
		output wire         ip2cafu_aximm1_bvalid,             //                    .bvalid
		input  wire         cafu2ip_aximm1_bready,             //                    .bready
		input  wire [11:0]  cafu2ip_aximm0_arid,               // axi2ccip_rdaddr_ch0.arid
		input  wire [63:0]  cafu2ip_aximm0_araddr,             //                    .araddr
		input  wire [9:0]   cafu2ip_aximm0_arlen,              //                    .arlen
		input  wire [2:0]   cafu2ip_aximm0_arsize,             //                    .arsize
		input  wire [1:0]   cafu2ip_aximm0_arburst,            //                    .arburst
		input  wire [2:0]   cafu2ip_aximm0_arprot,             //                    .arprot
		input  wire [3:0]   cafu2ip_aximm0_arqos,              //                    .arqos
		input  wire [4:0]   cafu2ip_aximm0_aruser,             //                    .aruser
		input  wire         cafu2ip_aximm0_arvalid,            //                    .arvalid
		input  wire [3:0]   cafu2ip_aximm0_arcache,            //                    .arcache
		input  wire [1:0]   cafu2ip_aximm0_arlock,             //                    .arlock
		input  wire [3:0]   cafu2ip_aximm0_arregion,           //                    .arregion
		output wire         ip2cafu_aximm0_arready,            //                    .arready
		input  wire [11:0]  cafu2ip_aximm1_arid,               // axi2ccip_rdaddr_ch1.arid
		input  wire [63:0]  cafu2ip_aximm1_araddr,             //                    .araddr
		input  wire [9:0]   cafu2ip_aximm1_arlen,              //                    .arlen
		input  wire [2:0]   cafu2ip_aximm1_arsize,             //                    .arsize
		input  wire [1:0]   cafu2ip_aximm1_arburst,            //                    .arburst
		input  wire [2:0]   cafu2ip_aximm1_arprot,             //                    .arprot
		input  wire [3:0]   cafu2ip_aximm1_arqos,              //                    .arqos
		input  wire [4:0]   cafu2ip_aximm1_aruser,             //                    .aruser
		input  wire         cafu2ip_aximm1_arvalid,            //                    .arvalid
		input  wire [3:0]   cafu2ip_aximm1_arcache,            //                    .arcache
		input  wire [1:0]   cafu2ip_aximm1_arlock,             //                    .arlock
		input  wire [3:0]   cafu2ip_aximm1_arregion,           //                    .arregion
		output wire         ip2cafu_aximm1_arready,            //                    .arready
		output wire [11:0]  ip2cafu_aximm0_rid,                //  axi2ccip_rdrsp_ch0.rid
		output wire [511:0] ip2cafu_aximm0_rdata,              //                    .rdata
		output wire [1:0]   ip2cafu_aximm0_rresp,              //                    .rresp
		output wire         ip2cafu_aximm0_rlast,              //                    .rlast
		output wire         ip2cafu_aximm0_ruser,              //                    .ruser
		output wire         ip2cafu_aximm0_rvalid,             //                    .rvalid
		input  wire         cafu2ip_aximm0_rready,             //                    .rready
		output wire [11:0]  ip2cafu_aximm1_rid,                //  axi2ccip_rdrsp_ch1.rid
		output wire [511:0] ip2cafu_aximm1_rdata,              //                    .rdata
		output wire [1:0]   ip2cafu_aximm1_rresp,              //                    .rresp
		output wire         ip2cafu_aximm1_rlast,              //                    .rlast
		output wire         ip2cafu_aximm1_ruser,              //                    .ruser
		output wire         ip2cafu_aximm1_rvalid,             //                    .rvalid
		input  wire         cafu2ip_aximm1_rready,             //                    .rready
		output wire         ip2csr_avmm_clk,                   //             afu_csr.clk
		output wire         ip2csr_avmm_rstn,                  //                    .rst_n
		input  wire         csr2ip_avmm_waitrequest,           //                    .waitrequest
		input  wire [31:0]  csr2ip_avmm_readdata,              //                    .readdata
		input  wire         csr2ip_avmm_readdatavalid,         //                    .readdatavalid
		output wire [31:0]  ip2csr_avmm_writedata,             //                    .writedata
		output wire [21:0]  ip2csr_avmm_address,               //                    .address
		output wire         ip2csr_avmm_write,                 //                    .write
		output wire         ip2csr_avmm_read,                  //                    .read
		output wire [3:0]   ip2csr_avmm_byteenable,            //                    .byteenable
		output wire         ip2cafu_avmm_clk,                  //            cafu_csr.clk
		output wire         ip2cafu_avmm_rstn,                 //                    .rstn
		input  wire         cafu2ip_avmm_waitrequest,          //                    .waitrequest
		input  wire [63:0]  cafu2ip_avmm_readdata,             //                    .readdata
		input  wire         cafu2ip_avmm_readdatavalid,        //                    .readdatavalid
		output wire         ip2cafu_avmm_burstcount,           //                    .burstcount
		output wire [63:0]  ip2cafu_avmm_writedata,            //                    .writedata
		output wire [21:0]  ip2cafu_avmm_address,              //                    .address
		output wire         ip2cafu_avmm_write,                //                    .write
		output wire         ip2cafu_avmm_read,                 //                    .read
		output wire [7:0]   ip2cafu_avmm_byteenable,           //                    .byteenable
		output wire [31:0]  ccv_afu_conf_base_addr_high,       //             ccv_afu.base_addr_high
		output wire         ccv_afu_conf_base_addr_high_valid, //                    .base_addr_high_valid
		output wire [31:0]  ccv_afu_conf_base_addr_low,        //                    .base_addr_low
		output wire         ccv_afu_conf_base_addr_low_valid,  //                    .base_addr_low_valid
		output wire         ip2uio_tx_ready,                   //          usr_tx_st0.ready
		input  wire         uio2ip_tx_st0_dvalid,              //                    .dvalid
		input  wire         uio2ip_tx_st0_sop,                 //                    .sop
		input  wire         uio2ip_tx_st0_eop,                 //                    .eop
		input  wire         uio2ip_tx_st0_passthrough,         //                    .passthrough
		input  wire [255:0] uio2ip_tx_st0_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st0_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st0_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st0_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st0_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st0_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st0_prefix_parity,       //                    .prefix_parity
		input  wire [11:0]  uio2ip_tx_st0_RSSAI_prefix,        //                    .RSSAI_prefix
		input  wire         uio2ip_tx_st0_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		input  wire [1:0]   uio2ip_tx_st0_pvalid,              //                    .pvalid
		input  wire         uio2ip_tx_st0_vfactive,            //                    .vfactive
		input  wire [10:0]  uio2ip_tx_st0_vfnum,               //                    .vfnum
		input  wire [2:0]   uio2ip_tx_st0_pfnum,               //                    .pfnum
		input  wire [0:0]   uio2ip_tx_st0_chnum,               //                    .chnum
		input  wire [2:0]   uio2ip_tx_st0_empty,               //                    .empty
		input  wire         uio2ip_tx_st0_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st1_dvalid,              //          usr_tx_st1.dvalid
		input  wire         uio2ip_tx_st1_sop,                 //                    .sop
		input  wire         uio2ip_tx_st1_eop,                 //                    .eop
		input  wire         uio2ip_tx_st1_passthrough,         //                    .passthrough
		input  wire [255:0] uio2ip_tx_st1_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st1_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st1_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st1_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st1_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st1_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st1_prefix_parity,       //                    .prefix_parity
		input  wire [11:0]  uio2ip_tx_st1_RSSAI_prefix,        //                    .RSSAI_prefix
		input  wire         uio2ip_tx_st1_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		input  wire [1:0]   uio2ip_tx_st1_pvalid,              //                    .pvalid
		input  wire         uio2ip_tx_st1_vfactive,            //                    .vfactive
		input  wire [10:0]  uio2ip_tx_st1_vfnum,               //                    .vfnum
		input  wire [2:0]   uio2ip_tx_st1_pfnum,               //                    .pfnum
		input  wire [0:0]   uio2ip_tx_st1_chnum,               //                    .chnum
		input  wire [2:0]   uio2ip_tx_st1_empty,               //                    .empty
		input  wire         uio2ip_tx_st1_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st2_dvalid,              //          usr_tx_st2.dvalid
		input  wire         uio2ip_tx_st2_sop,                 //                    .sop
		input  wire         uio2ip_tx_st2_eop,                 //                    .eop
		input  wire         uio2ip_tx_st2_passthrough,         //                    .passthrough
		input  wire [255:0] uio2ip_tx_st2_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st2_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st2_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st2_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st2_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st2_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st2_prefix_parity,       //                    .prefix_parity
		input  wire [11:0]  uio2ip_tx_st2_RSSAI_prefix,        //                    .RSSAI_prefix
		input  wire         uio2ip_tx_st2_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		input  wire [1:0]   uio2ip_tx_st2_pvalid,              //                    .pvalid
		input  wire         uio2ip_tx_st2_vfactive,            //                    .vfactive
		input  wire [10:0]  uio2ip_tx_st2_vfnum,               //                    .vfnum
		input  wire [2:0]   uio2ip_tx_st2_pfnum,               //                    .pfnum
		input  wire [0:0]   uio2ip_tx_st2_chnum,               //                    .chnum
		input  wire [2:0]   uio2ip_tx_st2_empty,               //                    .empty
		input  wire         uio2ip_tx_st2_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st3_dvalid,              //          usr_tx_st3.dvalid
		input  wire         uio2ip_tx_st3_sop,                 //                    .sop
		input  wire         uio2ip_tx_st3_eop,                 //                    .eop
		input  wire         uio2ip_tx_st3_passthrough,         //                    .passthrough
		input  wire [255:0] uio2ip_tx_st3_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st3_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st3_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st3_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st3_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st3_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st3_prefix_parity,       //                    .prefix_parity
		input  wire [11:0]  uio2ip_tx_st3_RSSAI_prefix,        //                    .RSSAI_prefix
		input  wire         uio2ip_tx_st3_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		input  wire [1:0]   uio2ip_tx_st3_pvalid,              //                    .pvalid
		input  wire         uio2ip_tx_st3_vfactive,            //                    .vfactive
		input  wire [10:0]  uio2ip_tx_st3_vfnum,               //                    .vfnum
		input  wire [2:0]   uio2ip_tx_st3_pfnum,               //                    .pfnum
		input  wire [0:0]   uio2ip_tx_st3_chnum,               //                    .chnum
		input  wire [2:0]   uio2ip_tx_st3_empty,               //                    .empty
		input  wire         uio2ip_tx_st3_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_tx_st_Hcrdt_update,         //           usr_tx_st.Hcrdt_update
		output wire [0:0]   ip2uio_tx_st_Hcrdt_ch,             //                    .Hcrdt_ch
		output wire [5:0]   ip2uio_tx_st_Hcrdt_update_cnt,     //                    .Hcrdt_update_cnt
		output wire [2:0]   ip2uio_tx_st_Hcrdt_init,           //                    .Hcrdt_init
		input  wire [2:0]   uio2ip_tx_st_Hcrdt_init_ack,       //                    .Hcrdt_init_ack
		output wire [2:0]   ip2uio_tx_st_Dcrdt_update,         //                    .Dcrdt_update
		output wire [0:0]   ip2uio_tx_st_Dcrdt_ch,             //                    .Dcrdt_ch
		output wire [11:0]  ip2uio_tx_st_Dcrdt_update_cnt,     //                    .Dcrdt_update_cnt
		output wire [2:0]   ip2uio_tx_st_Dcrdt_init,           //                    .Dcrdt_init
		input  wire [2:0]   uio2ip_tx_st_Dcrdt_init_ack,       //                    .Dcrdt_init_ack
		output wire         ip2uio_rx_st0_dvalid,              //         usr_rx_st_0.dvalid
		output wire         ip2uio_rx_st0_sop,                 //                    .sop
		output wire         ip2uio_rx_st0_eop,                 //                    .eop
		output wire         ip2uio_rx_st0_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st0_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st0_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st0_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st0_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st0_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st0_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st0_prefix_parity,       //                    .prefix_parity
		output wire [11:0]  ip2uio_rx_st0_RSSAI_prefix,        //                    .RSSAI_prefix
		output wire         ip2uio_rx_st0_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		output wire [1:0]   ip2uio_rx_st0_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st0_bar,                 //                    .bar
		output wire         ip2uio_rx_st0_vfactive,            //                    .vfactive
		output wire [10:0]  ip2uio_rx_st0_vfnum,               //                    .vfnum
		output wire [2:0]   ip2uio_rx_st0_pfnum,               //                    .pfnum
		output wire [0:0]   ip2uio_rx_st0_chnum,               //                    .chnum
		output wire         ip2uio_rx_st0_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st0_empty,               //                    .empty
		output wire         ip2uio_rx_st1_dvalid,              //         usr_rx_st_1.dvalid
		output wire         ip2uio_rx_st1_sop,                 //                    .sop
		output wire         ip2uio_rx_st1_eop,                 //                    .eop
		output wire         ip2uio_rx_st1_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st1_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st1_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st1_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st1_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st1_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st1_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st1_prefix_parity,       //                    .prefix_parity
		output wire [11:0]  ip2uio_rx_st1_RSSAI_prefix,        //                    .RSSAI_prefix
		output wire         ip2uio_rx_st1_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		output wire [1:0]   ip2uio_rx_st1_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st1_bar,                 //                    .bar
		output wire         ip2uio_rx_st1_vfactive,            //                    .vfactive
		output wire [10:0]  ip2uio_rx_st1_vfnum,               //                    .vfnum
		output wire [2:0]   ip2uio_rx_st1_pfnum,               //                    .pfnum
		output wire [0:0]   ip2uio_rx_st1_chnum,               //                    .chnum
		output wire         ip2uio_rx_st1_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st1_empty,               //                    .empty
		output wire         ip2uio_rx_st2_dvalid,              //         usr_rx_st_2.dvalid
		output wire         ip2uio_rx_st2_sop,                 //                    .sop
		output wire         ip2uio_rx_st2_eop,                 //                    .eop
		output wire         ip2uio_rx_st2_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st2_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st2_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st2_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st2_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st2_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st2_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st2_prefix_parity,       //                    .prefix_parity
		output wire [11:0]  ip2uio_rx_st2_RSSAI_prefix,        //                    .RSSAI_prefix
		output wire         ip2uio_rx_st2_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		output wire [1:0]   ip2uio_rx_st2_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st2_bar,                 //                    .bar
		output wire         ip2uio_rx_st2_vfactive,            //                    .vfactive
		output wire [10:0]  ip2uio_rx_st2_vfnum,               //                    .vfnum
		output wire [2:0]   ip2uio_rx_st2_pfnum,               //                    .pfnum
		output wire [0:0]   ip2uio_rx_st2_chnum,               //                    .chnum
		output wire         ip2uio_rx_st2_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st2_empty,               //                    .empty
		output wire         ip2uio_rx_st3_dvalid,              //         usr_rx_st_3.dvalid
		output wire         ip2uio_rx_st3_sop,                 //                    .sop
		output wire         ip2uio_rx_st3_eop,                 //                    .eop
		output wire         ip2uio_rx_st3_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st3_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st3_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st3_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st3_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st3_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st3_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st3_prefix_parity,       //                    .prefix_parity
		output wire [11:0]  ip2uio_rx_st3_RSSAI_prefix,        //                    .RSSAI_prefix
		output wire         ip2uio_rx_st3_RSSAI_prefix_parity, //                    .RSSAI_prefix_parity
		output wire [1:0]   ip2uio_rx_st3_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st3_bar,                 //                    .bar
		output wire         ip2uio_rx_st3_vfactive,            //                    .vfactive
		output wire [10:0]  ip2uio_rx_st3_vfnum,               //                    .vfnum
		output wire [2:0]   ip2uio_rx_st3_pfnum,               //                    .pfnum
		output wire [0:0]   ip2uio_rx_st3_chnum,               //                    .chnum
		output wire         ip2uio_rx_st3_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st3_empty,               //                    .empty
		input  wire [2:0]   uio2ip_rx_st_Hcrdt_update,         //           usr_rx_st.Hcrdt_update
		input  wire [0:0]   uio2ip_rx_st_Hcrdt_ch,             //                    .Hcrdt_ch
		input  wire [5:0]   uio2ip_rx_st_Hcrdt_update_cnt,     //                    .Hcrdt_update_cnt
		input  wire [2:0]   uio2ip_rx_st_Hcrdt_init,           //                    .Hcrdt_init
		output wire [2:0]   ip2uio_rx_st_Hcrdt_init_ack,       //                    .Hcrdt_init_ack
		input  wire [2:0]   uio2ip_rx_st_Dcrdt_update,         //                    .Dcrdt_update
		input  wire [0:0]   uio2ip_rx_st_Dcrdt_ch,             //                    .Dcrdt_ch
		input  wire [11:0]  uio2ip_rx_st_Dcrdt_update_cnt,     //                    .Dcrdt_update_cnt
		input  wire [2:0]   uio2ip_rx_st_Dcrdt_init,           //                    .Dcrdt_init
		output wire [2:0]   ip2uio_rx_st_Dcrdt_init_ack,       //                    .Dcrdt_init_ack
		output wire [7:0]   ip2uio_bus_number,                 //                 uio.usr_bus_number
		output wire [4:0]   ip2uio_device_number               //                    .usr_device_number
	);
endmodule

