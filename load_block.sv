// =============================================================
// load_block.sv
//   - Decodes RISC-V load instructions and selects/sign-extends
//     the proper byte/halfword/word/doubleword from a 64-bit read
// =============================================================
`timescale 1ns/1ps

module load_block #(
    parameter dwidth      = 64,
    parameter awidth      = 64,
    parameter instr_width = 32
)(
    input  logic             rdEn_i,      // "is-load?" from EX→MEM stage
    input  logic [6:0]       opcoder_s,   // raw opcode (for completeness, not used here)
    input  logic [2:0]       func3r_s,    // func3 (load subtype)
    input  logic [awidth-1:0] addr_i,      // effective address from ALU
    input  logic [dwidth-1:0] dataRd_s,    // raw 64-bit data read from data memory
    output logic [dwidth-1:0] data_o       // correctly sliced+extended load result
);

    // ────────────────────────────────────────────────────────────
    // Index calculations (must be declared outside procedural block
    // to avoid "must explicitly be declared automatic or static")
    // ────────────────────────────────────────────────────────────
    logic [2:0] byte_index;   // selects one of 8 bytes (0..7)
    logic [1:0] half_index;   // selects one of 4 halfwords (0..3)
    logic       word_index;   // selects one of 2 words     (0..1)

    // ────────────────────────────────────────────────────────────
    // always_comb: pick the right portion of dataRd_s and sign/zero-extend
    // ────────────────────────────────────────────────────────────
    always_comb begin
        // default: zero-output if not a load
        data_o = '0;

        if (rdEn_i) begin
            // compute indices based on low bits of addr_i
            byte_index = addr_i[2:0];
            half_index = addr_i[2:1];
            word_index = addr_i[2];

            unique case (func3r_s)
                //-------------------------------------------------------
                // LB (3'b000): load byte, sign-extend to 64 bits
                //-------------------------------------------------------
                3'b000: begin
                    // pick out one 8-bit byte at (byte_index * 8)
                    logic [7:0] byte_data;
                    byte_data = dataRd_s >> (byte_index * 8);

                    // sign-extend to 64 bits
                    data_o = {{56{byte_data[7]}}, byte_data};
                end

                //-------------------------------------------------------
                // LH (3'b001): load halfword, sign-extend to 64 bits
                //-------------------------------------------------------
                3'b001: begin
                    // pick out one 16-bit halfword at (half_index * 16)
                    logic [15:0] half_data;
                    half_data = dataRd_s >> (half_index * 16);

                    // sign-extend to 64 bits
                    data_o = {{48{half_data[15]}}, half_data};
                end

                //-------------------------------------------------------
                // LW (3'b010): load word, sign-extend to 64 bits
                //-------------------------------------------------------
                3'b010: begin
                    // pick out one 32-bit word at (word_index * 32)
                    logic [31:0] word_data;
                    word_data = dataRd_s >> (word_index * 32);

                    // sign-extend to 64 bits
                    data_o = {{32{word_data[31]}}, word_data};
                end

                //-------------------------------------------------------
                // LD (3'b011): load doubleword (64 bits) - just pass through
                //-------------------------------------------------------
                3'b011: begin
                    data_o = dataRd_s;
                end

                //-------------------------------------------------------
                // LBU (3'b100): load byte, zero-extend to 64 bits
                //-------------------------------------------------------
                3'b100: begin
                    logic [7:0] byte_data;
                    byte_data = dataRd_s >> (byte_index * 8);
                    data_o    = {56'd0, byte_data};
                end

                //-------------------------------------------------------
                // LHU (3'b101): load halfword, zero-extend to 64 bits
                //-------------------------------------------------------
                3'b101: begin
                    logic [15:0] half_data;
                    half_data = dataRd_s >> (half_index * 16);
                    data_o    = {48'd0, half_data};
                end

                //-------------------------------------------------------
                // LWU (3'b110): load word, zero-extend to 64 bits
                //-------------------------------------------------------
                3'b110: begin
                    logic [31:0] word_data;
                    word_data = dataRd_s >> (word_index * 32);
                    data_o    = {32'd0, word_data};
                end

                //-------------------------------------------------------
                // (3'b111 is reserved for atomic/unused in RV64I) 
                //-------------------------------------------------------
                default: begin
                    data_o = '0;
                end
            endcase
        end
    end

endmodule
