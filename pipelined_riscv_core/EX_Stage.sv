//***********************************************************
// Execute stage
//
// RISCV Processor System Verilog Behavioral Model
//
//
//  Module:     EX_Stage
//  Functionality:
//      Execute Stage of a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module EX_Stage (
  input logic clock, 
  input logic reset, 

  // Inputs from Decode for ALU
  input logic alu_enable_ip,
  input alu_opcode_e alu_operator_ip,
  input logic [31:0] alu_operand_a_ip,
  input logic [31:0] alu_operand_b_ip, 

  // Operand Selector from Forward Controller
  input forward_mux_code fa_mux_ip,
  input forward_mux_code fb_mux_ip,
  input logic [31:0] fw_wb_data,

  // Pass-Through Signals to Memory
  input logic lsu_enable_pt_ip,
  input load_store_func_code ex_lsu_operator_pt_ip, 
  input logic [31:0] mem_wdata_pt_ip,
  input write_back_mux_selector ex_wb_mux_ip,
  input logic [4:0] ex_write_reg_addr_pt_ip,
  input logic [31:0] ex_pc_addr_pt_ip,
  input logic [31:0] ex_uimmd_pt_ip,

  // Pass-Through to Fetch based on Flush Controller and Writeback
  input pc_mux pc_mux_ip,
  input logic [31:0] pc_branch_offset_ip,

  // Outputs of Pass-Through Signals to Memory
  output logic lsu_enable_pt_op,
  output load_store_func_code ex_lsu_operator_pt_op,
  output logic [31:0] mem_wdata_pt_op,
  output logic [4:0] ex_write_reg_addr_pt_op,

  // Outputs to LSU, MEM, and Fetch
  output logic [31:0] alu_result_op,
  output logic alu_valid_op,

  // Outputs to forward to Fetch for Flush Control
  output logic [31:0] next_PC_addr_op,
  output logic next_PC_addr_valid_op,

  // Pass Through the WriteBack Mux Signal
  output write_back_mux_selector ex_wb_mux_op,
  output logic [31:0] ex_pc_addr_pt_op,
  output logic [31:0] ex_uimmd_pt_op,
  output logic flush_en_op

);

  logic [31:0] alu_result;
  logic alu_valid;

  logic [31:0] mem_wdata;

  // For JAL Instruction to give new PC Address
  always @(*) begin
    next_PC_addr_valid_op = 0;
    next_PC_addr_op = 0;

    case (pc_mux_ip) 
      ALU_RESULT: begin
        next_PC_addr_valid_op = alu_valid;
        next_PC_addr_op = alu_result;
      end
      default begin
        next_PC_addr_valid_op = 0;
        next_PC_addr_op = 0;
      end
    endcase
  end


  // EX-MEM Pipeline Buffer
  always @(posedge clock) begin
    lsu_enable_pt_op <= lsu_enable_pt_ip;
    ex_lsu_operator_pt_op <= ex_lsu_operator_pt_ip;
    mem_wdata_pt_op <= mem_wdata_pt_ip;
    alu_result_op <= alu_result;
    alu_valid_op <= alu_valid;
    ex_wb_mux_op <= ex_wb_mux_ip;
    ex_write_reg_addr_pt_op <= ex_write_reg_addr_pt_ip;
    ex_pc_addr_pt_op <= ex_pc_addr_pt_ip;
    ex_uimmd_pt_op <= ex_uimmd_pt_ip;
  end

  // Forwarding Selection
  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;

  // Forward Values for Source Register 1
  always @(*) begin
    case (fa_mux_ip) 
      ORIGINAL_SELECT: alu_operand_a = alu_operand_a_ip; // normal reg file value
      EX_RESULT_SELECT: alu_operand_a = alu_result_op;
      MEM_RESULT_SELECT: alu_operand_a = fw_wb_data; // fw from ex/mem ALU result
      default:  alu_operand_a = alu_operand_a_ip;
    endcase
  end

  // Forward Values for Source Register 2
  always @(*) begin
    case (fb_mux_ip) 
      ORIGINAL_SELECT: alu_operand_b = alu_operand_b_ip; // normal reg file value
      EX_RESULT_SELECT: alu_operand_b = alu_result_op;
      MEM_RESULT_SELECT: alu_operand_b = fw_wb_data; // fw from ex/mem ALU result
      default: alu_operand_b = alu_operand_b_ip;
    endcase
  end

  Flush_Control U_FLUSH (
    .reset(reset),
    .alu_valid(alu_valid),
    .pc_mux_ip(pc_mux_ip),

    .flush_en(flush_en_op)
  );

  ALU ArthimeticLogicUnit (
    .reset(reset),

    // Inputs from decode
    .alu_enable_ip(alu_enable_ip),
    .alu_operator_ip(alu_operator_ip),
    .alu_operand_a_ip(alu_operand_a),
    .alu_operand_b_ip(alu_operand_b), 

    // Outputs to LSU, MEM, and Fetch
    .alu_result_op(alu_result),
    .alu_valid_op(alu_valid)
  );

endmodule