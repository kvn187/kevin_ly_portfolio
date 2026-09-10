all: sim

sync_adder_tb: sync_adder_tb.sv sync_adder.sv
	iverilog -g2012 -I include -s sync_adder_tb -o $@ $^

sim: sync_adder_tb
	vvp $<

clean:
	rm -f sync_adder_tb 
