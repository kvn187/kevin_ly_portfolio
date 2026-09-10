import CORE_PKG::*;

module Core (
	// Input signals
	input logic clock,
	input logic reset,
	input logic mem_en
);

	localparam INSTR_START_PC = 0;
	localparam DATA_START_PC = 127; 							// address that separates instruction from data

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Signals and outputs
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	logic mem_gnt_req;														// Memory is ready to inputs. Sent to inputs of Fetch and LSU 	

	// Fetch Instruction Signals
	logic [31:0] instr_mem_addr;									// PC that gets sent to mem. Addr. of the instr. to fetch
	logic [31:0] next_instr_addr; 								// PC + 4
	logic [31:0] instr_mem_data;									// Instruction that memory loads out
	logic mem_instr_req_valid;										// Validity of the request sent to memory for instructions
	logic mem_instr_data_valid;										// Mem to decode to inform of validity of instruction data sent

	// Decode signals 
	pc_mux pc_mux_select;													// Mux to select the address of the next instruction to execute
	logic [31:0] pc_branch_offset;								// Value of PC Address calculation needed for certain instructions

	// Load/Store Mem Signals
	logic [31:0] DRAM_wdata;
	logic [31:0] DRAM_load_mem_data;							// Data from DRAM after a load to sent to LSU for sign extensions and such
	logic [31:0] load_mem_data; 									// Data from LSU to Decode after a load instr.
	logic mem_data_req_valid;											// Validity of request sent to mem for store/load

	// ALU Signals 
	alu_opcode_e alu_operator;										// Operation that ALU should perform
	logic [31:0] alu_operand_a;										// A inputs of the ALU
	logic [31:0] alu_operand_b;										// B inputs of the ALU
	logic [31:0] alu_result;											// Result of the ALU operation
	logic alu_valid;															// If the result of the ALU operation is valid
	logic alu_en;																	// Enable the ALU

	// LSU Signals 
	load_store_func_code lsu_operator;						// Type of load/store instr. for LSU to interpret
	logic lsu_en;																	// Enable signal for the LSU

	Fetch FetchModule (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.instr_gnt_ip(mem_gnt_req),

		// Inputs from Decode
		.pc_mux_ip(pc_mux_select),
		.pc_branch_offset_ip(pc_branch_offset),

		// Inputs from ALU
		.alu_result_ip(alu_result),

		// Outputs to MEM
		.instr_req_op(mem_instr_req_valid),
		.instr_addr_op(instr_mem_addr),

		// Outputs to decode
		.next_instr_addr_op(next_instr_addr)
	);

	Decode DecodeModule (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.pc(instr_mem_addr),
		.pc4(next_instr_addr),

		// Inputs from MEM
		.instr_data_valid_ip(mem_instr_data_valid),
		.instr_data_ip(instr_mem_data),

		 // Inputs from ALU
		.alu_result_valid_ip(alu_valid),
		.alu_result_ip(alu_result),

		// Inputs from LSU
		.mem_data_ip(load_mem_data),
		.mem_data_valid_ip(mem_data_req_valid),

		// Outputs to ALU and Comparator
		.alu_operator_op(alu_operator),
		.alu_en_op(alu_en),
		.alu_operand_a_ex_op(alu_operand_a),
		.alu_operand_b_ex_op(alu_operand_b),

		// Outputs to LSU
		.en_lsu_op(lsu_en),
		.lsu_operator_op(lsu_operator),

		// Outputs to MEM	
		.mem_wdata_op(DRAM_wdata),

		// Outputs to Fetch
		.pc_branch_offset_op(pc_branch_offset),
		.pc_mux_op(pc_mux_select)
	);

	ALU ALUModule (
		// General Inputs
		.reset(reset),

		// Inputs from decode
		.alu_enable_ip(alu_en),
		.alu_operator_ip(alu_operator),
		.alu_operand_a_ip(alu_operand_a),
		.alu_operand_b_ip(alu_operand_b),

		// Outputs to LSU, MEM, and Fetch
		.alu_result_op(alu_result),
		.alu_valid_op(alu_valid)
	);

	LSU LoadStoreUnit (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.data_gnt_i(mem_gnt_req),

		// Inputs from Decode
		.lsu_en_ip(lsu_en),
		.lsu_operator_ip(lsu_operator),

		// Inputs from ALU
		.alu_valid_ip(alu_valid),
		.mem_addr_ip(alu_result),

		// Inputs from DRAM
		.mem_data_ip(DRAM_load_mem_data),

		// Output to Decode
		.data_req_op(mem_data_req_valid),
		.load_mem_data_op(load_mem_data)
	);

	DRAM MainMemory (
		// General Inputs
		.mem_en(mem_en),
		.clock(clock),
		
		// Inputs from LSU
		.data_req_ip(mem_data_req_valid),

		// Inputs from Fetch
		.instr_req_ip(mem_instr_req_valid),
		.instr_addr_ip(instr_mem_addr),

		// Inputs from Decode
		.lsu_operator(lsu_operator),
		.wdata_ip(DRAM_wdata),

		// Inputs from ALU
		.data_addr_ip(alu_result),

		//Outputs 
		.mem_gnt_op(mem_gnt_req),

		// Outputs to Decode
		.instr_valid_op(mem_instr_data_valid),
		.instr_data_op(instr_mem_data),
		.load_data_op(DRAM_load_mem_data)
	);

endmodule