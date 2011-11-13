module vga_sync
	(
	input wire clk, reset,
	output wire hsync, vsync, video_on, p_tick,
	output wire [9:0] pixel_x, pixel_y
	);
	
	// constant declaration
	// VGA 640-by-480 sync parameters
	localparam HD = 640; //horizontal display
	localparam HF = 48; // h. back(left) porch
	localparam HB = 16; //h. front(right) porch
	localparam HR = 96; //h. retrace (sync a)
	localparam VD = 480; //vertical display
	localparam VF = 10; //v. back(top)
	localparam VB = 33; //v. front (bottom)
	localparam VR = 2; //v. retrace (sync a)
	
	// mod-2 counter
	reg mod2_reg;
	wire mod2_next;
	// sync counters
	reg [9:0] h_count_reg, h_count_next;
	reg [9:0] v_count_reg, v_count_next;
	//output buffer
	reg v_sync_reg, h_sync_reg;
	wire v_sync_next, h_sync_next;
	//status signal
	wire h_end, v_end, pixel_tick;
	
	//body
	//registers
	always @(posedge clk, posedge reset)
		if (reset)
			begin
				mod2_reg <= 1'b0;
				v_count_reg <= 1'b0;
				h_count_reg <= 1'b0;
				v_sync_reg <= 1'b0;
				h_sync_reg <= 1'b0;
			end
		else
			begin
				mod2_reg <= mod2_next;
				v_count_reg <= v_count_next;
				h_count_reg <= h_count_next;
				v_sync_reg <= v_sync_next;
				h_sync_reg <= h_sync_next;
			end

	// mod-2 circuit to generate 25Mhz enable tick
	assign mod2_next = ~mod2_reg;
	assign pixel_tick = mod2_reg;

	// status signals
	// end of horizontal counter (799)
	assign h_end = (h_count_reg == (HD+HF+HB+HR-1));
	// end of vertical counter (524)
	assign v_end = (v_count_reg == (VD+VF+VB+VR-1));

	// next state logic of mod-800 horizontal sync counter
	always @*
		if (pixel_tick) //25MHz pulse
			if(h_end)
				h_count_next = 0;
			else
				h_count_next = h_count_reg+1;
		else
			h_count_next = h_count_reg;

	// next-state logic of mod-525 vertical sync counter
	always @*
		if (pixel_tick & h_end)
			if (v_end)
				v_count_next = 0;
			else
				v_count_next = v_count_reg + 1;
		else
			v_count_next = v_count_reg;

	// horizontal and vertical sync, buffered to avoid glitch
	// h_sync_next asserted between 656 and 751
	assign h_sync_next = (h_count_reg >= (HD+HB) && h_count_reg <= (HD+HB+HR-1));
	// v_sync_next asserted between 490 and 491
	assign v_sync_next = (v_count_reg >= (VD+VB) && v_count_reg <= (VD+VB+VR-1));

	// video on/off
	assign video_on = (h_count_reg<HD) && (v_count_reg<VD);

	// output
	assign h_sync = h_sync_reg;
	assign v_sync = v_sync_reg;
	assign pixel_x = h_count_reg;
	assign pixel_y = v_count_reg;
	assign p_tick = pixel_tick;

endmodule
