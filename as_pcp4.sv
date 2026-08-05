//program for pcp4
`timescale 1ns / 1ps
//import as_pack::*;
module as_pcp4 #(parameter iaddr_width = 64) (
    input  logic [iaddr_width-1:0] pc_i,       // Current PC value
    output logic [iaddr_width-1:0] pc_plus4_o  // PC + 4 output
);

    // Add 4 to the current PC
    assign pc_plus4_o = pc_i + 64'd4;

endmodule
