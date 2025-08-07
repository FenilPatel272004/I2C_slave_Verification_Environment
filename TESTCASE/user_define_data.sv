class user_define_data extends i2c_base_test;
	
	`uvm_component_utils(user_define_data)

	function new(string name = "user_define_data", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		wr_seq.set_addr(8'b11110000);
		wr_seq.set_data(8'b11001100);
		wr_seq.start(env.agt.seqr); // now wr_seq will generate addr data as define using above method
		rd_seq.set_addr(8'b11110000);
		env.agt.drv.apply_stop=1;
		rd_seq.start(env.agt.seqr);
		phase.drop_objection(this);
	endtask : run_phase

endclass : user_define_data
