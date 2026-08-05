// tb_dual_core_top.sv
`timescale 1ns/1ps

module tb_dual_core_top;

  // Clock & reset
  logic clk, reset;

  // DUT: same ports as dual_core_top.sv
  dual_core_top dut (
    .clk   (clk),
    .reset (reset),
    .led_o ()    // leave unconnected
  );

  // Clock gen: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset pulse
  initial begin
    reset = 1;
    #20;
    reset = 0;
  end

  // Advance N cycles
  task automatic run_cycles(input int n);
    repeat(n) @(posedge clk);
  endtask

  // Temporaries
  logic [63:0] m8, expected, actual;
  logic [31:0] pc_before, pc_after;

  // Main test
  initial begin
    @(negedge reset);
    $display("\n=== TESTBENCH START ===\n");

    ////////////////////////////////////////////////////
    // A: Arithmetic Startup
    ////////////////////////////////////////////////////
    $display("A: Arithmetic Startup");
    run_cycles(4);
    run_cycles(2);   // allow writeback
    // core0 x1..x4
    assert(dut.core0.reg0.regfile_s[1]==9)  else $error("Core0 x1!=9");
    assert(dut.core0.reg0.regfile_s[2]==14) else $error("Core0 x2!=14");
    assert(dut.core0.reg0.regfile_s[3]==23) else $error("Core0 x3!=23");
    assert(dut.core0.reg0.regfile_s[4]==37) else $error("Core0 x4!=37");
    $display("  Core0: x1=%0d, x2=%0d, x3=%0d, x4=%0d",
             dut.core0.reg0.regfile_s[1],
             dut.core0.reg0.regfile_s[2],
             dut.core0.reg0.regfile_s[3],
             dut.core0.reg0.regfile_s[4]);
    // core1 x1..x4
    assert(dut.core1.reg0.regfile_s[1]==3)  else $error("Core1 x1!=3");
    assert(dut.core1.reg0.regfile_s[2]==10) else $error("Core1 x2!=10");
    assert(dut.core1.reg0.regfile_s[3]==13) else $error("Core1 x3!=13");
    assert(dut.core1.reg0.regfile_s[4]==23) else $error("Core1 x4!=23");
    $display("  Core1: x1=%0d, x2=%0d, x3=%0d, x4=%0d\n",
             dut.core1.reg0.regfile_s[1],
             dut.core1.reg0.regfile_s[2],
             dut.core1.reg0.regfile_s[3],
             dut.core1.reg0.regfile_s[4]);

    ////////////////////////////////////////////////////
    // B: Load from address 8 (expect 0)
    ////////////////////////////////////////////////////
    $display("B: Load from address 8 (should be 0)");
    run_cycles(2);
    run_cycles(2);
    m8 = dut.mem.ram_s[8>>3];  // = ram_s[1]
    assert(dut.core0.reg0.regfile_s[5]==m8)
      else $error("Core0 LD got %0d, expected %0d",dut.core0.reg0.regfile_s[5],m8);
    assert(dut.core1.reg0.regfile_s[5]==m8)
      else $error("Core1 LD got %0d, expected %0d",dut.core1.reg0.regfile_s[5],m8);
    $display("  Both loaded %0d from MEM[8]\n", m8);

    ////////////////////////////////////////////////////
    // C: Store to address 0 (both cores) - expect MEM[0]=0
    ////////////////////////////////////////////////////
    $display("C: Store to address 0 by both cores");
    run_cycles(2);
    run_cycles(1);
    assert(dut.mem.ram_s[0]==0)
      else $error("MEM[0]!=0 after stores");
    $display("  MEM[0]=%0d\n", dut.mem.ram_s[0]);

    ////////////////////////////////////////////////////
    // D: Load from address 16 (expect 0)
    ////////////////////////////////////////////////////
    $display("D: Load from address 16 (should be 0)");
    run_cycles(2);
    run_cycles(2);
    expected = dut.mem.ram_s[16>>3];  // ram_s[2]
    actual   = dut.core0.reg0.regfile_s[7];
    assert(actual==expected)
      else $error("Coherence: x7=%0d, expected %0d",actual,expected);
    $display("  Coherent: core0 x7=%0d\n", actual);

    ////////////////////////////////////////////////////
    // E: Stall injection
    ////////////////////////////////////////////////////
    $display("E: Stall injection");
    force dut.mem.rdEn_i=0;
    run_cycles(1);
    release dut.mem.rdEn_i;
    $display("  Stall released\n");

    ////////////////////////////////////////////////////
    // F: Out-of-bounds read
    ////////////////////////////////////////////////////
    $display("F: Out-of-bounds read MEM[0xFF]");
    $display("  MEM[0xFF]=%0d\n", dut.mem.ram_s[8'hFF>>3]);

    ////////////////////////////////////////////////////
    // G: NOP behavior
    ////////////////////////////////////////////////////
    $display("G: NOP only advances PC by 4");
    pc_before=dut.pc0; run_cycles(1); pc_after=dut.pc0;
    assert(pc_after==pc_before+4)
      else $error("NOP PC %0h->%0h",pc_before,pc_after);
    $display("  PC %0h->%0h\n",pc_before,pc_after);

    ////////////////////////////////////////////////////
    // H: Dual-port IMEM
    ////////////////////////////////////////////////////
    $display("H: Dual-port IMEM");
    @(posedge clk);
    assert(dut.imem0.inst0_o!==32'hx && dut.imem0.inst1_o!==32'hx)
      else $error("IMEM invalid");
    $display("  inst0=%0h, inst1=%0h\n",dut.imem0.inst0_o,dut.imem0.inst1_o);

    ////////////////////////////////////////////////////
    // I: Final register checks
    ////////////////////////////////////////////////////
    $display("I: Final register checks");
    run_cycles(2);
    $display("  Core0 x16=%0d", dut.core0.reg0.regfile_s[16]);
    $display("  Core1 x17=%0d\n", dut.core1.reg0.regfile_s[17]);

    $display("=== TESTBENCH COMPLETE ===\n");
    $finish;
  end

  // Global collision monitor, but skip addr==0
  always @(posedge clk) begin
    if (dut.cache0.wrEn && dut.cache1.wrEn &&
        dut.cache0.addr!=64'h0 &&
        dut.cache0.addr==dut.cache1.addr) begin
      $error("Collision at %h at time %0t", dut.cache0.addr, $time);
    end
  end

endmodule

