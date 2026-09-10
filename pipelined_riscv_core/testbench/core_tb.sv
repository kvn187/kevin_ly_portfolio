//***********************************************************
// Pipelined RISC-V core testbench
//
// RISCV Processor System Verilog Behavioral Model
//
//
//  Module:     core_tb
//  Functionality:
//      This is the testbed for the 5 Stage Pipeline RISCV processor
//
//***********************************************************
`timescale 1ns / 1ns

module Core_tb;

// Clock and Reset signals to simulate as input into core
	logic clk = 1;
	logic mem_enable;
	logic reset;

	// local variables to display for testbench
	logic[6:0] cycle_count;
	
	integer i;
	initial
	begin
		cycle_count = 0;

		// do the simulation
		$dumpfile("Core_Simulation.vcd");

		// dump all the signals into the vcd waveforem file
		$dumpvars(0, Core_tb);

		reset = 1'b1;
		mem_enable = 1'b1;

		// Set the Test instructions and preset MEM and Regfile here if desired

		// Start Testbench Test Instructions. First instruction should always be a NOP

		#1 

    // NOP 
		core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[0] = 8'h00;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[1] = 8'h00;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[2] = 8'h00;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[3] = 8'h00;

    // add x5, x5, x2
		core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[4] = 8'h00;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[5] = 8'h22;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[6] = 8'h82;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[7] = 8'hb3;

    // sub x4, x12, x7
		core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[8] = 8'h40;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[9] = 8'h76;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[10] = 8'h02;
    core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[11] = 8'h33;

		#6 reset = 1'b0;

		#50 $finish;
	end

	always
		#1 clk <= clk + 1;

	always @(posedge clk) begin
		if (~reset)
			cycle_count <= cycle_count + 1;
	end

	Core core_proc(
		// Inputs
		.clock(clk),
		.reset(reset),
		.mem_en(mem_enable)
	);

endmodule