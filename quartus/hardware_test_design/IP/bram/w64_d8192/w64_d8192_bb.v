module w64_d8192 (
		input  wire [63:0] data,      //      data.datain
		output wire [63:0] q,         //         q.dataout
		input  wire [12:0] wraddress, // wraddress.wraddress
		input  wire [12:0] rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock,     //     clock.clk
		input  wire        sclr       //      sclr.reset
	);
endmodule

