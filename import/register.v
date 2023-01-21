`timescale 1ns/1ps

module register #(parameter WIDTH=8) (
    input   wire    [WIDTH-1:0]     i_d,

    input   wire                    clk,
    input   wire                    arst_n,
    input   wire                    i_halt,

    output  reg     [WIDTH-1:0]     o_q,
    output  wire                    o_ready
);
    
    assign o_ready = ~i_halt;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_q <= {WIDTH{1'b0}};
        end
        else if(~i_halt) begin
            o_q <= i_d;
        end
    end
	
endmodule
