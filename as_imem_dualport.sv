// ================================================
// as_imem_dualport.sv   (256×32-bit IMEM with two read ports)
// ================================================
`timescale 1ns/1ps

module as_imem_dualport (
    input  logic [63:0] pc0_i,    // Core0's PC
    input  logic [63:0] pc1_i,    // Core1's PC
    output logic [31:0] inst0_o,  // Instruction for Core0
    output logic [31:0] inst1_o,  // Instruction for Core1
    input  logic        clk_i     // (not used for combinational read)
);
    // 256 entries of 32-bit instructions per core
    (* ram_style = "distributed" *) reg [31:0] ram0 [0:255];
    (* ram_style = "distributed" *) reg [31:0] ram1 [0:255];

    initial begin
        //─────────────────────────────────────────────────────────────────
        //  Core 0's 10-instruction sequence (starts at byte-address 0x00)
        //
        //   0x00: ADDI x1, x0,   9   → x1 =  9
        //   0x04: ADDI x2, x1,   5   → x2 = x1 + 5
        //   0x08: ADD  x3, x1,  x2  → x3 = x1 + x2
        //   0x0C: ADD  x4, x3,  x2  → x4 = x3 + x2
        //   0x10: LD   x5,   8(x0)  → x5 ← [base+8]
        //   0x14: ADD  x6, x3,  x5  → x6 = x3 + x5
        //   0x18: LD   x7,  16(x0)  → x7 ← [base+16]
        //   0x1C: SUB  x8, x7,  x5  → x8 = x7 - x5
        //   0x20: SD   x16,   0(x0) → store x16 (just example)
        //   0x24: NOP                → do nothing
        //─────────────────────────────────────────────────────────────────
        ram0[ 8'h00 ] = 32'h0090_0093; // ADDI x1, x0,  9
        ram0[ 8'h01 ] = 32'h0050_8113; // ADDI x2, x1,  5
        ram0[ 8'h02 ] = 32'h0020_81B3; // ADD  x3, x1, x2
        ram0[ 8'h03 ] = 32'h0021_8233; // ADD  x4, x3, x2
        ram0[ 8'h04 ] = 32'h0080_3283; // LD   x5,   8(x0)
        ram0[ 8'h05 ] = 32'h0031_83B3; // ADD  x6, x3, x5
        ram0[ 8'h06 ] = 32'h0100_2383; // LD   x7,  16(x0)
        ram0[ 8'h07 ] = 32'h4052_03B3; // SUB  x8, x7, x5  (func7=0x20, func3=000 ⇒ SUB)
        ram0[ 8'h08 ] = 32'h0100_0023; // SD   x16,  0(x0)
        ram0[ 8'h09 ] = 32'h0000_0013; // NOP

        // Fill the rest of Core0's ROM with NOP
        for (int i = 10; i < 256; i++) begin
            ram0[i] = 32'h0000_0013;
        end

        //─────────────────────────────────────────────────────────────────
        //  Core 1's 10-instruction sequence (starts at byte-address 0x00)
        //
        //   0x00: ADDI x1, x0,   3   → x1 =  3
        //   0x04: ADDI x2, x1,   7   → x2 = x1 + 7
        //   0x08: ADD  x3, x1,  x2  → x3 = x1 + x2
        //   0x0C: ADD  x4, x3,  x2  → x4 = x3 + x2
        //   0x10: LD   x5,    8(x0)  → x5 ← [base+8]
        //   0x14: ADD  x6, x3,  x5  → x6 = x3 + x5
        //   0x18: LD   x7,   16(x0)  → x7 ← [base+16]
        //   0x1C: SUB  x8, x7,  x5  → x8 = x7 - x5
        //   0x20: SD   x17,  0(x0)  → store x17 (just example)
        //   0x24: NOP                → do nothing
        //─────────────────────────────────────────────────────────────────
        ram1[ 8'h00 ] = 32'h0030_0093; // ADDI x1, x0,  3
        ram1[ 8'h01 ] = 32'h0070_8113; // ADDI x2, x1,  7
        ram1[ 8'h02 ] = 32'h0020_81B3; // ADD  x3, x1, x2
        ram1[ 8'h03 ] = 32'h0021_8233; // ADD  x4, x3, x2
        ram1[ 8'h04 ] = 32'h0080_3283; // LD   x5,   8(x0)
        ram1[ 8'h05 ] = 32'h0031_83B3; // ADD  x6, x3, x5
        ram1[ 8'h06 ] = 32'h0100_2383; // LD   x7,  16(x0)
        ram1[ 8'h07 ] = 32'h4052_03B3; // SUB  x8, x7, x5
        ram1[ 8'h08 ] = 32'h0110_0023; // SD   x17,  0(x0)
        ram1[ 8'h09 ] = 32'h0000_0013; // NOP

        // Fill the rest of Core1's ROM with NOP
        for (int i = 10; i < 256; i++) begin
            ram1[i] = 32'h0000_0013;
        end
    end

    always_comb begin
        // PC is always word-aligned → use PC[9:2] as the RAM index
        inst0_o = ram0[ pc0_i[9:2] ];
        inst1_o = ram1[ pc1_i[9:2] ];
    end
endmodule
