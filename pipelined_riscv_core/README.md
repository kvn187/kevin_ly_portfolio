# Pipelined RISC-V Core

A five-stage RISC-V processor model implemented in SystemVerilog, including hazard detection, forwarding, memory, and pipeline control.

# Contents

Pipeline stages and datapath modules
`include/`: shared core definitions
`testbench/`: simulation testbench
`Makefile`: build and packaging commands

# Directed Regression

`testbench/core_metrics_tb.sv` runs three self-checking programs for arithmetic forwarding, a dependency chain, and JAL flush routing. It checks 12 architectural register results and records write-backs, stalls, forwarding selections, and flush events.

Run the regression in ModelSim from this directory:

```powershell
vsim -c -do "do ModelSim/metrics.do"
```

The current directed suite runs 25 post-reset cycles per program (75 total). It is a functional regression, not a benchmark or a branch-predictor evaluation.
