`timescale 1ns/1ps

module missed_word_driver (
    input   wire    [MEM_DATA_WIDTH-1:0]    i_mem_data,
    input   wire    [B_OFFSET_BITS-1:0]     i_block_offset_bits,
    input   wire                            i_valid,

    output  reg     [WORD_WIDTH-1:0]        o_missed_word,
    output  wire                            o_valid
);
    localparam MEM_DATA_WIDTH = 320;
    localparam WORD_WIDTH = 20;
    localparam B_OFFSET_BITS = 4;

    assign o_valid = i_valid; 

    always @(*) begin
        case (i_block_offset_bits)
        4'd0 :  begin
            o_missed_word = i_mem_data[19:0];
        end
        4'd1 :  begin
            o_missed_word = i_mem_data[39:20];
        end
        4'd2 :  begin
            o_missed_word = i_mem_data[59:40];
        end
        4'd3 :  begin
            o_missed_word = i_mem_data[79:60];
        end
        4'd4 :  begin
            o_missed_word = i_mem_data[99:80];
        end
        4'd5 :  begin
            o_missed_word = i_mem_data[119:100];
        end
        4'd6 :  begin
            o_missed_word = i_mem_data[139:120];
        end
        4'd7 :  begin
            o_missed_word = i_mem_data[159:140];
        end
        4'd8 :  begin
            o_missed_word = i_mem_data[179:160];
        end
        4'd9 :  begin
            o_missed_word = i_mem_data[199:180];
        end
        4'd10 :  begin
            o_missed_word = i_mem_data[219:200];
        end
        4'd11 :  begin
            o_missed_word = i_mem_data[239:220];
        end
        4'd12 :  begin
            o_missed_word = i_mem_data[259:240];
        end
        4'd13 :  begin
            o_missed_word = i_mem_data[279:260];
        end
        4'd14 :  begin
            o_missed_word = i_mem_data[299:280];
        end
        4'd15 :  begin
            o_missed_word = i_mem_data[319:300];
        end

        default : begin
            o_missed_word = 0;
        end
        endcase
    end
endmodule