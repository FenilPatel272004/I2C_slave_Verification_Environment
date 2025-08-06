class sanity extends i2c_base_test;
	
	`uvm_component_utils(sanity)

	function new(string name = "sanity", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		wr_seq.start(env.agt.seqr);
		wr_seq.start(env.agt.seqr);
		rd_seq.start(env.agt.seqr);
		env.agt.drv.apply_stop=1;
		rd_seq.start(env.agt.seqr);
		wr_seq.start(env.agt.seqr);
		wr_seq.start(env.agt.seqr);
		rd_seq.start(env.agt.seqr);
		env.agt.drv.apply_stop=1;
		rd_seq.start(env.agt.seqr);
		phase.drop_objection(this);
	endtask : run_phase

endclass : sanity
