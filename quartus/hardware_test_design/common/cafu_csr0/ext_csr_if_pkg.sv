package ext_csr_if_pkg;

    // Device type definitions
    parameter TYPE_1_DEV = 3'b001;
    parameter TYPE_2_DEV = 3'b010;
    parameter TYPE_3_DEV = 3'b100;

    // Interface width parameters
    parameter CAFU2IP_CSR0_CFG_IF_WIDTH = 64;
    parameter TMP_NEW_DVSEC_FBCTRL2_STATUS2_T_BW = 32;

    // Device type enumeration
    typedef enum logic [2:0] {
        TYPE1 = TYPE_1_DEV,
        TYPE2 = TYPE_2_DEV,
        TYPE3 = TYPE_3_DEV
    } CxlDeviceType_e;

    // Memory error counter type
    typedef struct packed {
        logic [31:0] correctable;
        logic [31:0] uncorrectable;
    } mc_err_cnt_t;

    // CSR interface types
    typedef struct packed {
        logic [63:0] data;
        logic [31:0] addr;
        logic        valid;
    } csr_req_t;

    typedef struct packed {
        logic [63:0] data;
        logic        valid;
    } csr_rsp_t;

    // CAFU to IP CSR configuration interface type
    typedef struct packed {
        logic [CAFU2IP_CSR0_CFG_IF_WIDTH-1:0] data;
        logic                                  valid;
    } cafu2ip_csr0_cfg_if_t;

    // CXL Type 2 CDAT constants
    parameter TYPE2_CDAT_0 = 32'h0000_0001;
    parameter TYPE2_CDAT_1 = 32'h0000_0002;

endpackage : ext_csr_if_pkg 