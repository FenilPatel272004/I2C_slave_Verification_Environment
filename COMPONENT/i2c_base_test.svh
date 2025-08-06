class i2c_base_test extends uvm_test;

	i2c_environment env;
	i2c_wr_seq wr_seq;
	i2c_rd_seq rd_seq;

	`uvm_component_utils(i2c_base_test)

	function new(string name="i2c_base_test", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = i2c_environment::type_id::create("env", this);
		wr_seq = i2c_wr_seq::type_id::create("wr_seq", this);
		rd_seq = i2c_rd_seq::type_id::create("rd_seq", this);
	endfunction : build_phase

	virtual function void end_of_elaboration();
		print();
		//uvm_top.print_topology();
	endfunction : end_of_elaboration

	virtual function void report_phase(uvm_phase phase);
		uvm_report_server svr;
		super.report_phase(phase);
		$display();
		svr = uvm_report_server::get_server();
		if(svr.get_severity_count(UVM_FATAL)+svr.get_severity_count(UVM_ERROR)>0) begin
			`uvm_info(get_type_name(), "\033[1;38;5;196m-----------------------------------------\033[0m", UVM_NONE)
			`uvm_info(get_type_name(), "\033[1;38;5;196m----            TEST FAIL            ----\033[0m", UVM_NONE)
			`uvm_info(get_type_name(), "\033[1;38;5;196m-----------------------------------------\033[0m", UVM_NONE)
		end else begin
			`uvm_info(get_type_name(), "\033[1;38;5;34m-----------------------------------------\033[0m", UVM_NONE)
			`uvm_info(get_type_name(), "\033[1;38;5;34m----            TEST PASS            ----\033[0m", UVM_NONE)
			`uvm_info(get_type_name(), "\033[1;38;5;34m-----------------------------------------\033[0m", UVM_NONE)
		end
	endfunction : report_phase
endclass : i2c_base_test
