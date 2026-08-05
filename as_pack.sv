// ==============================
// as_pack Package (Updated)
// ==============================
`timescale 1ns/1ps

package as_pack;

    // Instruction-address width (64 bits)
    localparam int iaddr_width   = 64;

    // Register file data width (64 bits)
    localparam int reg_width     = 64;

    // Instruction width (32 bits)
    localparam int instr_width   = 32;

    // Immediate-source field width (3 bits)
    localparam int immsrc_width  = 3;

    // Register-address width (5 bits)
    localparam int rwaddr_width  = 5;

    // Number of registers (32)
    localparam int nr_regs       = 32;

    // Data-memory width (64 bits)
    localparam int dwidth        = 64;

    // ALU-select width (6 bits)
    localparam int aluselrv_width= 6;

    // GPIO instruction width (32 bits)
    localparam int gpio_inst_width= 32;

endpackage
