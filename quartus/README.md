# m5_impl

# Mini doc v0 
## Design files
Please see the following folder for the design:
1. Instantiation of the design is in [afu_banking_top.sv](./hardware_test_design/common/afu/afu_banking_top.sv)
2. Several version of the tracker was done in this [folder](./hardware_test_design/common/cm_sketch_sorted_cam/)
3. The final version of CM-sketch banking implementation is in this [folder](./hardware_test_design/common/cm_sketch_sorted_cam/afu_banking/)
4. The [afu_banking_top.sv](./hardware_test_design/common/afu/afu_banking_top.sv) have `parameter` that allows the user to set the number of counters `parameter W =`.
5. The hot address are return from the `CSR` in this [file](./hardware_test_design/common/ex_default_csr/ex_default_csr_avmm_slave.sv). Please refer to the M5 manager for fetching and tuning the tracker.

## Compile Env
* Quartus v23.3
