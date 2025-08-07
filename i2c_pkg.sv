package i2c_pkg;

	`include "uvm_macros.svh";
	import uvm_pkg::*;

	int wr_pkt=2;
	int rd_pkt=2;

	`include "COMPONENT/i2c_seq_item.svh";
	`include "COMPONENT/i2c_sequencer.svh";
	`include "COMPONENT/i2c_sequence.svh";
	`include "COMPONENT/i2c_driver.svh";
	`include "COMPONENT/i2c_monitor.svh";
	`include "COMPONENT/i2c_agent.svh";
	`include "COMPONENT/i2c_scoreboard.svh"
	`include "COMPONENT/i2c_environment.svh";
	`include "COMPONENT/i2c_base_test.svh";

	`include "TESTCASE/sanity.sv"
	`include "TESTCASE/user_define_data.sv"

endpackage
