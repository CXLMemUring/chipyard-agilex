module port_1_ram (
		input  wire [13:0] data,    //    data.datain
		output wire [13:0] q,       //       q.dataout
		input  wire [11:0] address, // address.address
		input  wire        wren,    //    wren.wren
		input  wire        clock    //   clock.clk
	);
endmodule

