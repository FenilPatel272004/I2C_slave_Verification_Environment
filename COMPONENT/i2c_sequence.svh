class base_sequence extends uvm_sequence#(i2c_seq_item);

	static logic [`AW-1:0] wr_addr_que [$];

	// flag & variable for fix address and data
	bit fix_addr_flag = 0;
	bit fix_data_flag = 0;
	bit [`AW-1 : 0] fix_addr;
	bit [`DW-1 : 0] fix_data;

	`uvm_object_utils(base_sequence)

	function new(string name="base_sequence");
		super.new(name);
	endfunction : new

	// set addr
	virtual function void set_addr(bit [`AW-1 : 0] addr);
		fix_addr_flag = 1;
		fix_addr = addr;
	endfunction : set_addr

	// set data
	virtual function void set_data(bit [`DW-1 : 0] data);
		fix_data_flag = 1;
		fix_data = data;
	endfunction : set_data

	// reset flag
	virtual task post_body();
		super.post_body();
		fix_addr_flag = 0;
		fix_data_flag = 0;
	endtask : post_body
endclass : base_sequence


class i2c_wr_seq extends base_sequence;
	
	`uvm_object_utils(i2c_wr_seq)

	function new(string name="i2c_wr_seq");
		super.new(name);
	endfunction : new

	virtual task body();
		/*
		req = i2c_seq_item::type_id::create("req");
		assert(req.randomize() with {req.target_addr==`SLAVE_ID; req.rw==0;});
		send_request(req);
		wr_addr_que.push_back(req.addr);
		*/
		`uvm_do_with(req, {req.target_addr==`SLAVE_ID; req.rw==0; if(fix_addr_flag)req.addr==fix_addr; if(fix_data_flag)req.data_in==fix_data;})
		wr_addr_que.push_back(req.addr);
	endtask : body

endclass : i2c_wr_seq


class i2c_rd_seq extends base_sequence;
	
	`uvm_object_utils(i2c_rd_seq)

	function new(string name="i2c_rd_seq");
		super.new(name);
	endfunction : new

	virtual task body();
		/*
		req = i2c_seq_item::type_id::create("req");
		assert(req.randomize() with {req.target_addr==`SLAVE_ID; req.rw==1; if(wr_addr_que.size()>0){req.addr==wr_addr_que.pop_front();}});
		send_request(req);
		*/
		`uvm_do_with(req, {req.target_addr==`SLAVE_ID; req.rw==1; if(fix_addr_flag){req.addr==fix_addr;} else if(wr_addr_que.size()>0){req.addr==wr_addr_que.pop_front();}})
	endtask : body

endclass : i2c_rd_seq
