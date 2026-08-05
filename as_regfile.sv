// ================================================
// as_regfile.sv   (with base_addr_i, N_i, preset_id_i)
// ================================================
`timescale 1ns/1ps

import as_pack::*;

module as_regfile (
    input  logic                    clk_i,        // Clock
    input  logic                    rst_i,        // Reset (active-high)
    input  logic [63:0]             base_addr_i,  // preload x10
    input  logic [63:0]             N_i,          // preload x11
    input  logic [2:0]              preset_id_i,  // preload x12 and x16=(preset_id<<3)
    input  logic [rwaddr_width-1:0] raddr01_i,    // rs1
    input  logic [rwaddr_width-1:0] raddr02_i,    // rs2
    input  logic [rwaddr_width-1:0] waddr_i,      // rd
    input  logic [reg_width-1:0]    wdata_i,      // write data
    input  logic                    wren_i,       // write enable
    output logic [reg_width-1:0]    rdata01_o,    // read data 1
    output logic [reg_width-1:0]    rdata02_o     // read data 2
);

    logic [reg_width-1:0] regfile_s [0:nr_regs-1];

    // On reset, clear all registers, then preload x10, x11, x12, x16
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            foreach (regfile_s[i]) regfile_s[i] <= '0;
            regfile_s[10] <= base_addr_i;          // x10 = array base
            regfile_s[11] <= N_i;                  // x11 = N
            regfile_s[12] <= preset_id_i;          // x12 = THREAD_ID
            regfile_s[16] <= (preset_id_i << 3);   // x16 = THREAD_ID×8
        end 
        else if (wren_i && (waddr_i != 0)) begin
            regfile_s[waddr_i] <= wdata_i;         // normal write-back
        end
    end

    // Combinational read (x0 always reads back 0)
    always_comb begin
        rdata01_o = (raddr01_i != 0) ? regfile_s[raddr01_i] : '0;
        rdata02_o = (raddr02_i != 0) ? regfile_s[raddr02_i] : '0;
    end
endmodule
