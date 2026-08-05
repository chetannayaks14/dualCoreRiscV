// ==============================
// as_immgen Module
// ==============================
`timescale 1ns/1ps

import as_pack::*;

module as_immgen (
    input  logic [instr_width-1:0]  inst_i,
    input  logic [immsrc_width-1:0] sel_i,
    output logic [reg_width-1:0]    imm_o
);

    always_comb begin
        case (sel_i)
            3'b000: imm_o = {{52{inst_i[31]}}, inst_i[31:20]}; // I-type
            3'b001: imm_o = {{52{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}; // S-type
            3'b010: imm_o = {{52{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0}; // B-type
            3'b011: imm_o = {{44{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0}; // J-type
            3'b100: imm_o = {inst_i[31:12], 12'b0}; // U-type
            default: imm_o = 'x;
        endcase
    end

endmodule : as_immgen