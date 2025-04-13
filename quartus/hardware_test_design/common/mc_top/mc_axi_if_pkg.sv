package mc_axi_if_pkg;

    // AXI Interface Parameters
    parameter AXI_ADDR_WIDTH = 64;
    parameter AXI_DATA_WIDTH = 512;
    parameter AXI_ID_WIDTH = 8;
    parameter AXI_LEN_WIDTH = 8;
    parameter AXI_SIZE_WIDTH = 3;
    parameter AXI_BURST_WIDTH = 2;
    parameter AXI_LOCK_WIDTH = 1;
    parameter AXI_CACHE_WIDTH = 4;
    parameter AXI_PROT_WIDTH = 3;
    parameter AXI_QOS_WIDTH = 4;
    parameter AXI_REGION_WIDTH = 4;
    parameter AXI_USER_WIDTH = 1;
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8;

    // Additional AXI Parameters
    parameter MC_AXI_RAC_ADDR_BW = AXI_ADDR_WIDTH;
    parameter MC_AXI_RAC_ID_BW = AXI_ID_WIDTH;
    parameter MC_AXI_WAC_ID_BW = AXI_ID_WIDTH;
    parameter MC_AXI_WRC_ID_BW = AXI_ID_WIDTH;
    parameter MC_AXI_WRC_USER_BW = AXI_USER_WIDTH;
    parameter MC_AXI_RRC_ID_BW = AXI_ID_WIDTH;
    parameter MC_AXI_RRC_DATA_BW = AXI_DATA_WIDTH;

    // AXI Burst Types
    parameter BURST_FIXED = 2'b00;
    parameter BURST_INCR  = 2'b01;
    parameter BURST_WRAP  = 2'b10;

    // AXI Response Types
    parameter RESP_OKAY   = 2'b00;
    parameter RESP_EXOKAY = 2'b01;
    parameter RESP_SLVERR = 2'b10;
    parameter RESP_DECERR = 2'b11;

    // Interface Types
    typedef struct packed {
        logic [AXI_ID_WIDTH-1:0]     id;
        logic [AXI_ADDR_WIDTH-1:0]   addr;
        logic [AXI_LEN_WIDTH-1:0]    len;
        logic [AXI_SIZE_WIDTH-1:0]   size;
        logic [AXI_BURST_WIDTH-1:0]  burst;
        logic [AXI_LOCK_WIDTH-1:0]   lock;
        logic [AXI_CACHE_WIDTH-1:0]  cache;
        logic [AXI_PROT_WIDTH-1:0]   prot;
        logic [AXI_QOS_WIDTH-1:0]    qos;
        logic [AXI_REGION_WIDTH-1:0] region;
        logic [AXI_USER_WIDTH-1:0]   user;
        logic                        valid;
    } axi_ar_t;

    typedef struct packed {
        logic [AXI_ID_WIDTH-1:0]     id;
        logic [AXI_ADDR_WIDTH-1:0]   addr;
        logic [AXI_LEN_WIDTH-1:0]    len;
        logic [AXI_SIZE_WIDTH-1:0]   size;
        logic [AXI_BURST_WIDTH-1:0]  burst;
        logic [AXI_LOCK_WIDTH-1:0]   lock;
        logic [AXI_CACHE_WIDTH-1:0]  cache;
        logic [AXI_PROT_WIDTH-1:0]   prot;
        logic [AXI_QOS_WIDTH-1:0]    qos;
        logic [AXI_REGION_WIDTH-1:0] region;
        logic [AXI_USER_WIDTH-1:0]   user;
        logic                        valid;
    } axi_aw_t;

    typedef struct packed {
        logic [AXI_DATA_WIDTH-1:0]   data;
        logic [AXI_STRB_WIDTH-1:0]   strb;
        logic                        last;
        logic [AXI_USER_WIDTH-1:0]   user;
        logic                        valid;
    } axi_w_t;

    typedef struct packed {
        logic [AXI_ID_WIDTH-1:0]     id;
        logic [1:0]                  resp;
        logic [AXI_USER_WIDTH-1:0]   user;
        logic                        valid;
    } axi_b_t;

    typedef struct packed {
        logic [AXI_ID_WIDTH-1:0]     id;
        logic [AXI_DATA_WIDTH-1:0]   data;
        logic [1:0]                  resp;
        logic                        last;
        logic [AXI_USER_WIDTH-1:0]   user;
        logic                        valid;
    } axi_r_t;

    // Additional Interface Types
    typedef struct packed {
        axi_aw_t aw;
        axi_w_t  w;
        logic    ready;
    } t_to_mc_axi4;

    typedef struct packed {
        axi_b_t  b;
        logic    ready;
    } t_from_mc_axi4;

endpackage : mc_axi_if_pkg 