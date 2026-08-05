//program for pcbr
`timescale 1ns / 1ps
//import as_pack::*;
module as_pcbr #(parameter reg_width = 64) (
    input  logic [reg_width-1:0] data01_i,  
    input  logic [reg_width-1:0] imm_i, 
    output logic [reg_width-1:0] pcbr_o
);

    // Add 4 to the current PC
    assign pcbr_o = data01_i + imm_i;

endmodule

