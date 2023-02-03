`timescale 1ns/1ps

module data_out_arb (
    input   wire    [READ_WORD_WIDTH-1:0]   i_missed_word,
    input   wire                            i_missed_word_valid,

    input   wire    [READ_WORD_WIDTH-1:0]   i_hit_word,
    input   wire                            i_hit_word_valid, 

    input   wire                            i_miss_state,

    output  wire    [READ_WORD_WIDTH-1:0]   o_cache_word,
    output  wire                            o_cache_word_valid
);

    localparam READ_WORD_WIDTH = 20;

    assign o_cache_word         = i_miss_state ? i_missed_word : i_hit_word;
    assign o_cache_word_valid   = i_miss_state ? i_missed_word_valid : i_hit_word_valid;
    
endmodule