// ===============================================
// shared_mem.sv   (with explicit initialization)
// ===============================================
`timescale 1ns/1ps

module shared_mem #(
    parameter int dwidth      = 64,    // Data width (64 bits)
    parameter int awidth      = 64,    // Address width (64 bits)
    parameter int instr_width = 32,    // Instruction width (32 bits)
    parameter int mdepth      = 4096   // Number of 64-bit words
)(
    input  logic                 clk_i,      // Clock
    input  logic                 wrEn_i,     // Data-memory write enable
    input  logic                 rdEn_i,     // Data-memory read enable
    input  logic [awidth-1:0]    addr_i,     // Byte-address from ALU
    input  logic [instr_width-1:0] instr_i,  // Fetched instruction (for opcode/func3)
    input  logic [dwidth-1:0]    data_i,     // Write data from core
    output logic [dwidth-1:0]    data_o      // Read data to core
);

    // Use distributed RAM style for a small memory block
    (* ram_style = "distributed" *)
    reg [dwidth-1:0] ram_s [0:mdepth-1];

    //--------------------------------------------------------------------
    // 1) Initialize memory contents on simulation start
    //--------------------------------------------------------------------
    initial begin
        // Zero out entire memory
        for (int i = 0; i < mdepth; i++) begin
            ram_s[i] = {dwidth{1'b0}};
        end

        // Preload two 64-bit values so that:
        //   LD x5,   8(x0)  → returns 5  (address index = 8 >> 3 = 1)
        //   LD x7,  16(x0) → returns 10 (address index = 16 >> 3 = 2)
        ram_s[1] = 64'd5;    // word at index 1 (byte-address 8)
        ram_s[2] = 64'd10;   // word at index 2 (byte-address 16)
    end

    //--------------------------------------------------------------------
    // 2) Combinational read: drive dataRd_s only when rdEn_i is asserted
    //--------------------------------------------------------------------
    logic [dwidth-1:0] dataRd_s;
    assign dataRd_s = rdEn_i
                     ? ram_s[ addr_i[awidth-1:3] ]   // index = addr >> 3
                     : {dwidth{1'b0}};

    // "prev" holds the old 64-bit word at that address (for store_block)
    logic [dwidth-1:0] prev;
    assign prev = ram_s[ addr_i[awidth-1:3] ];

    //--------------------------------------------------------------------
    // 3) Instantiate store_block + load_block (no stray semicolons!)
    //--------------------------------------------------------------------

    // This net carries the final "store data" computed by store_block
    logic [dwidth-1:0] dataWr_s;

    store_block #(
        .dwidth      (dwidth),
        .awidth      (awidth),
        .instr_width (instr_width)
    ) store (
        .we_s       (wrEn_i),            // write-enable to store logic
        .opcode_s   (instr_i[6:0]),      // extract RISC-V opcode
        .func3_s    (instr_i[14:12]),    // extract RISC-V func3
        .addr_s     (addr_i),            // full byte-address
        .dataw_s    (data_i),            // raw write-data from core
        .dataWr_s   (dataWr_s),          // output of store_block
        .prev_data  (prev)               // the old value at that location
    );

    load_block #(
        .dwidth      (dwidth),
        .awidth      (awidth),
        .instr_width (instr_width)
    ) load (
        .rdEn_i    (rdEn_i),             // read-enable to load logic
        .opcoder_s (instr_i[6:0]),       // RISC-V opcode for loads
        .func3r_s  (instr_i[14:12]),     // RISC-V func3 for loads
        .addr_i    (addr_i),             // full byte-address
        .dataRd_s  (dataRd_s),           // raw read-data from RAM
        .data_o    (data_o)              // final load output to core
    );

    //--------------------------------------------------------------------
    // 4) On rising edge of clk, if wrEn_i and opcode==STORE, perform write
    //--------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        // RISC-V store opcode = 7'b0100011
        if (wrEn_i && (instr_i[6:0] == 7'b0100011)) begin
            ram_s[ addr_i[awidth-1:3] ] <= dataWr_s;
        end
    end

endmodule
