`timescale 1ns/1ns
`include "i2c_slave.v"

module testbench;

bit clk;
reg rst_n = 0;

wire scl;
wire sda;
pullup(scl);
pullup(sda);
reg mst_sda_ctrl;
reg hold_scl_high=0;
reg scl_drv=0;
reg sda_out = 0; // driven value
//reg scl_out = 1; // driven value



bit clk_100khz;
always #5 clk=~clk;
int counter;

always @(posedge clk) begin
	//if(dut.state != 0)
	if(scl_drv && !hold_scl_high) begin
		if (counter == 499) begin
			counter <= 0;
			clk_100khz <= ~clk_100khz;
		end else begin
			counter = counter + 1;
		end
	end else begin
		counter = 0;
		clk_100khz=1;
	end
end

assign sda = mst_sda_ctrl ? sda_out : 'bz;
assign scl = scl_drv ? hold_scl_high ? 1'b1 : clk_100khz : 'bz;

  // Instantiate the slave
  i2c_slave #(8, 8) dut (
    .rst_n(rst_n),
    .SCL(scl),
    .SDA(sda)
  );

bit [7:0] data_write;
bit [7:0] data_read;

// start conditio
task start_condition(int delay);
	#delay;
	scl_drv=1;
	mst_sda_ctrl = 1;
	sda_out = 0;
endtask

// stop condition
task stop_condition(int delay);
	@(negedge scl);
	mst_sda_ctrl=1; sda_out=0;
	@(posedge scl) hold_scl_high=1; scl_drv=1;
	#delay;
	hold_scl_high=0; scl_drv=0; 
	mst_sda_ctrl=1; sda_out=1;
	#1;
	mst_sda_ctrl=0; sda_out=0;
endtask

task repeat_start();
	@(negedge scl) mst_sda_ctrl=1; sda_out=1;
	@(posedge scl) mst_sda_ctrl=1; sda_out=0;
endtask

// give master control of SDA and assign 1-bit from MSB to LSB to SDA
task input_byte(input bit [7:0] in_byte);
	for(int i=0; i<8; i++) begin
		@(negedge scl);
		mst_sda_ctrl=1;
		sda_out = in_byte[7-i];
	end
endtask

task output_byte();
	@(negedge scl);
	for(int i=0; i<8; i++) begin
		@(posedge scl);
		mst_sda_ctrl=0;
		data_read[7-i]=sda;
	end
endtask
// free SDA so slave can send ack
task receive_ack();
	@(negedge scl) mst_sda_ctrl=0;
endtask

// take control of SDA and send ack to slave
task send_ack();
	@(negedge scl) mst_sda_ctrl=1;
	sda_out=0;
endtask

initial begin
rst_n=0; mst_sda_ctrl=0;
#5 rst_n=1;

#30000
/////// write
// start condition
start_condition(10000); // argument for delay
input_byte({`SLAVE_ID, 1'b0});
receive_ack();
data_write = 8'b11001101;
input_byte(data_write);
receive_ack();
data_write = $urandom;
input_byte(data_write);
receive_ack();
$strobe("%t\tat addr=%b\t write=%b", $time, dut.mem_addr, dut.mem[dut.mem_addr]);
stop_condition(10007);
#20000;

//// read
// send address
start_condition(10000);
input_byte({`SLAVE_ID, 1'b0});
receive_ack();
data_write = 8'b11001101;
input_byte(data_write);
receive_ack();
repeat_start();
input_byte({`SLAVE_ID, 1'b1});
receive_ack();
output_byte();
send_ack();
$strobe("%t\tat addr=%b\t read=%b", $time, dut.mem_addr, data_read);
stop_condition(10000);

#40000  $finish;

end


endmodule
