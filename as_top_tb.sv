`timescale 1ns/1ps

module as_fintop_tb;

    // Signals and Ports
    logic clk_i;
    logic rst_i;
    logic [7:0] gpio_o;    // GPIO Output from DUT

    // Clock Parameters
    localparam integer CLK_PERIOD = 10;

    // Instantiate the DUT
    as_top dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .gpio_o(gpio_o)
    );

    // Clock Generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    // Testbench Logic
    initial begin
        // Open simulation
        $display("Starting Simulation");

        // Initialize inputs
        rst_i = 1;
        #(2 * CLK_PERIOD);
        rst_i = 0;

        // Wait for a few clock cycles to observe behavior
        #(100 * CLK_PERIOD);

        // Finish Simulation
        $display("Ending Simulation");
        `ifndef SYNTHESIS
    $finish;
`endif

    end

endmodule
