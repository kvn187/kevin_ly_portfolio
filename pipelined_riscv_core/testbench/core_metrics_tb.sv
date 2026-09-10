// Directed functional regression and pipeline-event measurements.
`timescale 1ns / 1ps

module Core_metrics_tb;

  logic clk = 1'b1;
  logic mem_enable = 1'b1;
  logic reset = 1'b1;
  logic active_run = 1'b0;

  integer total_cases = 0;
  integer passed_cases = 0;
  integer total_cycles = 0;
  integer total_writebacks = 0;
  integer total_stalls = 0;
  integer total_forwards = 0;
  integer total_flushes = 0;

  integer run_cycles;
  integer run_writebacks;
  integer run_stalls;
  integer run_forwards;
  integer run_flushes;

  always #1 clk <= clk + 1'b1;

  always @(posedge clk) begin
    if (active_run && !reset) begin
      run_cycles <= run_cycles + 1;
      if (core_proc.writeback_data_valid)
        run_writebacks <= run_writebacks + 1;
      if (core_proc.stall)
        run_stalls <= run_stalls + 1;
      if ((core_proc.FA != 3'b000) || (core_proc.FB != 3'b000))
        run_forwards <= run_forwards + 1;
      if (core_proc.flush_en)
        run_flushes <= run_flushes + 1;
    end
  end

  task automatic clear_instruction_memory;
    integer index;
    begin
      for (index = 0; index < 1024; index = index + 1)
        core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[index] = 8'h00;
    end
  endtask

  task automatic write_instruction(input integer address, input logic [31:0] instruction);
    begin
      core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[address] = instruction[31:24];
      core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[address + 1] = instruction[23:16];
      core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[address + 2] = instruction[15:8];
      core_proc.InstructionFetch_Module.InstructionMemory.instr_RAM[address + 3] = instruction[7:0];
    end
  endtask

  task automatic begin_case(input string case_name);
    begin
      active_run = 1'b0;
      reset = 1'b1;
      clear_instruction_memory();
      repeat (3) @(posedge clk);
      #0.1;
      run_cycles = 0;
      run_writebacks = 0;
      run_stalls = 0;
      run_forwards = 0;
      run_flushes = 0;
      reset = 1'b0;
      active_run = 1'b1;
      $display("CASE_START %s", case_name);
    end
  endtask

  task automatic end_case(input string case_name);
    begin
      repeat (25) @(posedge clk);
      #0.1;
      active_run = 1'b0;
      total_cases = total_cases + 1;
      total_cycles = total_cycles + run_cycles;
      total_writebacks = total_writebacks + run_writebacks;
      total_stalls = total_stalls + run_stalls;
      total_forwards = total_forwards + run_forwards;
      total_flushes = total_flushes + run_flushes;
      $display("CASE_METRICS %s cycles=%0d writebacks=%0d stalls=%0d forwarding_cycles=%0d flushes=%0d", case_name, run_cycles, run_writebacks, run_stalls, run_forwards, run_flushes);
    end
  endtask

  task automatic pass_case(input string case_name);
    begin
      passed_cases = passed_cases + 1;
      $display("CASE_PASS %s", case_name);
    end
  endtask

  initial begin
    $dumpfile("Core_Metrics.vcd");
    $dumpvars(0, Core_metrics_tb);

    // Five arithmetic operations, including back-to-back register dependencies.
    begin_case("arithmetic_forwarding");
    write_instruction(4,  32'h00500093); // addi x1, x0, 5
    write_instruction(8,  32'h00700113); // addi x2, x0, 7
    write_instruction(12, 32'h002081b3); // add  x3, x1, x2
    write_instruction(16, 32'h40118233); // sub  x4, x3, x1
    write_instruction(20, 32'h00820293); // addi x5, x4, 8
    end_case("arithmetic_forwarding");
    if ((core_proc.InstructionDecode_Module.register_file.RegisterFile[1] !== 32'd5) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[2] !== 32'd7) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[3] !== 32'd12) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[4] !== 32'd7) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[5] !== 32'd15)) begin
      $fatal(1, "arithmetic_forwarding register-state mismatch");
    end
    pass_case("arithmetic_forwarding");

    // A four-instruction dependency chain exercises consecutive forwarding paths.
    begin_case("dependency_chain");
    write_instruction(4,  32'h00100313); // addi x6, x0, 1
    write_instruction(8,  32'h00230393); // addi x7, x6, 2
    write_instruction(12, 32'h00338413); // addi x8, x7, 3
    write_instruction(16, 32'h006404b3); // add  x9, x8, x6
    end_case("dependency_chain");
    if ((core_proc.InstructionDecode_Module.register_file.RegisterFile[6] !== 32'd1) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[7] !== 32'd3) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[8] !== 32'd6) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[9] !== 32'd7)) begin
      $fatal(1, "dependency_chain register-state mismatch");
    end
    pass_case("dependency_chain");

    // JAL should redirect the PC and flush the skipped arithmetic instruction.
    begin_case("jal_flush_routing");
    write_instruction(4,  32'h00100093); // addi x1, x0, 1
    write_instruction(8,  32'h0080056f); // jal  x10, 8
    write_instruction(12, 32'h06408093); // addi x1, x1, 100 (skipped)
    write_instruction(16, 32'h00208113); // addi x2, x1, 2
    end_case("jal_flush_routing");
    if ((core_proc.InstructionDecode_Module.register_file.RegisterFile[1] !== 32'd1) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[2] !== 32'd3) ||
        (core_proc.InstructionDecode_Module.register_file.RegisterFile[10] !== 32'd12)) begin
      $fatal(1, "jal_flush_routing register-state mismatch");
    end
    pass_case("jal_flush_routing");

    $display("REGRESSION_SUMMARY cases=%0d passed=%0d cycles=%0d writebacks=%0d stalls=%0d forwarding_cycles=%0d flushes=%0d", total_cases, passed_cases, total_cycles, total_writebacks, total_stalls, total_forwards, total_flushes);
    $finish;
  end

  Core core_proc (
    .clock(clk),
    .reset(reset),
    .mem_en(mem_enable)
  );

endmodule
