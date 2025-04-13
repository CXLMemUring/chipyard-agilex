module w32_d1024 (
		input  wire [31:0] data,      //      data.datain
		output wire [31:0] q,         //         q.dataout
		input  wire [9:0]  wraddress, // wraddress.wraddress
		input  wire [9:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock,     //     clock.clk
		input  wire        sclr       //      sclr.reset
	);
endmodule

