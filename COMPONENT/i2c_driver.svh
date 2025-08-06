class i2c_driver extends uvm_driver#(i2c_seq_item);

	uvm_event reset_evt;
	bit [7:0] prev_addr_op;
	bit in_transaction;
	bit apply_stop;
	int count;
	virtual i2c_intf vif;

	`uvm_component_utils(i2c_driver)

	function new(string name="i2c_driver", uvm_component parent);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		//super.build_phase(phase);
		if(!uvm_config_db#(virtual i2c_intf)::get(this, "", "i2c_intf", vif))
			`uvm_fatal("NOVIF", "Virtual interface not set in config DB");
		reset_evt = new();
	endfunction : build_phase

	virtual task run_phase(uvm_phase phase);
		forever begin
			seq_item_port.get_next_item(req);
			count++;
			//req.print();
			`uvm_info("DRVIVER", $sformatf("\tslave_id=%b  addr=%b  rw=%b  data_in=%b", `SLAVE_ID, req.addr, req.rw, req.data_in), UVM_FULL)
			drive_pkt();
			
			if(req.rw)
				`uvm_info("DRIVER", $sformatf("\tat addr=%b  read=%b", req.addr, req.data_out), UVM_FULL)
			else
				`uvm_info("DRIVER", $sformatf("\tat addr=%b  wriet=%b", req.addr, req.data_in), UVM_FULL)
			
			seq_item_port.item_done();

		end
	endtask : run_phase

	virtual task drive_pkt();
		fork
			forever begin : reset_block
				@(negedge vif.rst_n);
				reset_evt.trigger;
			end : reset_block

			begin
				reset_evt.wait_trigger;
				disable drv_main;
				`uvm_info("DRIVER", "\tapplying reset", UVM_LOW)
				@(posedge vif.rst_n);
				in_transaction=0;
			end

			begin : drv_main
				if(!vif.rst_n) begin
					`uvm_info("DRIVER", "\tapplying reset", UVM_LOW)
					@(posedge vif.rst_n);
					in_transaction=0;
				end
				if(!in_transaction) begin
					start_condition();
					send_byte({req.target_addr, 1'b0});
					receive_ack();
				end else if(prev_addr_op[7:1] == req.target_addr && prev_addr_op[0] != 1'b0) begin
					repeat_start();
					send_byte({req.target_addr, 1'b0});
					receive_ack();
				end
				prev_addr_op = {req.target_addr, 1'b0};
				send_byte(req.addr);
				receive_ack();
				if(req.rw) begin
					repeat_start();
					send_byte({req.target_addr, req.rw});
					prev_addr_op = {req.target_addr, req.rw};
					receive_ack();
					receive_byte(req.data_out);
					send_ack();
				end else begin
					send_byte(req.data_in);
					receive_ack();
				end
				if(apply_stop)
					stop_condition();
				
			end : drv_main

		join_any
		disable fork;
		disable reset_block;
	endtask : drive_pkt



	virtual task start_condition();
		repeat(1000)
			@(posedge vif.clk);
		vif.mst_sda_ctrl=1;
		vif.mst_sda_out=0;
		vif.mst_scl_ctrl=1;
		in_transaction = 1;
		`uvm_info("DRIVER", "\tstart condition...", UVM_FULL)
	endtask : start_condition

	virtual task repeat_start();
		@(negedge vif.scl); 
		vif.mst_sda_ctrl=1;
		vif.mst_sda_out=1;
		@(posedge vif.scl) 
		vif.mst_hold_scl_high=1;
		repeat(500)
			@(posedge vif.clk)
		vif.mst_sda_ctrl=1;
		vif.mst_sda_out=0;
		vif.mst_hold_scl_high=0;
		`uvm_info("DRIVER", "\trepeat start condition...", UVM_FULL)
	endtask : repeat_start

	virtual task stop_condition();
		apply_stop = 0;
		@(negedge vif.scl) vif.mst_sda_ctrl=1;
						   vif.mst_sda_out=0;
		@(posedge vif.scl) vif.mst_hold_scl_high=1;
						   vif.mst_sda_ctrl=1;
						   vif.mst_sda_out=0;
		repeat(1000)
			@(posedge vif.clk);
		vif.mst_sda_ctrl=1;
		vif.mst_sda_out=1;
		`uvm_info("DRIVER", "\tstop condition...", UVM_FULL)
		@(posedge vif.clk) vif.mst_sda_ctrl=0;
						   vif.mst_sda_out=0;
						   vif.mst_scl_ctrl=0;
						   vif.mst_hold_scl_high=0;
		repeat(500)
			@(posedge vif.clk);
		in_transaction = 0;
	endtask : stop_condition

	// master take control of SDA and send bit to slave
	virtual task send_byte(bit [7:0] byte_to_send);
		for(int i=0; i<8; i++) begin
			@(negedge vif.scl);
			vif.mst_sda_ctrl=1;
			vif.mst_sda_out=byte_to_send[7-i];
		end
	endtask : send_byte

	// master release SDA and take bit send by slave
	task receive_byte(output bit [7:0] byte_to_receive);
		@(negedge vif.scl);
		for(int i=0; i<8; i++) begin
			@(posedge vif.scl);
			vif.mst_sda_ctrl=0;
			byte_to_receive[7-i]=vif.sda;
		end
	endtask : receive_byte
	
	// free SDA so slave can send ack
	task receive_ack();
		@(negedge vif.scl) vif.mst_sda_ctrl=0;
	endtask : receive_ack

	// take control of SDA and send ack to slave
	task send_ack();
		@(negedge vif.scl) vif.mst_sda_ctrl=1;
						   vif.mst_sda_out=0;
	endtask : send_ack

endclass : i2c_driver

/*	
	virtual task drive_pkt();
		start_condition();
		// send target address
		send_byte({req.target_addr, 1'b0});	// master need to send address first on 
		receive_ack();					// which write/read operation going to happen
		repeat(10) begin
		if(req.rw) begin
			send_byte($random);
			receive_ack();
			repeat_start();
			send_byte({req.target_addr, 1'b1});
			receive_ack();
			receive_byte(req.data_out);
			send_ack();
			repeat_start();
			send_byte({req.target_addr, 1'b0});	// master need to send address first on 
			receive_ack();					// which write/read operation going to happen
		end else begin
			send_byte($random);
			receive_ack();
			send_byte($random);
			receive_ack();
		end
		end
		stop_condition();
	endtask : drive_pkt
*/
