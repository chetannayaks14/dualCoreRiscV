//module datapath
`timescale 1ns/1ps

import as_pack::*;

module as_datapath(
    input  logic                           clk_i,
    input  logic                           rst_i,
    input  logic                           pcsrc_i,         //from ControlAll to pcsrc mux(mux_1)(trigger)
    input  logic [31:0]                    inst_i,          //from Instruction memory to instruction(read,write address ) fro reg file, instruction for controlall
    input  logic                           regwr_i,         //from controlall to register file write enable(trigger)
    input  logic                           alusrca_i,       //from controlall to alusrca mux(trigger)
    input  logic [63:0]                    wdata_i,         //from mux5 to register file
    input  logic                           alusrcb_i,       //from controlall to alusrcb mux(trigger)
    input  logic [5:0]                     alusel_i,        //from controlall to alu(trigger)
    input  logic [2:0]                     immsrc_i,        //from controlall to immediate extender(trigger)
    input  logic                           jump_i,          //from controlall to jumpjalr(trigger)
    output logic [63:0]                    rdata01_o,       //from register file to datamemory
    output logic [63:0]                    pc_o,            //from pc to Instruction memory
    output logic                           aluzero_o,       //from alu to controlall
    output logic [63:0]                    pc_plus4_o,     //from pcplus4 to mux5
    output logic [reg_width-1:0]           aluresult_o,     //from alu to data memory
    output logic                           aluNega_o,
    output logic                           aluCarr_o,
    output logic                           aluOver_o

);

//control signals in datapath
logic [63:0]    pc_plus4_s;         //between   mux1           &   pcp4
logic [63:0]    pcbr_s;             //between   mux1           &   pcbr
logic [63:0]    pcnext_s;           //between   mux1           &   pc
logic [63:0]    pc_s;               //between   pc             &   pcp4    &     mux2    &     mux4
logic [63:0]    rdata02_s;          //between   register file  &   mux2    &     mux4
logic [63:0]    rdata01_s;          //between   register file  &   mux3 
logic [63:0]    data01_s;           //between   mux2           &   alu
logic [63:0]    data02_s;           //between   mux3           &   alu
logic [63:0]    imm_s;              //between   extendall      &   mux3    &     pcbr
logic [63:0]    y_s;                //between   mux4           &   pcbr

//mux_1
as_mux1 mux1(
    .pcp4_i(pc_plus4_s),
    .pcbr_i(pcbr_s),
    .pcsrc_i(pcsrc_i),
    .pcnext_o(pcnext_s)
);


//Program counter
as_pc pc(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .pcnext_i(pcnext_s),
    .pc_o(pc_o)  // Connect pc_o to external signal
);
assign pc_s=pc_o;  // Internal signal pc_s gets the value of pc_o


//Register File
as_regfile regfile(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wren_i(regwr_i),
    .raddr01_i(inst_i[19:15]),
    .raddr02_i(inst_i[24:20]),
    .waddr_i(inst_i[11:7]),
    .wdata_i(wdata_i),
    .rdata02_o(rdata01_o),
    .rdata01_o(rdata02_s)
);
assign rdata01_s=rdata01_o; 


//Mux_2
as_mux2 mux2(
    .data01_i(rdata02_s),
    .pc_i(pc_s),
    .alusrca_i(alusrca_i),
    .data01_o(data01_s)
);


//Mux_3
as_mux3 mux3(
    .data02_i(rdata01_s),
    .imm_i(imm_s),
    .alusrcb_i(alusrcb_i),
    .data02_o(data02_s)
);


//ALU
as_alu alu(
    
    .srca_i(data01_s),
    .srcb_i(data02_s),
    .alusel_i(alusel_i),
    .aluzero_o(aluzero_o),
    .aluresult_o(aluresult_o),
    .aluNega_o(aluNega_o),
    .aluCarr_o(aluCarr_o),
    .aluOver_o(aluOver_o)
);


//Pcp4 adder
as_pcp4 pcp4(
    .pc_i(pc_s),
    .pc_plus4_o(pc_plus4_o)
);
assign pc_plus4_s=pc_plus4_o;

//Extend all
as_immgen immgen(
    
    .inst_i(inst_i[31:0]),
    .sel_i(immsrc_i),
    .imm_o(imm_s)
);


//Mux_4
as_mux4 mux4(
    .pc_i(pc_s),
    .jalr_i(rdata02_s),
    .jump_i(jump_i),
    .y_o(y_s)
);



//Pcbr_adder
as_pcbr pbcbr(
    .data01_i(y_s),
    .imm_i(imm_s),
    .pcbr_o(pcbr_s)
);

endmodule : as_datapath