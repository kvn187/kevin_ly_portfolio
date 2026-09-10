//***********************************************************
// Pipeline stall control
//
// RISCV Processor System Verilog Behavioral Model
//
//
//  Module:     core_tb
//  Functionality:
//      Stall Controller for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Stall_Control (
  input logic reset, 

  input logic [6:0] ID_instr_opcode_ip,
  input logic [4:0] ID_src1_addr_ip,
  input logic [4:0] ID_src2_addr_ip,

  //The destination register from the different stages
  input logic [4:0] EX_reg_dest_ip,  // destination register from EX pipe
  input logic [4:0] LSU_reg_dest_ip,
  input logic [4:0] WB_reg_dest_ip,
  input logic WB_write_reg_en_ip,

  // The opcode of the current instr. in ID/EX
  input [6:0] EX_instr_opcode_ip,

  output logic stall_op
);

  // registers
  logic uses_rs1;
  logic uses_rs2;

  always_comb begin
    stall_op = 1'b0;
    uses_rs1 = 1'b0;
    uses_rs2 = 1'b0;
    
    if (reset != 1'b1) begin

      case(ID_instr_opcode_ip) 

        OPCODE_OP: begin
        
          // ADD, SUB, and SLT use rs1 and rs2
          uses_rs1 = 1'b1;
          uses_rs2 = 1'b1;

        end

        OPCODE_OPIMM: begin

          // ADDI uses rs1
          uses_rs1 = 1'b1;
          uses_rs2 = 1'b0;

        end

        OPCODE_LOAD: begin

          // LW uses rs1
          uses_rs1 = 1'b1;
          uses_rs2 = 1'b0;

        end

        default: begin
          uses_rs1 = 1'b0;
          uses_rs2 = 1'b0;
          stall_op = 1'b0;
        end
      endcase

      // Load-Use Stall
      // check if instr ahead in EX lw, check if load writes same reg as decode reads as reg
      // no stalling for x0
      // lab hint: reg can be high impedance z
      if (EX_instr_opcode_ip == OPCODE_LOAD) begin
        if ((uses_rs1 && (EX_reg_dest_ip !== 5'bzzzzz) && (EX_reg_dest_ip != 5'd0) &&
          (EX_reg_dest_ip == ID_src1_addr_ip)) ||
          (uses_rs2 && (EX_reg_dest_ip !== 5'bzzzzz) && (EX_reg_dest_ip != 5'd0) &&
          (EX_reg_dest_ip == ID_src2_addr_ip))) begin
          stall_op = 1'b1;
        end
      end

      // Write-Back Stall
      // cannot write to reg and read new value in same cycle
      // check if wb write a reg and decode reads same reg
      // no stalling for x0
      // lab hint: reg can be high impedance z
      if (WB_write_reg_en_ip && (WB_reg_dest_ip !== 5'd0) && (WB_reg_dest_ip !== 5'bzzzzz)) begin
        if (uses_rs1 && (WB_reg_dest_ip === ID_src1_addr_ip) && (ID_src1_addr_ip !== EX_reg_dest_ip) && (ID_src1_addr_ip !== LSU_reg_dest_ip)) begin
          stall_op = 1'b1;
        end

        if (uses_rs2 && (WB_reg_dest_ip === ID_src2_addr_ip) && (ID_src2_addr_ip !== EX_reg_dest_ip) && (ID_src2_addr_ip !== LSU_reg_dest_ip)) begin
        stall_op = 1'b1;
        end
      end
    end
  end
endmodule
