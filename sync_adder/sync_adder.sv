module sync_adder(
    input logic clk,
    input logic reset,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] Q
);

logic [7:0] sum;
logic [7:0] D;

always @(*)
	sum = a+b;
	
assign D = sum;

always @(posedge clk)
    if (reset == 1)
        Q <= 0;
    else
        Q <= D;

endmodule
