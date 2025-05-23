// fifo_28w_16d.v

// Generated using ACDS version 23.3 104

`timescale 1 ps / 1 ps
module fifo_28w_16d (
		input  wire [27:0] data,    //  fifo_input.datain
		input  wire        wrreq,   //            .wrreq
		input  wire        rdreq,   //            .rdreq
		input  wire        wrclk,   //            .wrclk
		input  wire        rdclk,   //            .rdclk
		output wire [27:0] q,       // fifo_output.dataout
		output wire        rdempty, //            .rdempty
		output wire        wrfull   //            .wrfull
	);

	fifo_28w_16d_fifo_1923_i6cb3wa fifo_0 (
		.data    (data),    //   input,  width = 28,  fifo_input.datain
		.wrreq   (wrreq),   //   input,   width = 1,            .wrreq
		.rdreq   (rdreq),   //   input,   width = 1,            .rdreq
		.wrclk   (wrclk),   //   input,   width = 1,            .wrclk
		.rdclk   (rdclk),   //   input,   width = 1,            .rdclk
		.q       (q),       //  output,  width = 28, fifo_output.dataout
		.rdempty (rdempty), //  output,   width = 1,            .rdempty
		.wrfull  (wrfull)   //  output,   width = 1,            .wrfull
	);

endmodule
