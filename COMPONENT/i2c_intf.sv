interface i2c_intf(input bit clk, rst_n);

	wire	scl;
	wire	sda;

	// sda & scl control signal
	bit	mst_sda_ctrl;
	bit	mst_sda_out;
	bit	mst_scl_ctrl;
	bit	mst_hold_scl_high;
	bit [7:0] data_read;

	// variable for 100khz clk
	bit	clk_100khz;
	int	count;	// counter for generating clk_100khz

	// generate 100 khz clk
	always@(posedge clk) begin
		if(mst_scl_ctrl) begin
			if (count == 499) begin
				count <= 0;
				clk_100khz <= ~clk_100khz;
			end else begin
				count++;
			end
		end else begin
			count <= 0;
			clk_100khz <= 1;
		end
		if(mst_hold_scl_high) count <= 0;
	end

	// handle sda & scl
	assign scl = mst_scl_ctrl ? mst_hold_scl_high ? 1'b1 : clk_100khz : 1'bz;
	assign sda = mst_sda_ctrl ? mst_sda_out : 1'bz;

endinterface : i2c_intf
