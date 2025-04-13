module fifo_12b_128w_show_ahead (
		input  wire [11:0] data,  //  fifo_input.datain
		input  wire        wrreq, //            .wrreq
		input  wire        rdreq, //            .rdreq
		input  wire        clock, //            .clk
		input  wire        aclr,  //            .aclr
		output wire [11:0] q,     // fifo_output.dataout
		output wire [6:0]  usedw, //            .usedw
		output wire        full,  //            .full
		output wire        empty  //            .empty
	);
endmodule

