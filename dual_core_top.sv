// ===============================================
// dual_core_top.sv
//    Two-Core MIMD + MESI Caches + Shared Memory + LED Heartbeat
// ===============================================
`timescale 1ns/1ps

module dual_core_top #(
  parameter int ADDR_WIDTH   = 64,
  parameter int DATA_WIDTH   = 64,
  parameter int INDEX_WIDTH  = 8,
  parameter int OFFSET_WIDTH = 3
)(
  input  logic        clk,
  input  logic        reset,
  output logic [7:0]  led_o
);

  // I) Dual-Port Instruction Memory
  wire [63:0] pc0, pc1;
  wire [31:0] inst0, inst1;
  as_imem_dualport imem0 (
    .pc0_i   (pc0), .pc1_i   (pc1),
    .inst0_o (inst0), .inst1_o (inst1),
    .clk_i   (clk)
  );

  // II) Core ↔ Cache Wires
  logic [63:0] c0_addr, c0_wdata, c1_addr, c1_wdata;
  logic        c0_rdEn, c0_wrEn, c1_rdEn, c1_wrEn;
  logic [63:0] c0_rdata, c1_rdata;
  logic        c0_busy, c1_busy;

  // III) Two RISC-V Cores (debug)
  logic [63:0] base = 64'h2000, len = 100;
  logic [7:0]  gpio0, gpio1;
  as_core_debug core0 (
    .clk_i(clk), .rst_i(reset), .core_id_i(3'd0),
    .inst_i(inst0), .base_addr_i(base), .N_i(len), .preset_id_i(3'd0),
    .pc_s(pc0),
    .cache_addr_o(c0_addr), .cache_wr_data_o(c0_wdata),
    .cache_rdEn_o(c0_rdEn), .cache_wrEn_o(c0_wrEn),
    .cache_rd_data_i(c0_rdata), .gpio_o(gpio0)
  );
  as_core_debug core1 (
    .clk_i(clk), .rst_i(reset), .core_id_i(3'd1),
    .inst_i(inst1), .base_addr_i(base), .N_i(len), .preset_id_i(3'd0),
    .pc_s(pc1),
    .cache_addr_o(c1_addr), .cache_wr_data_o(c1_wdata),
    .cache_rdEn_o(c1_rdEn), .cache_wrEn_o(c1_wrEn),
    .cache_rd_data_i(c1_rdata), .gpio_o(gpio1)
  );

  // IV) MESI Coherence Bus Wires
  logic               br0, br1, bg0, bg1, bs0, bs1, sr0, sr1, sa0, sa1;
  logic [1:0]         bc0, bc1, sc0, sc1;
  logic [ADDR_WIDTH-1:0] ba0, ba1;

  // Cache instances
  cache_blk #(
    .ADDR_WIDTH   (ADDR_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH),
    .INDEX_WIDTH  (INDEX_WIDTH),
    .OFFSET_WIDTH (OFFSET_WIDTH)
  ) cache0 (
    .clk(clk), .reset(reset),
    .rdEn(c0_rdEn), .wrEn(c0_wrEn), .addr(c0_addr),
    .wr_data(c0_wdata), .rd_data(c0_rdata), .busy(c0_busy),
    .bus_req(br0), .bus_cmd(bc0), .bus_addr(ba0),
    .bus_grant(bg0), .bus_shared(bs0),
    .snoop_req(sr0), .snoop_cmd(sc0), .snoop_ack(sa0),
    .mem_data_i(smrdata)
  );
  cache_blk #(
    .ADDR_WIDTH   (ADDR_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH),
    .INDEX_WIDTH  (INDEX_WIDTH),
    .OFFSET_WIDTH (OFFSET_WIDTH)
  ) cache1 (
    .clk(clk), .reset(reset),
    .rdEn(c1_rdEn), .wrEn(c1_wrEn), .addr(c1_addr),
    .wr_data(c1_wdata), .rd_data(c1_rdata), .busy(c1_busy),
    .bus_req(br1), .bus_cmd(bc1), .bus_addr(ba1),
    .bus_grant(bg1), .bus_shared(bs1),
    .snoop_req(sr1), .snoop_cmd(sc1), .snoop_ack(sa1),
    .mem_data_i(smrdata)
  );

  // Simple fixed-priority arbiter: core0 > core1
  always_comb begin
    bg0 = 1'b0; bg1 = 1'b0;
    if (br0)      bg0 = 1'b1;
    else if (br1) bg1 = 1'b1;
  end

  // Broadcast snoops
  assign sr0 = bg1; assign sc0 = bc1;
  assign sr1 = bg0; assign sc1 = bc0;

  // Shared-line flags only on GETS (2'b00)
  assign bs0 = (bc0 == 2'b00) ? sa1 : 1'b0;
  assign bs1 = (bc1 == 2'b00) ? sa0 : 1'b0;

  // V) Shared-Memory Arbiter port
  logic                smr, smw;
  logic [ADDR_WIDTH-1:0] smaddr;
  logic [DATA_WIDTH-1:0] smwdata, smrdata;
  assign smw   = (bg0 && bc0==2'b01) || (bg1 && bc1==2'b01);
  assign smr   = (bg0 && (bc0==2'b00||bc0==2'b01))
               || (bg1 && (bc1==2'b00||bc1==2'b01));
  assign smaddr  = bg0 ? ba0 : ba1;
  assign smwdata = bg0 ? c0_wdata : c1_wdata;
  shared_mem #(
    .dwidth      (DATA_WIDTH),
    .awidth      (ADDR_WIDTH),
    .instr_width (32),
    .mdepth      (4096)
  ) mem (
    .clk_i   (clk),
    .wrEn_i  (smw),
    .rdEn_i  (smr),
    .addr_i  (smaddr),
    .instr_i (32'd0),
    .data_i  (smwdata),
    .data_o  (smrdata)
  );

  // VI) Heartbeat & LEDs
  logic [31:0] hb;
  always_ff @(posedge clk or posedge reset) begin
    if (reset) hb <= 32'd0;
    else       hb <= hb + 32'd1;
  end
  assign led_o[0]   = hb[24];
  assign led_o[7:1] = smrdata[6:0];

endmodule