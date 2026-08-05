// ==============================
// as_top Module (Updated)
// ==============================
`timescale 1ns/1ps

import as_pack::*;

module as_top #(parameter gpio_inst_width = 64)(
    input  logic                     clk_i,         // Clock signal
    input  logic                     rst_i,         // Reset signal
    //input  logic [31:0]              inst_i,        // Output of imem

    //output logic [63:0]              pc_o,          // Input for Imem
    output logic [7:0]              gpio_o        // GPIO output data
);

    // Control signals
    logic dmemwr_s;                // Write enable for DMEM
    logic dmemrd_s;                // Read enable for DMEM
    logic [1:0] resultsrc_s;       // Result source control
    logic [63:0] pc_plus4_s;       // PC + 4 value
    logic [63:0] rdata01_s;        // Read data from Register File
    logic [63:0] aluresult_s;      // ALU result
    logic [63:0] y_s;              // Data written to Register File
    logic [31:0] inst_s;
    logic [63:0] data_s;           // Data read from DMEM

    // GPIO control and chip select
    logic [63:0] pc_s;

    //assign inst_s = inst_i;

    as_imem inst_mem(
        .pc_i(pc_s),
        .inst_o(inst_s)
    );

 

    

    // RV64I Core
    as_rv64i rv64i (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dmemrd_o(dmemrd_s),
        .dmemwr_o(dmemwr_s),
        .resultsrc_o(resultsrc_s),
        .pc_plus4_o(pc_plus4_s),
        .rdata01_o(rdata01_s),
        .aluresult_o(aluresult_s),
        .inst_i(inst_s),
        .wdata_i(y_s),
        .pc_o(pc_s)
    );

    // DMEM
    data_mem dmem (
        .clk_i(clk_i),
        .addr_i(aluresult_s),
        .data_i(rdata01_s),
        .instr_i(inst_s),
        .rdEn_i(dmemrd_s),
        .wrEn_i(dmemwr_s),
        .data_o(data_s)
    );

    // MUX5
    as_mux5 mux5 (
        .pcp4_i(pc_plus4_s),
        .dmemoutput_i(data_s),
        .aluresult_i(aluresult_s),
        .resultsrc_i(resultsrc_s),
        .y_o(y_s)
    );

    // GPIO
    as_gpio gpio (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .gpio_addr_i(aluresult_s),
        .gpio_data_i(rdata01_s),
        .gpio_o(gpio_o)
    );

endmodule
