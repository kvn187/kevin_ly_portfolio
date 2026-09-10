# Kevin Ly — Hardware and Systems Portfolio

A curated collection of independent hardware, computer-architecture, and operating-systems projects. These projects were developed separately and assembled here as a single public portfolio in September 2026; each project directory has its own README with implementation details and run instructions.

## Projects

| Project | Focus | Technologies |
| --- | --- | --- |
| [Pipelined RISC-V Core](pipelined_riscv_core/) | Five-stage processor pipeline with forwarding, stalling, hazards, and control flow | SystemVerilog, ModelSim |
| [RISC-V Decode Core](riscv_decode_core/) | Instruction decode and supporting datapath components | SystemVerilog |
| [SCOMP ADC Peripheral](scomp_adc_peripheral/) | Memory-mapped ADC peripheral integrated into an educational processor | VHDL, Quartus, assembly |
| [Synchronous Adder](sync_adder/) | Registered 8-bit adder and verification testbench | SystemVerilog |
| [OS Scheduler Simulator](os_scheduler_simulator/) | Multithreaded CPU scheduler with process-state management | C, POSIX threads |
| [Virtual Memory Simulator](virtual_memory_simulator/) | Paging, page faults, swapping, frame allocation, and page replacement | C |
| [Cache Simulator](cache_simulator/) | Configurable cache behavior, hit/miss statistics, writebacks, and LRU replacement | C |

## Repository notes

The repository intentionally excludes generated simulator libraries, compiled hardware outputs, and large workload traces. The source code, build files, testbenches, and project documentation remain available for review. Where a simulator requires workload traces, use compatible course or custom traces with the documented build commands.
