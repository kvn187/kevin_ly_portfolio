.PHONY: all sim metrics core_tb core_metrics_tb clean

all: sim

core_tb: ./include/core_pkg.sv ./testbench/core_tb.sv Core.sv Fetch.sv Instr_Mem.sv IF_Stage.sv ID_Stage.sv Stall_Control.sv ALU.sv EX_Stage.sv FWD_Control.sv DRAM.sv DFlipFlop.sv Register_File.sv Mem_Stage.sv WB_Stage.sv Flush_Control.sv
	iverilog -g2012 -I include -s Core_tb -o $@ $^

sim: core_tb
	vvp $<

core_metrics_tb: ./include/core_pkg.sv ./testbench/core_metrics_tb.sv Core.sv Fetch.sv Instr_Mem.sv IF_Stage.sv ID_Stage.sv Stall_Control.sv ALU.sv EX_Stage.sv FWD_Control.sv DRAM.sv DFlipFlop.sv Register_File.sv Mem_Stage.sv WB_Stage.sv Flush_Control.sv
	iverilog -g2012 -I include -s Core_metrics_tb -o $@ $^

metrics: core_metrics_tb
	vvp $<

clean:
	@rm -f core_tb core_metrics_tb Core_Simulation.vcd Core_Metrics.vcd
