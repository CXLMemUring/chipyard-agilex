	component fifo_12b_128w_show_ahead is
		port (
			data  : in  std_logic_vector(11 downto 0) := (others => 'X'); -- datain
			wrreq : in  std_logic                     := 'X';             -- wrreq
			rdreq : in  std_logic                     := 'X';             -- rdreq
			clock : in  std_logic                     := 'X';             -- clk
			aclr  : in  std_logic                     := 'X';             -- aclr
			q     : out std_logic_vector(11 downto 0);                    -- dataout
			usedw : out std_logic_vector(6 downto 0);                     -- usedw
			full  : out std_logic;                                        -- full
			empty : out std_logic                                         -- empty
		);
	end component fifo_12b_128w_show_ahead;

	u0 : component fifo_12b_128w_show_ahead
		port map (
			data  => CONNECTED_TO_data,  --  fifo_input.datain
			wrreq => CONNECTED_TO_wrreq, --            .wrreq
			rdreq => CONNECTED_TO_rdreq, --            .rdreq
			clock => CONNECTED_TO_clock, --            .clk
			aclr  => CONNECTED_TO_aclr,  --            .aclr
			q     => CONNECTED_TO_q,     -- fifo_output.dataout
			usedw => CONNECTED_TO_usedw, --            .usedw
			full  => CONNECTED_TO_full,  --            .full
			empty => CONNECTED_TO_empty  --            .empty
		);

