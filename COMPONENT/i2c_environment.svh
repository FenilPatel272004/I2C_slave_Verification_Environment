class i2c_environment extends uvm_env;

	i2c_agent agt;
	i2c_scoreboard scb;

	`uvm_component_utils(i2c_environment)

	function new(string name="i2c_environment", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agt = i2c_agent::type_id::create("agt", this);
		scb = i2c_scoreboard::type_id::create("scb", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agt.mon.mon_port.connect(scb.scb_imp);
	endfunction : connect_phase

endclass : i2c_environment
