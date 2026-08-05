// ==========================================
// ControlAll.sv  (Control Unit "decode-all")
// ==========================================
`timescale 1ns/1ps

module ControlAll(
    input  logic [31:0] instruction, // 32-bit instruction
    input  logic        zero,        // ALU zero flag
    input  logic        carry,       // ALU carry flag
    input  logic        negative,    // ALU negative flag
    input  logic        overflow,    // ALU overflow flag

    output logic [5:0]  aluSel,      // 6-bit ALU operation select
    output logic        regWr,       // Register write enable
    output logic        aluSrcA,     // ALU input A select
    output logic        aluSrcB,     // ALU input B select
    output logic        dMemRd,      // Data memory read enable
    output logic        dMemWr,      // Data memory write enable
    output logic        PCSrc,       // Program counter source (branch/jump)
    output logic [2:0]  immSrc,      // Immediate source select
    output logic        jump,        // Jump enable
    output logic [1:0]  resultSrc,   // Result source (ALU/Data/PC+4)

    // ─────────── NEW OUTPUTS ───────────
    output logic [6:0]  ID_Opcode,   // raw opcode bits = instruction[6:0]
    output logic [2:0]  ID_func3     // raw func3 bits = instruction[14:12]
    // ────────────────────────────────────
);

    logic [6:0] opcode;
    logic [2:0] func3;
    logic       func7b5;

    // Extract opcode/func3/func7[5] from the instruction
    assign opcode   = instruction[6:0];
    assign func3    = instruction[14:12];
    assign func7b5  = instruction[30];       // bit 30 is func7[5]

    // ─── Drive the two new outputs straight from the instruction bits ───
    assign ID_Opcode = instruction[6:0];      // "carry raw opcode into pipeline"
    assign ID_func3  = instruction[14:12];    // "carry raw func3 into pipeline"
    // (Note: we have not renamed dMemRd/dMemWr here. We still drive them as before.)

    always_comb begin
        // Defaults
        aluSel    = 6'b000000;
        regWr     = 1'b0;
        aluSrcA   = 1'b0;
        aluSrcB   = 1'b0;
        dMemRd    = 1'b0;
        dMemWr    = 1'b0;
        PCSrc     = 1'b0;
        immSrc    = 3'b000;
        jump      = 1'b0;
        resultSrc = 2'b00;

        case (opcode)
            //------------------------------------------------------------
            // R-TYPE (OP) : 0b0110011
            //------------------------------------------------------------
            7'b0110011: begin 
                regWr   = 1'b1;
                aluSrcA = 1'b0;
                aluSrcB = 1'b0;
                resultSrc = 2'b00; // ALU result → REG

                case (func3)
                    3'b000: aluSel = (func7b5) ? 6'b000001 : 6'b000000; // SUB / ADD
                    3'b001: aluSel = 6'b010100; // SLL
                    3'b010: aluSel = 6'b001001; // SLT
                    3'b011: aluSel = 6'b001101; // SLTU
                    3'b100: aluSel = (instruction[31:25] == 7'b0000001) 
                                     ? 6'bxxxxxx : 6'b000111; // DIV or XOR (undefined DIV)
                    3'b101: aluSel = (func7b5) ? 6'b010010 : 6'b010011; // SRA / SRL
                    3'b110: aluSel = (instruction[31:25] == 7'b0000001) 
                                     ? 6'b001010 : 6'b000101; // REM / OR
                    3'b111: aluSel = 6'b000011; // AND
                    default: aluSel = 6'bxxxxxx;
                endcase
                $display("R-Type Decode: opcode=%b, func3=%b, func7[5]=%b → aluSel=%b", 
                          opcode, func3, func7b5, aluSel);
            end

            //------------------------------------------------------------
            // R-TYPE WORD (OP-W): 0b0111011
            //------------------------------------------------------------
            7'b0111011: begin 
                regWr   = 1'b1;
                aluSrcA = 1'b0;
                aluSrcB = 1'b0;
                resultSrc = 2'b00;

                case (func3)
                    3'b000: aluSel = (instruction[31:25] == 7'b0000000) 
                                     ? 6'b001100 : 6'b010001; // ADDW / SUBW
                    3'b001: aluSel = 6'b011001; // SLLW
                    3'b101: aluSel = (instruction[31:25] == 7'b0000000) 
                                     ? 6'b010110 : 6'b011000; // SRLIW / SRAIW
                    default: aluSel = 6'bxxxxxx;
                endcase
            end

            //------------------------------------------------------------
            // I-TYPE (OP-IMM): 0b0010011
            //------------------------------------------------------------
            7'b0010011: begin 
                regWr   = 1'b1;
                aluSrcA = 1'b0;
                aluSrcB = 1'b1;
                immSrc  = 3'b000; 
                resultSrc = 2'b00; 
                case (func3)
                    3'b000: aluSel = 6'b000010; // ADDI
                    3'b001: aluSel = 6'b010101; // SLLI
                    3'b010: aluSel = 6'b001011; // SLTI
                    3'b011: aluSel = 6'b001111; // SLTIU
                    3'b101: aluSel = (instruction[31:25] == 7'b0000000) 
                                     ? 6'b111110 : 6'b111101; // SRLI / SRAI
                    3'b100: aluSel = 6'b001000; // XORI
                    3'b110: aluSel = 6'b000110; // ORI
                    3'b111: aluSel = 6'b000100; // ANDI
                    default: aluSel = 6'bxxxxxx;
                endcase
            end

            //------------------------------------------------------------
            // I-TYPE WORD (OP-IMM-W): 0b0011011
            //------------------------------------------------------------
            7'b0011011: begin 
                regWr   = 1'b1;
                aluSrcA = 1'b0;
                aluSrcB = 1'b1;
                immSrc  = 3'b000; 
                resultSrc = 2'b00; 
                case (func3)
                    3'b000: aluSel = 6'b011110; // ADDIW
                    3'b001: aluSel = 6'b011010; // SLLIW
                    3'b101: aluSel = (instruction[31:25] == 7'b0000000) 
                                     ? 6'b011100 : 6'b010111; // SRLIW / SRAIW
                    default: aluSel = 6'bxxxxxx;
                endcase
            end

            //------------------------------------------------------------
            // LOAD (I-TYPE): 0b0000011
            //------------------------------------------------------------
            7'b0000011: begin 
                regWr     = 1'b1;
                aluSrcA   = 1'b0;
                aluSrcB   = 1'b1;
                dMemRd    = 1'b1;       // "is a load"
                resultSrc = 2'b01;      // memory → reg
                immSrc    = 3'b000;
                aluSel    = 6'b000010;  // ADD for address

                case (func3)
                    3'b000: aluSel = 6'b100100; // LB
                    3'b001: aluSel = 6'b100110; // LH
                    3'b010: aluSel = 6'b101000; // LW
                    3'b011: aluSel = 6'b101010; // LD
                    3'b100: aluSel = 6'b100101; // LBU
                    3'b101: aluSel = 6'b100111; // LHU
                    3'b110: aluSel = 6'b101001; // LWU
                    default: aluSel = 6'bxxxxxx;
                endcase
            end

            //------------------------------------------------------------
            // STORE (S-TYPE): 0b0100011
            //------------------------------------------------------------
            7'b0100011: begin 
                regWr     = 1'b0;
                aluSrcA   = 1'b0;
                aluSrcB   = 1'b1;
                dMemWr    = 1'b1;       // "is a store"
                immSrc    = 3'b001;
                aluSel    = 6'b000000; // ADD for address
                case (func3)
                    3'b000: aluSel = 6'b110000; // SB
                    3'b001: aluSel = 6'b110001; // SH
                    3'b010: aluSel = 6'b110010; // SW
                    3'b011: aluSel = 6'b110011; // SD
                    default: aluSel = 6'bxxxxxx;
                endcase
            end

            //------------------------------------------------------------
            // BRANCH (B-TYPE): 0b1100011
            //------------------------------------------------------------
            7'b1100011: begin 
                PCSrc   = 1'b0; 
                aluSrcA = 1'b0;
                aluSrcB = 1'b0;
                immSrc  = 3'b010;

                case (func3)
                    3'b000: begin // BEQ
                        aluSel = 6'b011101; // SUB
                        PCSrc  = zero;
                    end
                    3'b001: begin // BNE
                        aluSel = 6'b011111; // SUB
                        PCSrc  = ~zero;
                    end
                    3'b100: begin // BLT
                        aluSel = 6'b100001; // SLT
                        PCSrc  = negative ^ overflow;
                    end
                    3'b101: begin // BGE
                        aluSel = 6'b001001; // SLT
                        PCSrc  = ~(negative ^ overflow);
                    end
                    3'b110: begin // BLTU
                        aluSel = 6'b100011; // SLTU
                        PCSrc  = ~carry;
                    end
                    3'b111: begin // BGEU
                        aluSel = 6'b100000; // SLTU
                        PCSrc  = carry;
                    end
                    default: begin
                        aluSel = 6'bxxxxxx;
                        PCSrc  = 1'b0;
                    end
                endcase
            end

            //------------------------------------------------------------
            // LUI (U-TYPE): 0b0110111
            //------------------------------------------------------------
            7'b0110111: begin 
                regWr     = 1'b1;
                aluSrcA   = 1'b0;
                aluSrcB   = 1'b1;     // immediate only (upper bits)
                immSrc    = 3'b100;
                aluSel    = 6'b110100; // no ALU operation, just pass imm
                resultSrc = 2'b00;
            end

            //------------------------------------------------------------
            // AUIPC (U-TYPE): 0b0010111
            //------------------------------------------------------------
            7'b0010111: begin 
                regWr     = 1'b1;
                aluSrcA   = 1'b1;     // PC
                aluSrcB   = 1'b1;     // immediate
                immSrc    = 3'b100;
                aluSel    = 6'b110110; // ADD
                resultSrc = 2'b00;
            end

            //------------------------------------------------------------
            // JAL (J-TYPE): 0b1101111
            //------------------------------------------------------------
            7'b1101111: begin 
                regWr     = 1'b1;
                jump      = 1'b1;
                PCSrc     = 1'b1;     // unconditional jump
                immSrc    = 3'b011;
                aluSel    = 6'b110000; // no ALU op (PC+4 → x[rd])
                resultSrc = 2'b10;    // PC+4 → reg[rd]
            end

            //------------------------------------------------------------
            // JALR (I-TYPE): 0b1100111
            //------------------------------------------------------------
            7'b1100111: begin 
                regWr     = 1'b1;
                jump      = 1'b1;
                PCSrc     = 1'b1;     // unconditional jump (register base)
                immSrc    = 3'b000;
                aluSel    = 6'b101110; // ADD
                resultSrc = 2'b10;    // PC+4 → reg[rd]
            end

            //------------------------------------------------------------
            // DEFAULT: no operation
            //------------------------------------------------------------
            default: begin 
                regWr     = 1'b0;
                aluSrcA   = 1'b0;
                aluSrcB   = 1'b0;
                dMemRd    = 1'b0;
                dMemWr    = 1'b0;
                PCSrc     = 1'b0;
                immSrc    = 3'b000;
                jump      = 1'b0;
                resultSrc = 2'b00;
                aluSel    = 6'bxxxxxx;
            end
        endcase
    end
endmodule
