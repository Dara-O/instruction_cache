`timescale 1ns/1ps

module onehot_decoder4(
    input   wire    [3:0]	i_onehot,

    output  reg     [1:0]	o_decoded
);

    always @(*) begin
        casez(i_onehot) 
        4'b1???	:	 o_decoded = 3;
        4'b01??	:	 o_decoded = 2;
        4'b001?	:	 o_decoded = 1;
        4'b0001	:	 o_decoded = 0;
        
        default : o_decoded = {2{1'b0}};
        endcase
    end

endmodule

