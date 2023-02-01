`timescale 1ns/1ps


module icache_stage1 #(parameter METADATA_WIDTH=16) (
    input   wire    [METADATA_WIDTH-1:0]    i_metadata,
    input   wire                            i_metadata_valid,

    input   wire    [SET_BITS_WIDTH-1:0]    i_r_set_addr,
    input   wire                            i_r_valid, 

    input   wire    [SET_BITS_WIDTH-1:0]    i_w_ta_set_addr, 
    input   wire    [TA_WORD_WIDTH-1:0]     i_w_ta_data,
    input   wire    [NUM_WAYS-1:0]          i_w_ta_mask,
    input   wire                            i_w_ta_valid,

    input   wire    [SET_BITS_WIDTH-1:0]    i_w_sa_set_addr, 
    input   wire    [SA_WORD_WIDTH-1:0]     i_w_sa_data,
    input   wire    [NUM_WAYS-1:0]          i_w_sa_mask,
    input   wire                            i_w_sa_valid,

    input   wire                            i_miss_state,// FIXME: Do we need this?

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  wire    [TA_WORD_WIDTH-1:0]     o_ta_data, // ta == Tag Array 
    output  wire                            o_ta_data_valid,

    output  wire    [SA_WORD_WIDTH-1:0]     o_sa_data,
    output  wire                            o_sa_data_valid,

    output  wire    [METADATA_WIDTH-1:0]    o_metadata,
    output  wire                            o_metadata_valid,

    output  wire                            o_ready // for all inputs
);

    localparam SET_BITS_WIDTH   = 4;
    localparam TA_WORD_WIDTH    = 32; // 8 bits x 4 ways
    localparam SA_WORD_WIDTH    = 8; // 2 bits x 4 ways
    localparam NUM_WAYS         = 4;// same as the number of ways

    assign o_ready = ~(i_halt | saw_ready | ta_ready);

    register #(
        .WIDTH(ADDR_WIDTH+1)
    ) metadata_ff (
        .i_d({i_metadata, i_metadata_valid}),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_q({o_metadata, o_metadata_valid}),
        .o_ready()
    );

    wire [SA_WORD_WIDTH-1:0]  saw_data; // saw == status array wrapper
    wire saw_valid;
    wire saw_ready;

    status_array_wrapper status_array_wrapper_m (
        .i_tag(1'b0),
        .i_r_addr(i_r_set_addr),
        .i_r_valid(i_r_valid),

        .i_w_addr(i_w_sa_set_addr),
        .i_w_data(i_w_sa_data),
        .i_w_wmask(i_w_sa_mask),
        .i_w_valid(i_w_sa_valid),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_tag(),

        .o_data(saw_data),
        .o_valid(saw_valid),
        .o_ready(saw_ready)
    );
    
    wire [TA_WORD_WIDTH-1:0] ta_data;
    wire ta_valid;
    wire ta_ready;

    tag_array tag_array_m (
        .i_tag(1'b0),
        .i_r_addr(i_r_set_addr),
        .i_r_valid(i_r_valid),
        
        .i_w_addr(i_w_ta_set_addr),
        .i_w_data(i_w_ta_data),
        .i_w_wmask(i_w_ta_mask),
        .i_w_valid(i_w_ta_valid),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_tag(),

        .o_data(ta_data),
        .o_valid(ta_valid),
        .o_ready(ta_ready)
    );

endmodule