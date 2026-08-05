//program for mux 3
import as_pack::*;

module as_mux3   
    (  input  logic [reg_width-1:0] data02_i,      
       input  logic [reg_width-1:0] imm_i,
       input  logic  alusrcb_i,
       output logic [reg_width-1:0] data02_o
      );

  assign data02_o = alusrcb_i ?  imm_i : data02_i ;
                    
endmodule 

