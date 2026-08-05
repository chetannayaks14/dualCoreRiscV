//module mux 1
`timescale 1ns / 1ps


//import as_pack::*;

module as_mux1    
    (  input  logic [reg_width-1:0] pcp4_i,      // 64 bit 
       input  logic [reg_width-1:0] pcbr_i,      // 64 bit
       input  logic  pcsrc_i,                     // 1 bit
       output logic [reg_width-1:0] pcnext_o       // 64 bit
      );

  assign pcnext_o = pcsrc_i ? pcbr_i : pcp4_i;
                    
endmodule 

