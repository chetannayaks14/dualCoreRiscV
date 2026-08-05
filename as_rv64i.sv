// ==============================
// as_rv64i Module
// ==============================
`timescale 1ns/1ps

module as_rv64i(
    input logic clk_i,
    input logic rst_i,
    input logic [31:0] inst_i,
    input logic [63:0] wdata_i,
    output logic [1:0] resultsrc_o,
    output logic dmemrd_o,
    output logic dmemwr_o,
    output logic [reg_width-1:0] aluresult_o,
    output logic [63:0] pc_o, //64 bit
    output logic [63:0] pc_plus4_o,
    //output logic data_o,
    output logic [63:0] rdata01_o
);   


//control signals
logic         pcsrc_s;
logic [2:0]   immsrc_s;
logic         regwr_s;
logic [5:0]   alusel_s;
logic         alusrca_s;
logic         alusrcb_s;
logic         jump_s;
logic         aluzero_s;
logic           aluNega_s;          //between   alu            &   controlall
logic           aluCarr_s;          //between   alu            &   controlall
logic           aluOver_s;          //between   alu            &   controlall


// Datapath
as_datapath datapath(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .pcsrc_i(pcsrc_s),
    .immsrc_i(immsrc_s),
    .inst_i(inst_i),
    .regwr_i(regwr_s),
    .alusel_i(alusel_s),
    .alusrca_i(alusrca_s),
    .alusrcb_i(alusrcb_s),
    .jump_i(jump_s),
    .aluzero_o(aluzero_s),
    .pc_o(pc_o),
    .wdata_i(wdata_i),
    .aluresult_o(aluresult_o),
    .pc_plus4_o(pc_plus4_o),
    .rdata01_o(rdata01_o),  //data_o
    .aluNega_o(aluNega_s),
    .aluCarr_o(aluCarr_s),
    .aluOver_o(aluOver_s)
);


//Controlall
ControlAll controlall(
    
    .instruction(inst_i),
    .PCSrc(pcsrc_s),
    .immSrc(immsrc_s),
    .regWr(regwr_s),
    .aluSrcA(alusrca_s),
    .aluSrcB(alusrcb_s),
    .jump(jump_s),
    .zero(aluzero_s),
    .aluSel(alusel_s),
    .resultSrc(resultsrc_o),
    .dMemRd(dmemrd_o),
    .dMemWr(dmemwr_o),
    .carry(aluCarr_s),
    .negative(aluNega_s),
    .overflow(aluOver_s)
);

endmodule : as_rv64i
