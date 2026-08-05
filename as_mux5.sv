//program for mux 5
`timescale 1ns/1ps

import as_pack::*;

module as_mux5    
               (input  logic [reg_width-1:0] aluresult_i,
                input  logic [reg_width-1:0] dmemoutput_i,
                input  logic [reg_width-1:0] pcp4_i,
                input  logic [1:0]           resultsrc_i,
                output logic [reg_width-1:0] y_o);

  assign y_o = resultsrc_i[1] ? pcp4_i : (resultsrc_i[0] ? dmemoutput_i : aluresult_i);
                    
endmodule 

