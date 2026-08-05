// =========================================
// as_core.sv   (uses ControlAll instead of as_controlunitmain)
// =========================================
`timescale 1ns/1ps

import as_pack::*;

module as_core #(
    parameter gpio_inst_width = 64
)(
    input  logic            clk_i,           // Clock signal
    input  logic            rst_i,           // Reset signal

    // -------- Cache Interface --------
    output logic [63:0]     cache_addr_o,    // Address to cache
    output logic [63:0]     cache_wr_data_o, // Write-data to cache
    output logic            cache_rdEn_o,    // Read-enable to cache
    output logic            cache_wrEn_o,    // Write-enable to cache
    input  logic [63:0]     cache_rd_data_i, // Read-data from cache

    // -------- GPIO for "as_top" output --------
    output logic [7:0]      gpio_o
);

    // ----------------------------------------------------------------
    // 1) Instruction Fetch / IMEM + PC advance
    // ----------------------------------------------------------------
    logic [63:0]    pc_s;         // current PC
    logic [63:0]    pc_plus4_s;   // PC + 4
    logic [31:0]    inst_s;       // fetched instruction

    // Compute PC + 4
    assign pc_plus4_s = pc_s + 64'd4;

    // Instantiate program counter (as_pc)
    //   Ports: pcnext_i, clk_i, rst_i, pc_o
    as_pc pc0 (
        .pcnext_i  (pc_plus4_s),
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .pc_o      (pc_s)
    );

    // Private Instruction Memory (as_imem)
    //   Ports: pc_i, inst_o, clk_i
    as_imem imem0 (
        .pc_i    (pc_s),
        .inst_o  (inst_s),
        .clk_i   (clk_i)
    );

    // ----------------------------------------------------------------
    // 2) CONTROL: Replace as_controlunitmain with ControlAll
    // ----------------------------------------------------------------
    logic [5:0]    alusel_s;
    logic          regwr_s;
    logic          alusrca_s;
    logic          alusrcb_s;
    logic          dMemRd_s;
    logic          dMemWr_s;
    logic          pcsrc_s;
    logic [2:0]    immsrc_s;
    logic          jump_s;
    logic [1:0]    resultsrc_s;

    // For now, tie all ALU-status flags to 0. If you later compute real flags,
    // connect them here (e.g. zero_flag, carry_flag, negative_flag, overflow_flag).
    ControlAll ctrl0 (
        .instruction (inst_s),
        .zero        (1'b0),
        .carry       (1'b0),
        .negative    (1'b0),
        .overflow    (1'b0),

        .aluSel      (alusel_s),
        .regWr       (regwr_s),
        .aluSrcA     (alusrca_s),
        .aluSrcB     (alusrcb_s),
        .dMemRd      (dMemRd_s),
        .dMemWr      (dMemWr_s),
        .PCSrc       (pcsrc_s),
        .immSrc      (immsrc_s),
        .jump        (jump_s),
        .resultSrc   (resultsrc_s)
    );

 // ----------------------------------------------------------------
// 3) Immediate Generator (fixed port names)
// ----------------------------------------------------------------
logic [63:0]    imm_s;
as_immgen imm0 (
    .sel_i (immsrc_s),  // matches "input logic [immsrc_width-1:0] sel_i"
    .inst_i(inst_s),    // matches "input logic [instr_width-1:0] inst_i"
    .imm_o (imm_s)      // matches "output logic [reg_width-1:0] imm_o"
);
       // ----------------------------------------------------------------
    // 4) Register File (port names corrected)
    // ----------------------------------------------------------------
    logic [63:0]    rdata01_s, rdata02_s;
    logic [4:0]     rs1_s, rs2_s, rd_s;

    assign rs1_s = inst_s[19:15];
    assign rs2_s = inst_s[24:20];
    assign rd_s  = inst_s[11:7];


   as_regfile reg0 (
       .clk_i       (clk_i),        // matches "input logic clk_i"
       .rst_i       (rst_i),        // matches "input logic rst_i"
       .wren_i      (regwr_s),      // matches "input logic wren_i"
       .raddr01_i   (rs1_s),        // matches "input logic [4:0] raddr01_i"
       .raddr02_i   (rs2_s),        // matches "input logic [4:0] raddr02_i"       .waddr_i     (rd_s),         // matches "input logic [4:0] waddr_i"
       .wdata_i     (y_s),          // matches "input logic [63:0] wdata_i"
       .rdata01_o   (rdata01_s),    // matches "output logic [63:0] rdata01_o"
       .rdata02_o   (rdata02_s)     // matches "output logic [63:0] rdata02_o"
   );

    // ----------------------------------------------------------------
    // 5) ALU and Data Path (unchanged)
    // ----------------------------------------------------------------
    logic [63:0]    aluresult_s, operandA_s, operandB_s;
    logic [63:0]    y_s;            // final result back to register file

  // MUX for ALU operand A
// as_mux1 ports: (pcp4_i, pcbr_i, pcsrc_i, pcnext_o)
as_mux1 mux1 (
    .pcp4_i    (rdata01_s),   // if sel=0, choose rdata01_s
    .pcbr_i    (pc_s),        // if sel=1, choose pc_s
    .pcsrc_i   (alusrca_s),   // select signal
    .pcnext_o  (operandA_s)   // output goes to operandA_s
);

   // MUX for ALU operand B
// as_mux2 ports: (data01_i, pc_i, alusrca_i, data01_o)
as_mux2 mux2 (
    .data01_i   (rdata02_s),   // if alusrcb=0, choose rdata02_s
    .pc_i       (imm_s),       // if alusrcb=1, choose imm_s
    .alusrca_i  (alusrcb_s),   // select signal (here using alusrcb_s)
    .data01_o   (operandB_s)   // output goes to operandB_s
);

    // ALU instantiation with correct ports from as_alu.sv
as_alu alu0 (
    .srca_i      (operandA_s),    // matches "input logic [63:0] srca_i"
    .srcb_i      (operandB_s),    // matches "input logic [63:0] srcb_i"
    .alusel_i    (alusel_s),      // matches "input logic [5:0]  alusel_i"
    .aluzero_o   (aluzero_s),     // matches "output logic       aluzero_o"
    .aluNega_o   (aluNega_s),     // matches "output logic       aluNega_o"
    .aluCarr_o   (aluCarr_s),     // matches "output logic       aluCarr_o"
    .aluOver_o   (aluOver_s),     // matches "output logic       aluOver_o"
    .aluresult_o (aluresult_s)    // matches "output logic [63:0] aluresult_o"
);

    // ----------------------------------------------------------------
    // 6) Build Memory-Access Signals (Cache interface)
    // ----------------------------------------------------------------
    // Now directly use dMemRd_s and dMemWr_s from ControlAll to drive the cache.
    assign cache_addr_o    = aluresult_s;   // effective address
    assign cache_wr_data_o = rdata01_s;     // store data from rdata01_s
    assign cache_rdEn_o    = dMemRd_s;      // memory-read enable
    assign cache_wrEn_o    = dMemWr_s;      // memory-write enable

    // Rename the read-data from cache to "data_s"
    logic [63:0]    data_s;
    assign data_s = cache_rd_data_i;

    // ----------------------------------------------------------------
    // 7) MUX5: select between ALU result vs data_s vs PC+4
    // ----------------------------------------------------------------
    as_mux5 mux5 (
        .pcp4_i        (pc_plus4_s),
        .dmemoutput_i  (data_s),
        .aluresult_i   (aluresult_s),
        .resultsrc_i   (resultsrc_s),
        .y_o           (y_s)
    );

    // ----------------------------------------------------------------
    // 8) GPIO (unchanged)
    // ----------------------------------------------------------------
    as_gpio gpio0 (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .gpio_addr_i    (aluresult_s),
        .gpio_data_i    (rdata01_s),
        .gpio_o         (gpio_o)
    );

endmodule
