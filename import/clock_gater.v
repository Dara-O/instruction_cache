`timescale 1ns/1ps

module clock_gater(
    input clk, 
    input stop_clock,
    
    output gated_clock
);

    reg clock_prop;

    always @(negedge clk) begin
        clock_prop <= ~stop_clock;
    end

    assign gated_clock = clk & clock_prop;

endmodule