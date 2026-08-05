`timescale 1ns/1ps
 //import as_pack::*; 

module as_alu #(
    parameter reg_width = 64,       // Register width
    parameter aluselrv_width = 6    // ALU selection width
) (
    input  logic [reg_width-1:0]          srca_i,
    input  logic [reg_width-1:0]          srcb_i,
    input  logic [aluselrv_width-1:0]     alusel_i,
    output logic                          aluzero_o,
    output logic                          aluNega_o,
    output logic                          aluCarr_o,
    output logic                          aluOver_o,
    output logic [reg_width-1:0]          aluresult_o
);
                
 //signals declaration for control flags 
 logic carry_s;                 // carry of the adder; double add
 logic carryw_s;                // carry of the adder; word
 logic overf_s;                 // overflow
 
 // signed signals declaration
 logic signed [reg_width-1:0] data01_s; // must be signed for arithmetic shift
 logic signed [reg_width-1:0] data02_s; // must be signed for arithmetic 
 logic signed [31:0] data01w_s;
 logic signed [31:0] data02w_s;

 // signals declaration for double add 
  logic	aluCont1_s;              // inverted aluSel_i[1]
  logic	[reg_width-1:0] sum_s;   // sum of the adder; double
  logic [reg_width-1:0]	cinvb_s; // conditional inverted data02_i

  // signals declaration for word add
  logic	[31:0] sumw_s;           // sum of the adder; word
  logic [31:0] cinvbw_s;         // conditional inverted data02_i

  // signals declaration for  shift word 
  logic [31:0] sllw_s, srlw_s;
  logic signed [31:0] sraw_s;
  
  //signals declaration for set less than
  logic	slt_s, sltu_s, slti_s, sltiu_s;
  logic [63:0] slt_64_s, slti_64_s, sltu_64_s, sltiu_64_s;
  
  //signals declaration for branch operations
  logic bge_s, bgeu_s, beq_s, bne_s;
  logic [63:0] bge_64_s, bgeu_64_s, beq_64_s, bne_64_s;
  
  //assigning signals 
  assign data01_s = srca_i;
  assign data02_s = srcb_i;
  assign data01w_s = srca_i[31:0];
  
  
  // double add operation logic
  assign cinvb_s = alusel_i[0] ? ~srcb_i : srcb_i;          // for 2comp
  assign {carry_s, sum_s}   = srca_i + cinvb_s + alusel_i[0]; // ... carry in

  // word add operation logic
  assign cinvbw_s = alusel_i[0] ? ~srcb_i[31:0] : srcb_i[31:0];           // for 2comp
  assign {carryw_s, sumw_s}   = srca_i[31:0] + cinvbw_s + alusel_i[0];   // ... carry in
  
 // shifting operations logic 
  assign sllw_s = srca_i[31:0] <<  srcb_i[5:0];
  assign srlw_s = srca_i[31:0] >>  srcb_i[5:0];
  assign sraw_s = data01w_s >>> srcb_i[5:0];
 

  // overflow logic  
  assign aluCont1_s = ~alusel_i[1];     // alusel_i[1]: 1 
  assign overf_s = ~(alusel_i[0] ^ srcb_i[reg_width-1] ^ srca_i[reg_width-1]) & 
                    (srca_i[reg_width-1] ^ sum_s[reg_width-1]) & 
                    ~(alusel_i[1]);
                    
 //set less than logic
  assign slt_s       =  sum_s[reg_width-1] ^ overf_s;
  assign slt_64_s    =  slt_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign sltu_s      =  (srca_i < srcb_i) ? 1'b1 : 1'b0;
  assign sltu_64_s   =  sltu_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign slti_s      =  sum_s[reg_width-1] ^ overf_s;
  assign slti_64_s   =  slti_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign sltiu_s     =  (srca_i < srcb_i) ? 1'b1 : 1'b0;
  assign sltiu_64_s  =  sltiu_s ? 64'hffffffffffffffff : 64'h0000000000000000;

  // branch operations logic
  assign bge_s       = (data01_s >= data02_s) ? 1'b1 : 1'b0;
  assign bge_64_s    =  bge_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign bgeu_s      = (srca_i >= srcb_i) ? 1'b1 : 1'b0;
  assign bgeu_64_s   =  bgeu_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign beq_s       = (srca_i == srcb_i) ? 1'b1 : 1'b0;
  assign beq_64_s    =  beq_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  assign bne_s       = (srca_i != srcb_i) ? 1'b0 : 1'b1;
  assign bne_64_s    =  bne_s ? 64'hffffffffffffffff : 64'h0000000000000000;
  

  always_comb 
  begin
    case(alusel_i)
    // value : 0
      6'b000000  :       aluresult_o = sum_s;                           // ADD Operation
    // value : 1
      6'b000001  :       aluresult_o = sum_s;                           // SUBTRACT Operation
    // value : 3
      6'b000011  :       aluresult_o = srca_i & srcb_i;                 // AND Operation
    // value : 5
      6'b000101  :       aluresult_o = srca_i | srcb_i;                 // OR Operation
    // value : 7
      6'b000111  :       aluresult_o = srca_i ^ srcb_i;                 // XOR Operation
    // value : 9
      6'b001001  :       aluresult_o = slt_64_s;                        // SLT (signed)
    // value : 13
      6'b001101  :       aluresult_o = sltu_64_s;                       // SLTU (unsigned)
    // value : 18
      6'b010010  :       aluresult_o = data01_s >>> srcb_i[5:0];        // SRA Operation
    // value : 19
      6'b010011  :       aluresult_o = srca_i >>  srcb_i[5:0];        // SRL Operation
    // value : 20
      6'b010100  :       aluresult_o = srca_i <<  srcb_i[5:0];        // SLL Operation
   
      
              // Immediate Operations
              
    // value : 2
      6'b000010  :       aluresult_o = sum_s;                           // ADDI Immediate Operation
    // value : 4
      6'b000100  :       aluresult_o = srca_i & srcb_i;                 // ANDI Immediate Operation  
    // value : 6
      6'b000110  :       aluresult_o = srca_i | srcb_i;                 // ORI Immediate Operation    
    // value : 8
      6'b001000  :       aluresult_o = srca_i ^ srcb_i;                 // XORI Immediate Operation
    // value : 11
      6'b001011  :       aluresult_o = slti_64_s;                       // SLTI (signed)
    // value : 15
      6'b001111  :       aluresult_o = sltiu_64_s;                      // SLTIU (unsigned) 
    // value : 21
      6'b010101  :       aluresult_o = srca_i <<  srcb_i[5:0];          // SLLI Immediate Operation
    // value : 14
      6'b111110  :       aluresult_o = srca_i >>  srcb_i[5:0];          // SRLI Immediate Operation 
    // value : 16
      6'b111101  :       aluresult_o = data01_s >>> srcb_i[5:0];        // SRAI Immediate Operation    
             
             
              // Word Operations
              
    // value : 12
      6'b001100  :       aluresult_o = {{32{sumw_s[31]}},sumw_s};       // ADDW
    // value : 17
      6'b010001  :       aluresult_o = {{32{sumw_s[31]}},sumw_s};       // SUBW
    // value : 22
      6'b011000  :       aluresult_o = {{32{sraw_s[31]}},sraw_s};       // SRAW Word Operation
    // value : 24
      6'b010110  :       aluresult_o = {{32{srlw_s[31]}},srlw_s};       // SRLW Word Operation  
    // value : 25
      6'b011001  :       aluresult_o = {{32{sllw_s[31]}},sllw_s};       // SLLW Word Operation 
    
      
                  // Immediate Word Operations
                                 
    // value : 28              
     6'b011110  :        aluresult_o = {{32{sumw_s[31]}},sumw_s};       // ADDIW Immediate Word Operation
    // value : 23
      6'b010111  :       aluresult_o = {{32{sraw_s[31]}},sraw_s};       // SRAIW Immediate Word Operation
    // value : 27
      6'b011100  :       aluresult_o = {{32{sraw_s[31]}},srlw_s};       // SRLIW Immediate Word Operation  
    // value : 26
      6'b011010  :       aluresult_o = {{32{sllw_s[31]}},sllw_s};       // SLLIW Immediate Operation  
     
       //6'b010111  : aluresult_o = {{32{sraw_s[31]}},sraw_s};             // sraiw 
      
                  
                   // Branch Operations
                   
                   
    // value : 29
      6'b011101  :       aluresult_o =  beq_64_s;                        // beq
    // value : 31
      6'b011111  :       aluresult_o =  bne_64_s;                        // bne
    // value : 33
      6'b100001  :       aluresult_o =  slt_64_s;                       // blt signed
    // value : 35
      6'b100011  :       aluresult_o =  sltu_64_s;                      //bltu unsigned
    // value : 30
      6'b001001  :       aluresult_o =  bge_64_s;                       // bge signed
    // value : 32
      6'b100000  :       aluresult_o =  bgeu_64_s;                       // bgeu unsigned
         
                 
                  // Load Operations
                  
                  
    // value : 36      
    6'b100100  :         aluresult_o = data01_s + data02_s;                    // Signed Load Byte (LB)
    // value : 37
    6'b100101  :         aluresult_o = srca_i + srcb_i;                        // Unsigned Load Byte (LBU)
    // value : 38
    6'b100110  :         aluresult_o = (data01_s + data02_s) ;         // Signed Load Half Word (LH)
    // value : 39
    6'b100111  :         aluresult_o = (srca_i + srcb_i) ;             // Unsigned Load Half Word (LHU)
    // value : 40
    6'b101000  :         aluresult_o = (data01_s + data02_s);         // Signed Load Word (LW)
    // value : 41
    6'b101001  :         aluresult_o = (srca_i + srcb_i) ;             // Unsigned Load Word (LWU)
    // value : 42
    6'b101010  :         aluresult_o = (srca_i + srcb_i);             // Load Double Word (LD)

                   
                   // Store Operations
                   
                   
    // value : 43               
    6'b110000  :        aluresult_o = srca_i + srcb_i;                     // Store Byte (SB) 
    // value : 44
    6'b110001  :        aluresult_o = srca_i + srcb_i;          // Store Half (SH)
    // value : 45
    6'b110010  :        aluresult_o = srca_i + srcb_i;          // Store Word (SW)
    // value : 46
    6'b110011  :        aluresult_o = srca_i + srcb_i;          // Store Double Word (SD)
                  
                  // Jump and link Operations
   // value : 48               
   6'b110000  :       aluresult_o = sum_s;                                    // jalr
   // value : 50               
   6'b101110  :       aluresult_o = sum_s;                                    // jal
    
                
                
                 // load upper immediate and add upper immediate
                 
                 
   // value : 52               
    6'b110100  :      aluresult_o = data02_s;                                 // lui
   // value : 54               
    6'b110110  :      aluresult_o = sum_s;                                    // auipc
    
   
    
      default: aluresult_o = 64'b0;
    endcase
  end 


  assign aluzero_o = (aluresult_o == 0) ? 0 : 1;
  assign aluNega_o = aluresult_o [reg_width-1];
  assign aluCarr_o = carry_s;
  assign aluOver_o = overf_s;

endmodule 
