`timescale 1ns / 1ns

module sync_adder_tb;
//signals needed to test functionality of sync adder
logic clk;
logic reset;
logic [7:0] a;
logic [7:0] b;
logic [7:0] Q;

//creating a sync adder and connecting signals
sync_adder DUT(
.clk(clk),
.reset(reset),
.a(a), 
.b(b),
.Q(Q)
); 

initial // initial block runs only once
	begin
		$dumpfile("Core_Simulation.vcd"); 
		$dumpvars(0, sync_adder_tb); // dump all the signals into the vcd waveforem file

		clk = 0;
		//Simple test
		a = 5;
		b = 7;
		reset = 0;
		#10
		
		//self-checking
		a = 1;
		b = 6;
		reset = 0;
		#10
		if (Q != 7) $display("1+6 failed");
		
		//self-checking
		a = 10;
		b = 15;
		reset = 0;
		#10
		if (Q != 0) $display("10+15 is not 0!");
		
		
		//Add code for 4+5=9 -------------------------------

		a = 4;
		b = 5;
		reset = 0;
		#10
		if (Q != 9) $display("4+5 did not equal 9!");
		
	
		//Add code to test reset ---------------------------

		a = 4;
		b = 5;
		reset = 1;
		#10
		if (Q != 0) $display("Reset did not work!");
		
		#5
		// $stop;
		$finish;
	end
	
always
	#1 clk = ~clk;

endmodule
