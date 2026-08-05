//program for mux4
`timescale 1ns / 1ps

import as_pack::*;

module as_mux4     
    (  input  logic [reg_width-1:0] pc_i,      
       input  logic [reg_width-1:0] jalr_i,
       input  logic  jump_i,
       output logic [reg_width-1:0] y_o
      );

  assign y_o = jump_i ? jalr_i : pc_i ;
                    
endmodule 

