`define SLAVE_ID 7'b1010101

module i2c_slave#(parameter AW=8, DW=8)(
	input rst_n,

	inout SDA,
	input SCL
);

	// slave ID
	localparam SLAVE_ADDRESS = `SLAVE_ID;

	// master states
	reg [3:0] state, n_state;

	localparam	IDLE='d0,
				TARGET_ADDRESS='d1,
				SEND_DATA='d2,
				RECEIVE_DATA='d3,
				RECEIVE_ACK='d4,
				SEND_ACK='d5;

	// to handle SDA inout
	reg sda_out;
	wire slv_sda_ctrl;
	assign SDA = (slv_sda_ctrl) ? sda_out : 1'bz;
	assign slv_sda_ctrl = (state==SEND_ACK || state==SEND_DATA);
	
	reg [3:0] count; // byte count
	// reg to store SDA data
	reg addr_data;  //0: taking addr,	1: taking data
	reg [7 : 0] addr_op;
	reg [AW-1 : 0] mem_addr;
	reg [DW-1 : 0] data;

	// slave memory
	reg [DW-1 : 0] mem [0 : (1<<AW)-1];

	// state transition
	// assign n_state to state at posedge SCL
	always @(negedge rst_n or negedge SCL) begin	
		if(!rst_n) begin
			state <= IDLE;
			n_state <= IDLE;
			//slv_sda_ctrl <= 0;
			sda_out <= 1;
			count <= 0;
			addr_data <= 0;
			addr_op <= 0;
			mem_addr <= 0;
			data <= 0;
		end else begin
			state <= n_state;
		end
	end

	// to detect START and STOP condition because there won't be any scl toggle
	always @(SDA) begin	
		// start condition
		if(SCL && !SDA) begin
			state = TARGET_ADDRESS;
			addr_data = 0;
			count <= 0;
		end
		// stop condition
		if(SCL && SDA) begin
			state = IDLE;
			count <= 0;
		end
	end

	// next state block
	always@(*) begin
		case(state)
			IDLE: begin
				n_state = IDLE;
				count = 0;
			end

			TARGET_ADDRESS: begin
				if(count==8) begin
					if(addr_op[7:1]==`SLAVE_ID)
						n_state = SEND_ACK;
					else
						n_state = IDLE;
				end else
					n_state = TARGET_ADDRESS;
			end

			SEND_ACK: begin
				if(addr_op[0]) 
					n_state = SEND_DATA;
				else 
					n_state = RECEIVE_DATA;
				
			end

			RECEIVE_ACK: begin
			end

			RECEIVE_DATA: begin
				if(count == 8)
					n_state = SEND_ACK;
				else
					n_state = RECEIVE_DATA;
			end
			
			SEND_DATA: begin
				if(count == 8)
					n_state = RECEIVE_ACK;
				else
					n_state = SEND_DATA;
			end

		endcase
	end

	// posedge to sample data send by master
	always@(posedge SCL) begin	
		case(state)
			TARGET_ADDRESS: begin
				addr_op[~count[2:0]] <= SDA;
				count <= count + 1'b1;
			end
		
			RECEIVE_DATA: begin
				if(addr_data) begin
					data[~count[2:0]] <= SDA; // store SDA in "data" and then assign it to "mem[mem_addr]"
				end else
					mem_addr[~count[2:0]] <= SDA;
				count <= count + 1'b1;
			end

			SEND_DATA: begin			// there will be half cycle problem in state transistion if we update  
				count <= count + 1;		// counter for RECEIVE_DATA & SEND_DATA at different edge,				
			end							// that's why i am updating it at same edge

		endcase
	end


	// negedge to send data to master also take/give control of SDA
	always@(negedge SCL or state) begin	
		case(state)
			TARGET_ADDRESS: begin
				if(count == 8) begin
					count <= 0;
					if(addr_op[7:1]==`SLAVE_ID)
						sda_out <= 0;
				end
			end

			SEND_ACK: begin
			end

			RECEIVE_DATA: begin
				if(count == 8) begin
					addr_data <= ~addr_data;
					count <= 0;
					sda_out <= 0;
					if(addr_data)
						mem[mem_addr] <= data;
				end
			end

			RECEIVE_ACK: begin
			end

			SEND_DATA: begin
				sda_out <= mem[mem_addr][~count[2:0]];
				if(count == 8)
					count <= 0;
			end
		endcase
	end

endmodule
