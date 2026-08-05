// =========================================
// as_pc.sv   (program counter latching only pcnext → pc_o)
// =========================================
`timescale 1ns/1ps

import as_pack::*;

module as_pc (
    input  logic [iaddr_width-1:0] pcnext_i,   // next-PC value (e.g. PC+4 or branch target)
    input  logic                   clk_i,      // clock
    input  logic                   rst_i,      // synchronous reset
    output logic [iaddr_width-1:0] pc_o        // current PC
);

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            pc_o <= '0;            // on reset, PC ← 0
        end else begin
            pc_o <= pcnext_i;      // otherwise, PC ← next-PC
        end
    end

endmodule
