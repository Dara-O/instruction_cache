`timescale 1ns/1ps

/*
    TODO: 
        - finish icache_stage1.v
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
    localparam BLOCK_OFFSET_BITS_WIDTH = 4;
    localparam TAG_BITS_WIDTH = 8;
    localparam STATUS_ARRAY_WORD_WIDTH = 4*2;
    localparam NUM_WAYS = 4;

    // FIXME: Instantiate reset synchronizer that asserts o_ready when reset is complete

    // ============ STAGE 1 BEGINS ============

    wire [BLOCK_OFFSET_BITS_WIDTH-1:0] w_block_offset_bits  = i_addr[3:0];
    wire [SET_BITS_WIDTH-1:0] w_set_bits                    = i_addr[7:4];
    wire [TAG_BITS_WIDTH-1:0] w_tag_bits                    = i_addr[15:8];  

    //FIXME
    assign o_ready = saw_ready | ta_ready;

    wire [STATUS_ARRAY_WORD_WIDTH-1:0]  saw_data;
    wire saw_valid;
    wire saw_ready;

    status_array_wrapper status_array_wrapper_m (
        .i_tag(1'b0),
        .i_r_addr(w_set_bits),
        .i_r_valid(i_valid),

        //FIXME:
        .i_w_addr(i_w_addr),
        .i_w_data(i_w_data),
        .i_w_wmask(i_w_wmask),
        .i_w_valid(i_w_valid),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(), //FIXME:

        .o_tag(),

        .o_data(saw_data),
        .o_valid(saw_valid),
        .o_ready(saw_ready)
    );


    localparam TAG_ARRAY_WORD_WIDTH = 32;
    wire [TAG_ARRAY_WORD_WIDTH-1:0] ta_data;
    wire ta_valid;
    wire ta_ready;

    tag_array tag_array_m (
        .i_tag(1'b0),
        .i_r_addr(w_set_bits),
        .i_r_valid(i_valid),
        
        // FIXME:
        .i_w_addr(i_w_addr),
        .i_w_data(i_w_data),
        .i_w_wmask(i_w_wmask),
        .i_w_valid(i_w_valid),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(), //FIXME

        .o_tag(),
        .o_data(ta_data),
        .o_valid(ta_valid),
        .o_ready(ta_ready)
    );
  
    wire [TAG_BITS_WIDTH-1:0]           s1f_tc_tag_bits; // s1f == stage 1 flop
    wire [SET_BITS_WIDTH-1:0]           s1f_tc_set_bits;
    wire [BLOCK_OFFSET_BITS_WIDTH-1:0]  s1f_tc_b_offset_bits;
    wire s1f_tc_valid;

    register #(
        .WIDTH(TAG_BITS_WIDTH + SET_BITS_WIDTH + BLOCK_OFFSET_BITS_WIDTH+1)
        ) stage1_flop_m (
        .i_d({w_tag_bits, w_set_bits, w_block_offset_bits, i_valid}),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(),//FIXEME,

        .o_q({s1f_tc_tag_bits, s1f_tc_set_bits, s1f_tc_b_offset_bits, s1f_tc_valid}),
        .o_ready()//FIXME
    );

    // ============ STAGE 1 ENDS ============
    // =======================================
    // ============ STAGE 2 BEGINS ============

    wire [NUM_WAYS-1:0]
    wire                                tc_cache_hit;
    wire [TAG_BITS_WIDTH-1:0]           tc_tag_bits;
    wire [SET_BITS_WIDTH-1:0]           tc_set_bits;
    wire [BLOCK_OFFSET_BITS_WIDTH-1:0]  tc_block_offset_bits;
    wire [STATUS_ARRAY_WORD_WIDTH-1:0]  tc_status_array_data;


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
      .o_status_array_data(tc_status_array_data),
      
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