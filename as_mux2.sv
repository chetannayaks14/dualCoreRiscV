//module mux 2

`timescale 1ns/1ps

//import as_pack::*;

module as_mux2  
    (  input  logic [reg_width-1:0] data01_i,      
       input  logic [reg_width-1:0] pc_i,
       input  logic  alusrca_i,
       output logic [reg_width-1:0] data01_o
      );

  assign data01_o = alusrca_i ?  pc_i : data01_i ;
                    
endmodule 

