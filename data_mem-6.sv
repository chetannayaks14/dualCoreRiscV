// data_mem_with_blocks.v
`timescale 1ns / 1ps

module data_mem #(
    parameter int dwidth = 64,        // Data width (default: 64 bits)
    parameter int awidth = 64,        // Address width (default: 64 bits)
    parameter int instr_width = 32,   // Instruction width (default: 32 bits)
    parameter int mdepth = 4096       // Memory depth (default: 4096 entries)
)(
    input  logic                   clk_i,
    input  logic                   wrEn_i,
    input  logic                   rdEn_i,
    input  logic [awidth-1:0]      addr_i,
    input  logic [instr_width-1:0] instr_i,
    input  logic [dwidth-1:0]      data_i,
    output logic [dwidth-1:0]      data_o
);

    // Use Block RAM style with 64-bit width and 4096 entries
    //(* ram_style = "block" *) reg [63:0] ram_s [4095 : 0];
     (* ram_style = "distributed" *) reg [dwidth-1:0] ram_s [mdepth-1 : 0];
     
    logic [dwidth-1:0] prev;
    // Internal signals for store and load blocks
    logic [dwidth-1:0] dataWr_s;
    logic [dwidth-1:0] dataRd_s;
    logic [6:0]        opcode_s;
    logic [2:0]        func3_s;
    logic [6:0]        opcoder_s;
    logic [2:0]        func3r_s;
    
    assign opcode_s  = instr_i[6:0];
    assign opcoder_s = instr_i[6:0];
    assign func3_s   = instr_i[14:12];
    assign func3r_s  = instr_i[14:12];
   // assign prev = ram_s[addr_i[63:3]];
   
always_comb begin
    prev = ram_s[addr_i[ awidth-1:3]];
 end
 
 // Handle memory read (Combinational Read)
    assign dataRd_s = rdEn_i ? ram_s[addr_i[awidth-1:3]] : {dwidth{1'b0}};

   // Instantiate store block
    store_block #(
        .dwidth(dwidth),
        .awidth(awidth),
        .instr_width(instr_width)
    ) store (
        .we_s(wrEn_i),
        .opcode_s(opcode_s),
        .func3_s(func3_s),
        .addr_s(addr_i),
        .dataw_s(data_i),
        .dataWr_s(dataWr_s),
        .prev_data(prev)
    );

    // Instantiate load block
    load_block #(
        .dwidth(dwidth),
        .awidth(awidth),
        .instr_width(instr_width)
    ) load (
        .rdEn_i(rdEn_i),
        .opcoder_s(opcoder_s),
        .func3r_s(func3r_s),
        .addr_i(addr_i),
        .dataRd_s(dataRd_s),
        .data_o(data_o)
    );


    // Handle memory write
    always_ff @(posedge clk_i) begin
        if (wrEn_i && opcode_s == 7'b0100011) begin
            ram_s[addr_i[awidth-1:3]] <= dataWr_s;
        end
    end

endmodule
