`timescale 1ns/1ps

module use_bit_updater(
    input   wire    [SA_WORD_WIDTH-1:0]     i_sa_data,
    input   wire    [NUM_WAYS-1:0]          i_hit_blocks,
    input   wire                            i_cache_hit,
    input   wire                            i_valid,
    
    output  wire    [SA_WORD_WIDTH-1:0]     o_sa_w_data,
    output  wire    [NUM_WAYS-1:0]          o_sa_w_mask,
    output  wire                            o_valid
);

    localparam SA_WORD_WIDTH = 8;
    localparam NUM_WAYS = 4;

    // for use in understanding status_array_data
    localparam USE_BIT_IDX      = 0; 
    localparam VALID_BIT_IDX    = 1;

    assign o_valid = i_valid & i_cache_hit;
    assign o_sa_w_mask = {NUM_WAYS{1'b1}};

    wire [NUM_WAYS-1:0] w_sa_use_bits = {
        &i_sa_data[7:6], // VALID_BIT & USE_BIT. 
        &i_sa_data[5:4],
        &i_sa_data[3:2],
        &i_sa_data[1:0]
    };

    wire [$clog2(NUM_WAYS):0] w_num_ones =  w_sa_use_bits[0] + 
                                            w_sa_use_bits[1] + 
                                            w_sa_use_bits[2] + 
                                            w_sa_use_bits[3];

    wire [NUM_WAYS-1:0] w_new_use_bits; 
    assign w_new_use_bits= (w_num_ones < NUM_WAYS-1) ? (w_sa_use_bits | i_hit_blocks) : 
                                                       (i_hit_blocks);

    assign o_sa_w_data = {
        i_sa_data[7] ,w_new_use_bits[3],
        i_sa_data[5] ,w_new_use_bits[2],
        i_sa_data[3] ,w_new_use_bits[1],
        i_sa_data[1] ,w_new_use_bits[0]
    };

endmodule