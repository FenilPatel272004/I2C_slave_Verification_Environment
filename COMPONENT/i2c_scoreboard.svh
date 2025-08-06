class i2c_scoreboard extends uvm_scoreboard;

	i2c_seq_item pkt_que[$];

	logic [`DW-1 : 0] ref_MEM [0 : (1<<`AW)-1];

	i2c_seq_item txn;

	uvm_analysis_imp#(i2c_seq_item, i2c_scoreboard) scb_imp;

	`uvm_component_utils(i2c_scoreboard)

	function new(string name="i2c_scoreboard", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		scb_imp = new("scb_imp", this);
	endfunction : build_phase

	virtual function void write(i2c_seq_item txn);
		pkt_que.push_back(txn);
	endfunction : write

	virtual task run_phase(uvm_phase phase);
		forever begin
			wait(pkt_que.size() > 0);
			txn = pkt_que.pop_front();
			if(txn.rw) begin
				if(txn.data_out === ref_MEM[txn.addr]) begin
					`uvm_info("SCOREBOARD", $sformatf("\tREAD DATA MATCH     addr=%2d   data=0x%8h", txn.addr, txn.data_out), UVM_LOW)
				end else begin
					`uvm_error("SCOREBOARD", $sformatf("\tREAD DATA MIS-MATCH  addr=%2d   read_data=0x%8h   expected=0x%8h", txn.addr, txn.data_out, ref_MEM[txn.addr]))
				end
			end else begin
				ref_MEM[txn.addr] = txn.data_in;
				`uvm_info("SCOREBOARD", $sformatf("\tDATA WRITE        addr=%2d   data=0x%8h", txn.addr, txn.data_in), UVM_LOW)
			end
		end
	endtask : run_phase
endclass : i2c_scoreboard
