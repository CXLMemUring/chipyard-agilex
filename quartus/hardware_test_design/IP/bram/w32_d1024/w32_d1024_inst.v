	w32_d1024 u0 (
		.data      (_connected_to_data_),      //   input,  width = 32,      data.datain
		.q         (_connected_to_q_),         //  output,  width = 32,         q.dataout
		.wraddress (_connected_to_wraddress_), //   input,  width = 10, wraddress.wraddress
		.rdaddress (_connected_to_rdaddress_), //   input,  width = 10, rdaddress.rdaddress
		.wren      (_connected_to_wren_),      //   input,   width = 1,      wren.wren
		.clock     (_connected_to_clock_),     //   input,   width = 1,     clock.clk
		.sclr      (_connected_to_sclr_)       //   input,   width = 1,      sclr.reset
	);

