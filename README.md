# Kevin Ly — Hardware and Systems Portfolio

Portfolio collecting independent hardware, computer-architecture, and operating-systems projects. The projects were developed separately (Spring / Fall 2026) and assembled together as a single public portfolio September 2026.

# Projects

| Project | Focus | Technologies |
| --- | --- | --- |
| [Pipelined RISC-V Core](pipelined_riscv_core/) | Five-stage processor pipeline with forwarding, stalling, hazards, and control flow | SystemVerilog, ModelSim |
| [RISC-V Decode Core](riscv_decode_core/) | Instruction decode and supporting datapath components | SystemVerilog |
| [SCOMP ADC Peripheral](scomp_adc_peripheral/) | Memory-mapped ADC peripheral integrated into an educational processor | VHDL, Quartus, assembly |
| [Synchronous Adder](sync_adder/) | Registered 8-bit adder and verification testbench | SystemVerilog |
| [OS Scheduler Simulator](os_scheduler_simulator/) | Multithreaded CPU scheduler with process-state management | C, POSIX threads |
| [Virtual Memory Simulator](virtual_memory_simulator/) | Paging, page faults, swapping, frame allocation, and page replacement | C |
| [Cache Simulator](cache_simulator/) | Configurable cache behavior, hit/miss statistics, writebacks, and LRU replacement | C |

# Note

The repository excludes generated simulator libraries, compiled hardware outputs, and large workload traces. The source code, build files, testbenches, and project documentation are still available.
