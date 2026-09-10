//***********************************************************
// RISC-V core testbench
//
// MIPS Processor System Verilog Behavioral Model
//
//
//  Module:     core_tb
//  Functionality:
//      This is the testbed for the Single cycle RISCV processor
//
//***********************************************************
`timescale 1ns / 1ns

//Iverilog is very irritating and does not implement all System Verilog features
//If you are using modelsim delete lines 1-101 and uncomment the code at the bottom

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

		// Representative instructions for the decode test sequence.

		#1
    // NOP since first instruction is skipped 
    core_proc.MainMemory.data_RAM[0] = 8'h00;
    core_proc.MainMemory.data_RAM[1] = 8'h00;
    core_proc.MainMemory.data_RAM[2] = 8'h00;
    core_proc.MainMemory.data_RAM[3] = 8'h00;

    // addi x5, x5, 80
    core_proc.MainMemory.data_RAM[4] = 8'h05;
    core_proc.MainMemory.data_RAM[5] = 8'h02;
    core_proc.MainMemory.data_RAM[6] = 8'h82;
    core_proc.MainMemory.data_RAM[7] = 8'h93;

    // addi x4, x5, 20
		core_proc.MainMemory.data_RAM[8] = 8'h01;
    core_proc.MainMemory.data_RAM[9] = 8'h42;
    core_proc.MainMemory.data_RAM[10] = 8'h82;
    core_proc.MainMemory.data_RAM[11] = 8'h13;

    // add x10, x5, x4
    core_proc.MainMemory.data_RAM[12] = 8'h00;
    core_proc.MainMemory.data_RAM[13] = 8'h42;
    core_proc.MainMemory.data_RAM[14] = 8'h85;
    core_proc.MainMemory.data_RAM[15] = 8'h33;

    // sub x12, x5, x4
    core_proc.MainMemory.data_RAM[16] = 8'h40;
    core_proc.MainMemory.data_RAM[17] = 8'h42;
    core_proc.MainMemory.data_RAM[18] = 8'h86;
    core_proc.MainMemory.data_RAM[19] = 8'h33;

		#5 reset = 1'b0;

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