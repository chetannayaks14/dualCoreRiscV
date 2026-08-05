// ==============================
// as_gpio Module (Updated)
// ==============================
`timescale 1ns/1ps

import as_pack::*;

module as_gpio #(parameter gpio_inst_width = 64)(
    input  logic                         clk_i,        // System clock
    input  logic                         rst_i,        // Reset signal
    input  logic [63:0]                  gpio_addr_i,  // GPIO address input
    input  logic [63:0]                  gpio_data_i,  // GPIO input data
    output logic [7:0]                   gpio_o        // GPIO Output
);

logic [1:0]  cs_s;
logic [63:0] gpio_addr_s;
logic [63:0] gpio_data_s;
always_comb begin
    case (gpio_addr_i) inside
            [64'h00000000_00000000:64'h00000000_000003f7]: cs_s = 2'b01; // DMEM address space until 885
            [64'h00000000_000003f7:64'h00000000_0001000F]: cs_s = 2'b10; // GPIO address space
            default:                                       cs_s = 2'b00;
        endcase
end

// Assign GPIO address and data when chip select is active
    always_comb begin
        if (cs_s == 2'b10) begin
            gpio_addr_s = gpio_addr_i[63:0];
            gpio_data_s = gpio_data_i[63:0]; // Assume lower 32 bits of register file for GPIO data
        end else begin
            gpio_addr_s = 64'b0;
            gpio_data_s = 64'b0;
        end
    end

    // GPIO Registers
    logic [7:0] gpio_data_reg;   // Register to hold GPIO data
   // logic [63:0] gpio_addr_reg;   // Register to hold GPIO address

    // Write to GPIO Register
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            gpio_data_reg <= 64'b0;       // Reset GPIO data
        //    gpio_addr_reg <= 64'b0;       // Reset GPIO address
        end else if (cs_s[1]) begin
            gpio_data_reg <=  gpio_data_s[7:0]; // Write data to GPIO register
        //    gpio_addr_reg <=  gpio_addr_s[63:0]; // Write address to GPIO register
        end
    end

    // Output GPIO Data
    assign gpio_o = gpio_data_reg;

endmodule
