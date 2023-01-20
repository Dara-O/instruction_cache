`timescale 1ns/1ps

module cache_mux (
    input   wire    [TAG_BITS_WIDTH-1:0]        i_tag_bits,
    
    input   wire    [TAG_ARRAY_WIDTH-1:0]       i_tag_array_tag_data,
    input   wire    [STATUS_ARRAY_WIDTH-1:0]    i_status_array_data,
    
    // pass through for miss handling
    input   wire    [SET_BITS_WIDTH-1:0]        i_set_bits,
    input   wire    [BLOCK_OFFSET_BITS-1:0]     i_block_offset_bits,
    input   wire                                i_valid,
    
    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt,
    
    output  wire    [NUM_BLOCKS-1:0]            o_hit_blocks,
    output  reg                                 o_cache_hit, // 1 means cache hit, 0 means miss
    output  reg     [TAG_BITS_WIDTH-1:0]        o_tag_bits,
    output  reg     [SET_BITS_WIDTH-1:0]        o_set_bits,
    output  reg     [BLOCK_OFFSET_BITS-1:0]     o_block_offset_bits,
    output  reg     [STATUS_ARRAY_WIDTH-1:0]    o_status_array_data, 

    output  reg                                 o_valid,
    output  wire                                o_ready
);
    // to aid understanding
    localparam TAG_BITS_WIDTH = 8;
    localparam BLOCK_OFFSET_BITS = 4; 
    localparam TAG_ARRAY_WIDTH = 32;
    localparam STATUS_ARRAY_WIDTH = 8;
    localparam SET_BITS_WIDTH = 4;

    localparam NUM_BLOCKS = 4;

    localparam USE_BIT_IDX      = 0; // for use in understanding status_array_data
    localparam VALID_BIT_IDX    = 1;

    
    reg    [TAG_ARRAY_WIDTH:0]         r_tag_array_tag_data;

    assign o_ready = ~i_halt;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_tag_bits              <= {TAG_BITS_WIDTH{1'b0}};
            r_tag_array_tag_data    <= {TAG_ARRAY_WIDTH{1'b0}};
            o_status_array_data     <= {STATUS_ARRAY_WIDTH{1'b0}};
            o_valid                 <= 1'b0;

            o_set_bits              <= {SET_BITS_WIDTH{1'b0}};
            o_block_offset_bits     <= {BLOCK_OFFSET_BITS{1'b0}};
        end
        else if(~i_halt) begin
            o_tag_bits              <= i_tag_bits           & {TAG_BITS_WIDTH{i_valid}};
            r_tag_array_tag_data    <= i_tag_array_tag_data & {TAG_ARRAY_WIDTH{i_valid}};
            o_status_array_data     <= i_status_array_data  & {STATUS_ARRAY_WIDTH{i_valid}};
            o_valid                 <= i_valid;

            o_set_bits              <= i_set_bits           & {SET_BITS_WIDTH{i_valid}};
            o_block_offset_bits     <= i_block_offset_bits  & {BLOCK_OFFSET_BITS{i_valid}};
        end
    end

    assign o_hit_blocks = {
        (o_tag_bits === r_tag_array_tag_data[24 +: TAG_BITS_WIDTH]) & o_status_array_data[6], // valid bit is lsb
        (o_tag_bits === r_tag_array_tag_data[16 +: TAG_BITS_WIDTH]) & o_status_array_data[4],
        (o_tag_bits === r_tag_array_tag_data[8  +: TAG_BITS_WIDTH]) & o_status_array_data[2],
        (o_tag_bits === r_tag_array_tag_data[0  +: TAG_BITS_WIDTH]) & o_status_array_data[0]
    } & {NUM_BLOCKS{o_valid}};

    assign o_cache_hit = |o_hit_blocks;

endmodule