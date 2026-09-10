//***********************************************************
// Pipeline flush control
//
// RISCV Processor System Verilog Behavioral Model
//
//
//  Module:     Flush_Control
//  Functionality:
//      Flush Controller for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Flush_Control (
  input logic reset,
  input logic alu_valid,

  input pc_mux pc_mux_ip,

  output logic flush_en
);

  /*
    Flush control
    Add code for enabling a flush based on the inputs to this module
  */

  // check ex stage if next PC from ALU, and ALU result valid
  // flush wrong-path instructions
  always_comb begin
    flush_en = 1'b0;
    if (reset != 1'b1) begin
      if ((pc_mux_ip == ALU_RESULT) && (alu_valid == 1'b1)) begin
        flush_en = 1'b1;
      end
    end
  end
endmodule
