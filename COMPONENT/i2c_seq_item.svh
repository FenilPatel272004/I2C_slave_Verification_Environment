class i2c_seq_item extends uvm_sequence_item;
	rand	bit	[6:0]		target_addr;
	rand	bit				rw; // 0-write,	1-read
	rand	bit	[`AW-1:0]	addr;
	rand	bit	[`DW-1:0]	data_in;
			bit	[`DW-1:0]	data_out;
	
	`uvm_object_utils_begin(i2c_seq_item)
		`uvm_field_int(target_addr, UVM_ALL_ON)
		`uvm_field_int(rw, UVM_ALL_ON)
		`uvm_field_int(addr, UVM_ALL_ON)
		`uvm_field_int(data_in, UVM_ALL_ON)
		`uvm_field_int(data_out, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name="i2c_seq_item");
		super.new(name);
	endfunction : new

endclass : i2c_seq_item
