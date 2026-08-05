//------------------------------------------------------------------------------
// cache_blk.sv
//    Direct‐mapped cache block with full MESI coherence
//    *** NO LED OBUFs, NO shared_mem here ***
//------------------------------------------------------------------------------
module cache_blk #(
  parameter int ADDR_WIDTH   = 64,
  parameter int DATA_WIDTH   = 64,
  parameter int INDEX_WIDTH  = 8,
  parameter int OFFSET_WIDTH = 3,
  parameter int TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
  input  logic                   clk,
  input  logic                   reset,

  // CPU-side interface
  input  logic                   rdEn,
  input  logic                   wrEn,
  input  logic [ADDR_WIDTH-1:0]  addr,
  input  logic [DATA_WIDTH-1:0]  wr_data,
  output logic [DATA_WIDTH-1:0]  rd_data,
  output logic                   busy,

  // Coherence bus interface
  output logic                   bus_req,
  output logic [1:0]             bus_cmd,     // 00=GETS,01=GETM,10=UPGR
  output logic [ADDR_WIDTH-1:0]  bus_addr,
  input  logic                   bus_grant,
  input  logic                   bus_shared,

  // Snoop interface
  input  logic                   snoop_req,
  input  logic [1:0]             snoop_cmd,
  output logic                   snoop_ack,

  // Memory data input
  input  logic [DATA_WIDTH-1:0]  mem_data_i
);

  //==========================================================================
  // MESI state encoding
  typedef enum logic [1:0] {
    S_I = 2'b00,
    S_S = 2'b01,
    S_E = 2'b10,
    S_M = 2'b11
  } mesi_t;
  mesi_t state;

  //==========================================================================
  // Tag & Data arrays
  localparam int NUM_LINES = 1 << INDEX_WIDTH;
  logic [TAG_WIDTH-1:0]   tag_array  [NUM_LINES];
  logic [DATA_WIDTH-1:0]  data_array [NUM_LINES];

  // Address decode
  wire [INDEX_WIDTH-1:0]  idx     = addr[OFFSET_WIDTH +: INDEX_WIDTH];
  wire [TAG_WIDTH-1:0]    req_tag = addr[ADDR_WIDTH-1 -: TAG_WIDTH];

  //==========================================================================
  // 1) Read port (registered only)
  logic [TAG_WIDTH-1:0]   curr_tag;
  logic [DATA_WIDTH-1:0]  curr_data;
  always_ff @(posedge clk) begin
    curr_tag  <= tag_array[idx];
    curr_data <= data_array[idx];
  end
  assign rd_data = curr_data;

  //==========================================================================
  // 2) Write port (registered only, mutually-exclusive cases)
  always_ff @(posedge clk) begin
    if (bus_grant && bus_req) begin
      // refill on GETS or GETM grant using memory data
      tag_array[idx]  <= req_tag;
      data_array[idx] <= mem_data_i;
    end
    else if (wrEn && (state==S_E || state==S_M) && curr_tag==req_tag) begin
      // write-hit in Exclusive or Modified
      data_array[idx] <= wr_data;
    end
    // else: no write, registers keep their old value
  end

  //==========================================================================
  // Hit / Miss detection
  logic tag_match   = (state != S_I) && (curr_tag == req_tag);
  logic hit_read    = rdEn  && tag_match;
  logic hit_write   = wrEn  && tag_match && (state==S_E || state==S_M);
  logic miss_read   = rdEn  && !hit_read;
  logic miss_write  = wrEn  && !hit_write;

  //==========================================================================
  // 3) MESI FSM + busy
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state     <= S_I;
      bus_req   <= 1'b0;
      bus_cmd   <= 2'b00;
      bus_addr  <= '0;
      snoop_ack <= 1'b0;
      busy      <= 1'b0;
    end else begin
      // defaults
      bus_req   <= 1'b0;
      snoop_ack <= 1'b0;
      // busy if handling a miss or Shared→Modified upgrade
      busy      <= (miss_read || miss_write) ||
                   (rdEn && hit_write && state==S_S);

      // CPU access: decide GETS, GETM or UPGR when not busy
      if (!busy) begin
        if (hit_read || hit_write) begin
          // on a write-hit in Shared, send an UPGRADE
          if (wrEn && state==S_S) begin
            bus_req  <= 1'b1;
            bus_cmd  <= 2'b10;
            bus_addr <= addr;
          end
        end else begin
          // on miss, GETS for reads, GETM for writes
          bus_req  <= 1'b1;
          bus_cmd  <= (wrEn ? 2'b01 : 2'b00);
          bus_addr <= addr;
        end
      end

      // on bus grant, update state to S/E or M
      if (bus_grant && bus_req) begin
        unique case (bus_cmd)
          2'b00: state <= (bus_shared ? S_S : S_E); // GETS → Shared/Exclusive
          2'b01,                                    // GETM
          2'b10: state <= S_M;                     // GETM or UPGR → Modified
        endcase
      end

      // snoop from peer: downgrade or invalidate
      if (snoop_req && tag_match) begin
        unique case (snoop_cmd)
          2'b00: // peer GETS → downgrade E/M→S
            if (state==S_E || state==S_M) begin
              state     <= S_S;
              snoop_ack <= 1'b1;
            end
          2'b01, // peer GETM
          2'b10: // peer UPGR
            begin
              state     <= S_I;  // invalidate
              snoop_ack <= 1'b1;
            end
        endcase
      end
    end
  end

endmodule