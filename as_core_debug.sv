// =============================================
// as_core_debug.sv   (Core with per-cycle debug prints)
// =============================================
`timescale 1ns/1ps

import as_pack::*;

module as_core_debug #(
    parameter gpio_inst_width = 64
)(
    input  logic            clk_i,          // Clock
    input  logic            rst_i,          // Reset (active-high)
    input  logic  [2:0]     core_id_i,      // 0 or 1
    input  logic [31:0]     inst_i,         // Fetched instruction
    input  logic [63:0]     base_addr_i,    // preload x10
    input  logic [63:0]     N_i,            // preload x11
    input  logic  [2:0]     preset_id_i,    // preload x12, x16 = (THREAD_ID << 3)

    output logic [63:0]     pc_s,           // Exposed PC
    // -------- Cache Interface --------
    output logic [63:0]     cache_addr_o,
    output logic [63:0]     cache_wr_data_o,
    output logic            cache_rdEn_o,
    output logic            cache_wrEn_o,
    input  logic [63:0]     cache_rd_data_i,
    // -------- GPIO (unused) --------
    output logic [7:0]      gpio_o
);

    // 1) PROGRAM COUNTER (as_pc)
    logic [63:0] pc_plus4_s;
    assign pc_plus4_s = pc_s + 64'd4;

    as_pc pc0 (
        .pcnext_i  (pc_plus4_s),
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .pc_o      (pc_s)
    );

    // 2) INSTRUCTION REGISTER (inst_s)
    logic [31:0] inst_s;
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            inst_s <= 32'd0;
        else
            inst_s <= inst_i;
    end

    // 3) CONTROL UNIT (ControlAll)
    logic          regwr_s, alusrca_s, alusrcb_s;
    logic [5:0]    alusel_s;
    logic [2:0]    immsrc_s;
    logic [1:0]    resultsrc_s;

    ControlAll ctrl0 (
        .instruction  (inst_s),
        .zero         (1'b0),
        .carry        (1'b0),
        .negative     (1'b0),
        .overflow     (1'b0),
        .aluSel       (alusel_s),
        .regWr        (regwr_s),
        .aluSrcA      (alusrca_s),
        .aluSrcB      (alusrcb_s),
        .dMemRd       (cache_rdEn_o),
        .dMemWr       (cache_wrEn_o),
        .PCSrc        (/*unused*/),
        .immSrc       (immsrc_s),
        .jump         (/*unused*/),
        .resultSrc    (resultsrc_s)
    );

    // 4) IMMEDIATE GENERATOR (as_immgen)
    logic [63:0] imm_s;
    as_immgen imm0 (
        .sel_i   (immsrc_s),
        .inst_i  (inst_s),
        .imm_o   (imm_s)
    );

    // 5) REGISTER FILE (as_regfile with preload)
    logic [63:0] rdata01_s, rdata02_s;
    logic [4:0]  rs1_s, rs2_s, rd_s;

    assign rs1_s = inst_s[19:15];
    assign rs2_s = inst_s[24:20];
    assign rd_s  = inst_s[11:7];

    as_regfile reg0 (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .base_addr_i (base_addr_i),
        .N_i         (N_i),
        .preset_id_i (preset_id_i),
        .raddr01_i   (rs1_s),
        .raddr02_i   (rs2_s),
        .waddr_i     (rd_s),
        .wdata_i     (y_s),
        .wren_i      (regwr_s),
        .rdata01_o   (rdata01_s),
        .rdata02_o   (rdata02_s)
    );

    // 6) ALU DATAPATH
    logic [63:0]    operandA_s, operandB_s, aluresult_s;

    // MUX1: choose between rdata01_s vs pc_s
    as_mux1 mux1 (
        .pcp4_i   (rdata01_s),
        .pcbr_i   (pc_s),
        .pcsrc_i  (alusrca_s),
        .pcnext_o (operandA_s)
    );

    // MUX2: choose between rdata02_s vs imm_s
    as_mux2 mux2 (
        .data01_i (rdata02_s),
        .pc_i     (imm_s),
        .alusrca_i(alusrcb_s),
        .data01_o (operandB_s)
    );

    as_alu alu0 (
        .srca_i      (operandA_s),
        .srcb_i      (operandB_s),
        .alusel_i    (alusel_s),
        .aluzero_o   (/*unused*/),
        .aluNega_o   (/*unused*/),
        .aluCarr_o   (/*unused*/),
        .aluOver_o   (/*unused*/),
        .aluresult_o (aluresult_s)
    );

    // 7) CACHE INTERFACE
    assign cache_addr_o    = aluresult_s;
    assign cache_wr_data_o = rdata01_s;
    // cache_rdEn_o and cache_wrEn_o come directly from ControlAll

    // raw data from cache/shared memory:
    logic [63:0] data_s_pre;
    assign data_s_pre = cache_rd_data_i;

    // post-load_block result (sign/zero extension according to func3):
    logic [63:0] data_s;

    // Instantiate load_block to handle byte/half/word loads:
    load_block #(
      .dwidth      (64),
      .awidth      (64),
      .instr_width (32)
    ) u_load_block (
      .rdEn_i    (cache_rdEn_o),     // "is-load?" from ControlAll
      .opcoder_s (inst_s[6:0]),      // raw opcode bits [6:0]
      .func3r_s  (inst_s[14:12]),    // raw func3 bits [14:12]
      .addr_i    (aluresult_s),      // effective byte address from ALU
      .dataRd_s  (data_s_pre),       // raw 64-bit word read from cache
      .data_o    (data_s)            // extended byte/half/word/word or full 64-bit
    );

    // 8) MUX5: select between ALU result vs data_s vs PC+4
    logic [63:0] y_s;
    as_mux5 mux5 (
        .pcp4_i        (pc_plus4_s),
        .dmemoutput_i  (data_s),
        .aluresult_i   (aluresult_s),
        .resultsrc_i   (resultsrc_s),
        .y_o           (y_s)
    );

    // 9) GPIO (unchanged)
    as_gpio gpio0 (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .gpio_addr_i (aluresult_s),
        .gpio_data_i (rdata01_s),
        .gpio_o      (gpio_o)
    );

    // 10) PER-CYCLE DEBUG PRINT
    always_ff @(posedge clk_i) begin
        if (!rst_i) begin
            $display("[%0t] Core%0d: PC=0x%08h INST=0x%08h ALU_WB=0x%016h",
                     $time,
                     core_id_i,
                     pc_s,
                     inst_s,
                     y_s);
        end
    end

endmodule
