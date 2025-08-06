`timescale 1ns/1ps
`define AW 8
`define DW 8

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "DUT/i2c_slave.v"

`include "COMPONENT/i2c_intf.sv"

`include "i2c_pkg.sv"

module testbench_top;

import i2c_pkg::*;

bit clk;
bit rst_n;

i2c_intf inf (.clk(clk),.rst_n(rst_n));
pullup(inf.scl);
pullup(inf.sda);
initial	
	uvm_config_db#(virtual i2c_intf)::set(null, "*", "i2c_intf", inf);

always #5 clk = ~clk;	// 100 MHz clk

i2c_slave#(.AW(`AW),.DW(`DW)) dut (
	.rst_n(inf.rst_n),
	.SDA(inf.sda),
	.SCL(inf.scl)
);

initial begin
	rst_n=0;
	#7 rst_n=1;
end

initial begin
	run_test();
end

endmodule : testbench_top
