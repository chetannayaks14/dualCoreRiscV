// =============================================
// as_imem.sv  (Shared instruction memory for both cores)
// =============================================
`timescale 1ns/1ps

module as_imem (
    input  logic [63:0] pc_i,     // PC from CPU domain (word-aligned)
    output logic [31:0] inst_o,   // Instruction output
    input  logic        clk_i     // Unused (combinational read)
);

    // 256 × 32-bit words
    (* ram_style = "distributed" *) reg [31:0] ram [255:0];

    initial begin
        // ------------------------------------------------
        //  0: 0x00900093 → ADDI x1, x0, 9
        //  1: 0x00508113 → ADDI x2, x1, 5
        //  2: 0x002081B3 → ADD  x3, x1, x2
        //  3: 0x00218233 → ADD  x4, x3, x2
        //  4: 0x00803283 → LD   x5, 8(x0)       ; Core0→load A[0], Core1→load A[1]
        //  5: 0x00003303 → ADD  x6, x0, x6      ; (we will treat as ADD x6,x3,x5)
        //  6: 0x00402383 → LD   x7,16(x0)       ; Core0→load A[2], Core1→load A[3]
        //  7: 0x00000013 → NOP
        //  … fill NOP until word 0x88/4 = 0x22 …
        //  0x22: 0x01000023 → SD   x16, 0(x0)   ; store partial_sum at address in x16
        // ------------------------------------------------

        ram[0]  = 32'h0090_0093;
        ram[1]  = 32'h0050_8113;
        ram[2]  = 32'h0020_81B3;
        ram[3]  = 32'h0021_8233;
        ram[4]  = 32'h0080_3283;
        ram[5]  = 32'h0000_3303;
        ram[6]  = 32'h0040_2383;
        ram[7]  = 32'h0000_0013;

        // pad with NOPs up through index 0x21 (decimal 33)
        for (int i = 8; i < 34; i++) begin
            ram[i] = 32'h0000_0013;
        end

        // at word index 0x22 (decimal 34):
        ram[34] = 32'h0100_0023;  // SD x16, 0(x0)

        // remaining entries all NOP
        for (int i = 35; i < 256; i++) begin
            ram[i] = 32'h0000_0013;
        end
    end

    always_comb begin
        // PC is word-aligned, so use bits [9:2]
        inst_o = ram[pc_i[9:2]];
    end

endmodule
