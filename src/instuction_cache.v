`timescale 1ns/1ps

/*
    TODO: 
        - finish icache_stage1.v, restart and sa_w_arb logic
            - note that the restart logic and status array 
              write arbiter should be outside icache_stage1.v
        - cache restart logic
        - connect all sub modules together
        - test module
*/

module instruction_cache(
    input   wire    [ADDR_WIDTH-1:0]            i_addr,
    input   wire                                i_valid, 

    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt,

    input   wire    [MEM_IF_DATA_WIDTH-1:0]     i_mem_data,
    input   wire                                i_mem_data_valid,

    output  wire    [WORD_WIDTH-1:0]            o_data,
    output  wire                                o_valid,

    // memory interface
    output  wire    [MEM_IF_ADDR_WIDTH-1:0]     o_mem_addr,
    output  wire                                o_mem_req_valid,
    output  wire                                o_ready
);
    
    localparam ADDR_WIDTH = 16;
    localparam WORD_WIDTH = 20;
    localparam MEM_IF_DATA_WIDTH = 128; // FIXME
    localparam MEM_IF_ADDR_WIDTH = 16;

    localparam SET_BITS_WIDTH = 4;
    localparam B_OFFSET_BITS_WIDTH = 4;
    localparam TAG_BITS_WIDTH = 8;
    localparam NUM_WAYS = 4;

    // FIXME: Instantiate reset synchronizer that asserts o_ready when reset is complete

    // ============ STAGE 1 BEGINS ============
    wire [TAG_BITS_WIDTH-1:0]       w_addr_tag_bits             = i_addr[15:8];
    wire [SET_BITS_WIDTH-1:0]       w_addr_set_bits             = i_addr[7:4];
    wire [B_OFFSET_BITS_WIDTH-1:0]  w_addr_block_offset_bits    = i_addr[3:0];

    wire [TAG_BITS_WIDTH-1:0]       ics1_addr_tag_bits; // ics1 == icache_stage1      
    wire [SET_BITS_WIDTH-1:0]       ics1_addr_set_bits;         
    wire [B_OFFSET_BITS_WIDTH-1:0]  ics1_addr_block_offset_bits;
    wire ics1_metadata_valid;

    localparam TA_WORD_WIDTH    = 32; // 8 bits x 4 ways
    localparam SA_WORD_WIDTH    = 8; // 2 bits x 4 ways
    
    wire [TA_WORD_WIDTH-1:0]  ics1_ta_data;
    wire ics1_ta_valid;

    wire [SA_WORD_WIDTH-1:0]  ics1_sa_data; 
    wire ics1_sa_valid;

    wire ics1_ready; // FIXME: What does this halt?

    icache_stage1 #(.METADATA_WIDTH(ADDR_WIDTH)) icache_stage1_m (
        .i_metadata({w_addr_tag_bits, w_addr_set_bits, w_addr_block_offset_bits}),
        .i_metadata_valid(i_valid),

        // intercept from restart unit
        .i_r_addr(i_addr_FIXME),
        .i_r_valid(i_valid_FIXME),

        .i_w_ta_addr(i_w_ta_addr),
        .i_w_ta_data(i_w_ta_data),
        .i_w_ta_mask(i_w_ta_mask),
        .i_w_ta_valid(i_w_ta_valid),

        // from sa_write_arb (negotiate between miss update and use-bit update)
        .i_w_sa_addr(i_w_sa_addr),
        .i_w_sa_data(i_w_sa_data),
        .i_w_sa_mask(i_w_sa_mask),
        .i_w_sa_valid(i_w_sa_valid),
        .i_miss_state(i_miss_state),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt), //FIXME (global or from next stage's ready?)
        
        .o_ta_data(ics1_ta_data),
        .o_ta_data_valid(ics1_ta_valid),
        .o_sa_data(ics1_sa_data),
        .o_sa_data_valid(ics1_sa_valid),

        .o_metadata({ics1_addr_tag_bits, ics1_addr_set_bits, ics1_addr_block_offset_bits}),
        .o_metadata_valid(ics1_metadata_valid),

        .o_ready(ics1_ready)
    );
  

    // ============ STAGE 1 ENDS ============
    // =======================================
    // ============ STAGE 2 BEGINS ============

    // wire [NUM_WAYS-1:0]
    wire                                tc_cache_hit;
    wire [TAG_BITS_WIDTH-1:0]           tc_tag_bits;
    wire [SET_BITS_WIDTH-1:0]           tc_set_bits;
    wire [B_OFFSET_BITS_WIDTH-1:0]      tc_block_offset_bits;
    wire [SA_WORD_WIDTH-1:0]            tc_sa_data;


    tag_checker tc (
      .i_tag_bits(s1f_tc_tag_bits),

      .i_tag_array_tag_data(ta_data),
      .i_status_array_data(saw_data),

      .i_set_bits(s1f_tc_set_bits),
      .i_block_offset_bits(s1f_tc_b_offset_bits),
      .i_valid(s1f_tc_valid & saw_valid & ta_valid),

      .clk(clk),
      .arst_n(arst_n),
      .i_halt(), //FIXME

      .o_hit_blocks(tc_hit_blocks),
      .o_cache_hit(tc_cache_hit),

      .o_tag_bits(tc_tag_bits),
      .o_set_bits(tc_set_bits),
      .o_block_offset_bits(tc_block_offset_bits),
      .o_status_array_data(tc_sa_data),
      
      .o_valid(),//FIXME
      .o_ready()//FIXME
    );
  
    // ============ STAGE 2 ENDS ============
    // =======================================
    // ============ STAGE 3 BEGINS ============

    data_arrays_container dac (
      .i_r_addr({tc_set_bits, tc_block_offset_bits}),
      .i_r_valid(tc_cache_hit),
      .i_r_mask(tc_hit_blocks),

      .i_w_addr(),
      .i_w_data(),
      .i_w_valid(),
      .i_w_mask(),

      .clk(clk),
      .arst_n(arst_n),
      .i_halt_all(), //FIXME
      .i_stop_read_clk(1'b0), //FIXME
      .i_stop_write_clk(1'b0),//FIXME

      .o_word_data(o_data),
      .o_valid(o_valid),
      .o_ready()//FIXME
    );
  


endmodule