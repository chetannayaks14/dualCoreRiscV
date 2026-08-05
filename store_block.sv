// store_block.v
`timescale 1ns / 1ps

module store_block #(
    parameter int dwidth = 64,        // Data width (default: 64 bits)
    parameter int awidth = 64,        // Address width (default: 64 bits)
    parameter int instr_width = 32    // Instruction width (default: 32 bits)
)(
    input  logic                   we_s,         // Write enable
    input  logic [6:0]             opcode_s,     // Opcode from instruction
    input  logic [2:0]             func3_s,      // Func3 from instruction
    input  logic [awidth-1:0]      addr_s,       // Address input
    input  logic [dwidth-1:0]      dataw_s,      // Write data input
    input  logic [dwidth-1:0]      prev_data,    // Previous data from memory
    output logic [dwidth-1:0]      dataWr_s      // Data to write to memory
);

    always_comb begin
        // Initialize dataWr_s with previous memory data (read-modify-write behavior)
        dataWr_s = prev_data;

        // Check for store operation
        if (we_s && opcode_s == 7'b0100011) begin
            case (func3_s)
                3'b000: begin // Store Byte (SB)
                    automatic logic [2:0] byte_offset = addr_s[2:0];
                    dataWr_s[8*byte_offset +: 8] = dataw_s[7:0];
                end

                3'b001: begin // Store Half-word (SH)
                    if (addr_s[awidth-1:1] % 4 == 0)
                        dataWr_s[15:0] = dataw_s[15:0];
                    else if (addr_s[awidth-1:1] % 4 == 1)
                        dataWr_s[31:16] = dataw_s[15:0];
                    else if (addr_s[awidth-1:1] % 4 == 2)
                        dataWr_s[47:32] = dataw_s[15:0];
                    else
                        dataWr_s[63:48] = dataw_s[15:0];
                end

                3'b010: begin // Store Word (SW)
                    if (addr_s[awidth-1:2] % 2 == 0)
                        dataWr_s[31:0] = dataw_s[31:0];
                    else
                        dataWr_s[63:32] = dataw_s[31:0];
                end

                3'b011: begin // Store Double-word (SD)
                    dataWr_s = dataw_s;
                end

                default: begin
                    // Handle unexpected func3 values gracefully
                    dataWr_s = dataw_s;
                end
            endcase
        end
    end

endmodule
