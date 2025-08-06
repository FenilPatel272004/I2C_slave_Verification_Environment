class i2c_monitor extends uvm_monitor;

	uvm_event start, stop, r_start;

	bit [7:0] addr_op;	// address + operation(read(1) / write(0))
	bit [7:0] addr;
	bit [7:0] data_in;
	bit [7:0] data_out;
	bit	addr_data;	// flag to differenciate between receiving addr or data at write. 0-taking addr, 1-taking data
	bit in_transaction;
	virtual i2c_intf vif;

	uvm_analysis_port#(i2c_seq_item) mon_port;

	i2c_seq_item txn;

	`uvm_component_utils(i2c_monitor)

	function new(string name="i2c_monitor", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual i2c_intf)::get(this, "", "i2c_intf", vif))
			`uvm_fatal("NOVIF", "Virtual interface not set in config DB");
		mon_port = new("mon_port", this);
		txn = i2c_seq_item::type_id::create("txn", this);
		start = new();
		stop = new();
		r_start = new();
		in_transaction=0;
	endfunction : build_phase

	virtual task store_byte(output bit [7:0] data_byte);
		for(int i=7; i>=0; i--) begin
			@(posedge vif.scl);
			data_byte[i] = vif.sda;
		end
	endtask : store_byte

	virtual task run_phase(uvm_phase phase);
		fork
			// START detection
			forever begin : start_block
				@(negedge vif.sda iff (vif.scl == 1));
				start.trigger;
			end : start_block

			// STOP detection (only after START)
			forever begin : stop_block
				start.wait_trigger();
				@(posedge vif.sda iff (vif.scl == 1));
				stop.trigger;
			end : stop_block

			// Communication monitor block
			forever begin : communication_block
				if (!in_transaction) begin
					start.wait_trigger;
					`uvm_info("MONITOR", "\tStart condition detected...", UVM_MEDIUM)
				end
				in_transaction = 1;

				fork
					// Handle repeated START
					begin
						start.wait_trigger;
						`uvm_info("MONITOR", "\tRepeat START detected — restarting transaction", UVM_HIGH)
						disable monitor_transaction;
					end

					// Handle STOP
					begin
						stop.wait_trigger;
						in_transaction = 0;
						`uvm_info("MONITOR", "\tStop condition detected — ending transaction", UVM_MEDIUM)
						disable monitor_transaction;
					end

					// Monitor I2C Transaction
					begin : monitor_transaction
						store_byte(addr_op);
						addr_data = 0;	// reset flag at new connection
						@(posedge vif.scl);
					
						if (vif.sda) begin
							`uvm_warning("MONITOR", $sformatf("\tNo slave found with address %b", addr_op[7:1]))
							disable monitor_transaction;
						end else if (addr_op[7:1] == `SLAVE_ID) begin
							if (addr_op[0]) begin
								`uvm_info("MONITOR", $sformatf("\tConnected to %b for READ", addr_op[7:1]), UVM_HIGH)
								forever begin
									store_byte(data_out);
									vif.data_read = data_out;
									`uvm_info("MONITOR", $sformatf("\tData read = %b", data_out), UVM_HIGH)
									@(posedge vif.scl);
									if (vif.sda)
										`uvm_info("MONITOR", "\tNACK received", UVM_MEDIUM)
									`uvm_info("MONITOR", $sformatf("\tAt addr = %b, read = %b", addr, data_out), UVM_MEDIUM)
									txn.target_addr = addr_op[7:1];
									txn.rw = addr_op[0];
									txn.addr = addr;
									txn.data_out = data_out;
									mon_port.write(txn);
								end
							end else begin
								`uvm_info("MONITOR", $sformatf("\tConnected to %b for WRITE", addr_op[7:1]), UVM_HIGH)
								forever begin
									if (addr_data) begin
										store_byte(data_in);
										`uvm_info("MONITOR", $sformatf("\tData write = %b", data_in), UVM_HIGH)
									end else begin
										store_byte(addr);
										`uvm_info("MONITOR", $sformatf("\tMemory address = %b", addr), UVM_HIGH)
									end
									@(posedge vif.scl);
									if (vif.sda)
										`uvm_info("MONITOR", "\tNACK received", UVM_MEDIUM)
									if (addr_data) begin
										`uvm_info("MONITOR", $sformatf("\tAt addr = %b, write = %b", addr, data_in), UVM_MEDIUM)
										txn.target_addr = addr_op[7:1];
										txn.rw = addr_op[0];
										txn.addr = addr;
										txn.data_in = data_in;
										mon_port.write(txn);
									end
									addr_data = ~addr_data;
								end
							end
						end
					end : monitor_transaction
				join_any
				disable fork;
			end : communication_block
		join
	endtask : run_phase

endclass : i2c_monitor

/*
	virtual task run_phase(uvm_phase phase);
		begin
			fork
				begin : start_block
					forever begin
						@(negedge vif.sda iff (vif.scl==1));
						start.trigger;
					end
				end
				begin : stop_block
					forever begin
						start.wait_trigger();
						@(posedge vif.sda iff (vif.scl==1));
						stop.trigger;
					end
				end
				begin : comunication_block
					forever begin : start_again
						if(!in_transaction) begin
							start.wait_trigger;
							`uvm_info("MONITOR", "start condition detected...", UVM_MEDIUM)
						end
						in_transaction = 1;
						fork
							begin
								start.wait_trigger;
								`uvm_info("MONITOR", "repeat start condition detected...", UVM_HIGH)
								disable monitor_transaction;
							end
							begin
								stop.wait_trigger();
								`uvm_info("MONITOR", "stop condition detected...", UVM_MEDIUM)
								in_transaction = 0;
								disable monitor_transaction;
							end

							begin : monitor_transaction
								store_byte(addr_op);
								addr_data = 0; // reset flag at new connection
								@(posedge vif.scl);
								if(vif.sda) begin
									`uvm_warning("MONITOR", $sformatf("No slave fond with %b address", addr_op[7:1]))
									disable monitor_transaction;
								end else begin
									if(addr_op[7:1] == `SLAVE_ID) begin
										if(addr_op[0]) begin
											`uvm_info("MONITOR", $sformatf("Connected to %b for read operation", addr_op[7:1]), UVM_HIGH)
											forever begin
												store_byte(data_out);
												vif.data_read = data_out;
												`uvm_info("MONITOR", $sformatf("data read = %b", data_out), UVM_HIGH)
												`uvm_info("MONITOR", $sformatf("at addr=%b read=%b", addr, data_out), UVM_MEDIUM)
												@(posedge vif.scl);
												if(vif.sda)
													`uvm_info("MONITOR", "NACK receive...", UVM_MEDIUM)
											end
										end else begin
											`uvm_info("MONITOR", $sformatf("Connected to %b for write operation", addr_op[7:1]), UVM_HIGH)
											forever begin
												if(addr_data) begin
													store_byte(data_in);
													`uvm_info("MONITOR", $sformatf("data write = %b", data_in), UVM_HIGH)
												end else begin
													store_byte(addr);
													`uvm_info("MONITOR", $sformatf("      addr = %b", addr), UVM_HIGH)
												end
												if(addr_data)
													`uvm_info("MONITOR", $sformatf("at addr=%b write=%b", addr, data_in), UVM_MEDIUM)
												addr_data = ~addr_data;
												@(posedge vif.scl);
												if(vif.sda)
													`uvm_info("MONITOR", "NACK receive...", UVM_MEDIUM)
											end
										end
									end
								end
							end
						join_any
						disable fork;
					end
				end
			join
		end
	endtask : run_phase
*/
