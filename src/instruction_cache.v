`timescale 1ns/1ps

module instruction_cache(
    input   wire    [ADDR_WIDTH-1:0]            i_addr,
    input   wire                                i_valid, 

    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt,

    // memory interface >>>
    input   wire    [MEM_IF_DATA_WIDTH-1:0]     i_mem_data,
    input   wire                                i_mem_data_valid,
    // <<<< memory interface 

    output  wire    [WORD_WIDTH-1:0]            o_data,
    output  wire                                o_valid,
    output  wire                                o_ready,

    // memory interface >>>
    output  wire    [MEM_IF_ADDR_WIDTH-1:0]     o_mem_addr,
    output  wire                                o_mem_req_valid,
    output  wire                                o_mem_if_ready
    // <<<< memory interface 
);
    
    localparam ADDR_WIDTH = 16;
    localparam WORD_WIDTH = 20;
    localparam MEM_IF_DATA_WIDTH = 40;
    localparam MEM_IF_ADDR_WIDTH = 16;

    localparam SET_BITS_WIDTH = 4;
    localparam B_OFFSET_BITS_WIDTH = 4;
    localparam TAG_BITS_WIDTH = 8;
    localparam NUM_WAYS = 4;


    localparam TA_WORD_WIDTH    = 32; // 8 bits x 4 ways
    localparam SA_WORD_WIDTH    = 8; // 2 bits x 4 ways
    localparam DA_WRITE_WIDTH   = 80;

    wire tc_cache_hit;
    wire cmh_miss_state;
    wire glb_miss_state = (~tc_cache_hit)&tc_valid | cmh_miss_state;

    // ============ STAGE 1 BEGINS ============

    wire [ADDR_WIDTH-1:0] ics1r_addr;
    wire ics1r_addr_valid;
    wire ics1r_curr_r_addr_ready;

    assign o_ready = ics1r_curr_r_addr_ready;

    wire [TAG_BITS_WIDTH-1:0]       ics1_addr_tag_bits; // ics1 == icache_stage1      
    wire [SET_BITS_WIDTH-1:0]       ics1_addr_set_bits;         
    wire [B_OFFSET_BITS_WIDTH-1:0]  ics1_addr_block_offset_bits;
    wire ics1_metadata_valid;

    wire ics1_ready; 

    ics1_restart ics1_restart_m(
        .i_curr_r_addr(i_addr),
        .i_curr_r_addr_valid(i_valid),

        .i_prev_r_addr({ics1_addr_tag_bits, ics1_addr_set_bits, ics1_addr_block_offset_bits}),
        .i_prev_r_addr_valid(ics1_metadata_valid),

        .i_miss_state(glb_miss_state),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(~ics1_ready),

        .o_r_addr(ics1r_addr),
        .o_r_addr_valid(ics1r_addr_valid),

        .o_curr_r_addr_ready(ics1r_curr_r_addr_ready)
    );
    
    wire [SET_BITS_WIDTH-1:0]   sawb_w_set_addr;
    wire [SA_WORD_WIDTH-1:0]    sawb_w_data;
    wire [NUM_WAYS-1:0]         sawb_w_mask;
    wire                        sawb_w_valid;

    wire [SET_BITS_WIDTH-1:0]   cmh_w_sa_set_addr;
    wire [SA_WORD_WIDTH-1:0]    cmh_w_sa_data;
    wire [NUM_WAYS-1:0]         cmh_w_sa_blocks_mask;
    wire                        cmh_w_sa_valid;

    wire [SA_WORD_WIDTH-1:0]    ubu_sa_w_data;
    wire [NUM_WAYS-1:0]         ubu_sa_w_mask;
    wire                        ubu_valid;

    wire [SET_BITS_WIDTH-1:0]   tc_set_bits;

    sa_w_arb  sa_w_arb_m(
        .i_ubit_upd_sa_set_addr(tc_set_bits),
        .i_ubit_upd_sa_data(ubu_sa_w_data),
        .i_ubit_upd_sa_mask(ubu_sa_w_mask),
        .i_ubit_upd_sa_valid(ubu_valid),

        .i_miss_write_set_addr(cmh_w_sa_set_addr),
        .i_miss_write_data(cmh_w_sa_data),
        .i_miss_write_mask(cmh_w_sa_blocks_mask),
        .i_miss_if_valid(cmh_w_sa_valid),

        .i_miss_state(glb_miss_state),

        .o_w_set_addr(sawb_w_set_addr),
        .o_w_data(sawb_w_data),
        .o_w_mask(sawb_w_mask),
        .o_w_valid(sawb_w_valid)
    );
    
    wire [TAG_BITS_WIDTH-1:0]       w_addr_tag_bits             = ics1r_addr[15:8];
    wire [SET_BITS_WIDTH-1:0]       w_addr_set_bits             = ics1r_addr[7:4];
    wire [B_OFFSET_BITS_WIDTH-1:0]  w_addr_block_offset_bits    = ics1r_addr[3:0];

    wire [TA_WORD_WIDTH-1:0]  ics1_ta_data;
    wire ics1_ta_valid;

    wire [SA_WORD_WIDTH-1:0]  ics1_sa_data; 
    wire ics1_sa_valid;

    wire tc_ready;

    wire [SET_BITS_WIDTH-1:0]   cmh_w_ta_set_addr;
    wire [TA_WORD_WIDTH-1:0]    cmh_w_ta_data;
    wire [NUM_WAYS-1:0]         cmh_w_ta_blocks_mask;
    wire                        cmh_w_ta_valid;


    icache_stage1 #(.METADATA_WIDTH(ADDR_WIDTH)) icache_stage1_m (
        .i_metadata({w_addr_tag_bits, w_addr_set_bits, w_addr_block_offset_bits}),
        .i_metadata_valid(ics1r_addr_valid),

        .i_r_set_addr(w_addr_set_bits),
        .i_r_valid(ics1r_addr_valid),

        // from miss handler >>> 
        .i_w_ta_set_addr(cmh_w_ta_set_addr),
        .i_w_ta_data(cmh_w_ta_data),
        .i_w_ta_mask(cmh_w_ta_blocks_mask),
        .i_w_ta_valid(cmh_w_ta_valid),
        // from miss handler <<<

        .i_w_sa_set_addr(sawb_w_set_addr),
        .i_w_sa_data(sawb_w_data),
        .i_w_sa_mask(sawb_w_mask),
        .i_w_sa_valid(sawb_w_valid),
        .i_miss_state(glb_miss_state),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),
        
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

    wire [TAG_BITS_WIDTH-1:0]           tc_tag_bits;
    wire [B_OFFSET_BITS_WIDTH-1:0]      tc_block_offset_bits;
    wire [NUM_WAYS-1:0]                 tc_hit_blocks;
    wire [SA_WORD_WIDTH-1:0]            tc_sa_data;
    wire                                tc_valid;
    


    tag_checker tc (
        .i_tag_bits(ics1_addr_tag_bits),

        .i_ta_data(ics1_ta_data),
        .i_status_array_data(ics1_sa_data),

        .i_set_bits(ics1_addr_set_bits),
        .i_block_offset_bits(ics1_addr_block_offset_bits),
        .i_valid(ics1_ta_valid & ics1_sa_valid & ics1_metadata_valid),
        .i_clear(glb_miss_state),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(cmh_miss_state),

        .o_hit_blocks(tc_hit_blocks),
        .o_cache_hit(tc_cache_hit),

        .o_tag_bits(tc_tag_bits),
        .o_set_bits(tc_set_bits),
        .o_block_offset_bits(tc_block_offset_bits),
        .o_status_array_data(tc_sa_data),
        
        .o_valid(tc_valid),
        .o_ready(tc_ready)
    );

    use_bit_updater use_bit_updater_m (
        .i_sa_data(tc_sa_data),
        .i_hit_blocks(tc_hit_blocks),
        .i_cache_hit(tc_cache_hit),
        .i_valid(tc_valid),

        .o_sa_w_data(ubu_sa_w_data),
        .o_sa_w_mask(ubu_sa_w_mask),
        .o_valid(ubu_valid)
    );
  
  
    // ============ STAGE 2 ENDS ============
    // =======================================
    // ============ STAGE 3 BEGINS ============

    wire [SET_BITS_WIDTH-1:0]       cmh_da_set_addr;

    wire [$clog2(NUM_WAYS)-1:0]     cmh_da_way_index;
    wire [B_OFFSET_BITS_WIDTH-3:0]  cmh_da_block_offset_bits;
    wire [DA_WRITE_WIDTH-1:0]       cmh_da_write_data;
    wire                            cmh_da_blocks_if_valid;

    wire [WORD_WIDTH-1:0]   cmh_missed_word;
    wire                    cmh_missed_word_valid;
    
    wire dac_ready;

    cache_miss_handler cache_miss_handler_m (
        .i_cache_hit(tc_cache_hit),
        .i_tag_bits(tc_tag_bits),
        .i_set_bits(tc_set_bits),
        .i_block_offset_bits(tc_block_offset_bits),

        .i_status_array_data(tc_sa_data),
        .i_valid(tc_valid),

        .i_mem_if_data(i_mem_data),
        .i_mem_if_valid(i_mem_data_valid), 

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .i_sa_blocks_halt(~ics1_ready),
        .i_ta_blocks_halt(~ics1_ready),
        .i_da_blocks_halt(~dac_ready),

        .o_da_set_bits(cmh_da_set_addr),
        .o_da_way_index(cmh_da_way_index),
        .o_da_block_offset_bits(cmh_da_block_offset_bits),
        .o_da_write_data(cmh_da_write_data),
        .o_da_blocks_if_valid(cmh_da_blocks_if_valid),

        .o_ta_write_addr(cmh_w_ta_set_addr),
        .o_ta_write_data(cmh_w_ta_data),
        .o_ta_blocks_mask(cmh_w_ta_blocks_mask),
        .o_ta_blocks_if_valid(cmh_w_ta_valid),

        .o_sa_write_addr(cmh_w_sa_set_addr),
        .o_sa_write_data(cmh_w_sa_data),
        .o_sa_blocks_mask(cmh_w_sa_blocks_mask),
        .o_sa_blocks_if_valid(cmh_w_sa_valid),

        .o_mem_if_addr(o_mem_addr),
        .o_mem_if_req_valid(o_mem_req_valid),
        .o_mem_if_ready(o_mem_if_ready),

        .o_miss_state(cmh_miss_state),
        
        .o_missed_word(cmh_missed_word),
        .o_missed_word_valid(cmh_missed_word_valid),
        .o_ready()
    );
      
    wire [$clog2(NUM_WAYS)-1:0] oh4d_r_way_index;
    
    onehot_decoder4 onehot4_dec(
        .i_onehot(tc_hit_blocks),
        .o_decoded(oh4d_r_way_index)
    );
    
    wire [WORD_WIDTH-1:0]   dac_word_data;
    wire                    dac_word_data_valid;

    data_arrays_container dac (
        .i_r_set_bits(tc_set_bits),
        .i_r_way_index(oh4d_r_way_index),
        .i_r_block_offset_bits(tc_block_offset_bits),
        .i_r_valid(tc_valid),

        .i_w_set_bits(cmh_da_set_addr),
        .i_w_way_index(cmh_da_way_index),
        .i_w_block_offset_bits(cmh_da_block_offset_bits),
        .i_w_data(cmh_da_write_data),
        .i_w_valid(cmh_da_blocks_if_valid),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt_all(i_halt),
        .i_stop_read_clk(cmh_miss_state),
        .i_stop_write_clk(~cmh_miss_state),

        .o_word_data(dac_word_data),
        .o_valid(dac_word_data_valid),

        .o_ready(dac_ready)
    );

    wire cdmsr_miss_state;

    register #(.WIDTH(1)) cmh_doa_miss_state_reg (
      .i_d(glb_miss_state),

      .clk(clk),
      .arst_n(arst_n),
      .i_halt(i_halt),

      .o_q(cdmsr_miss_state),
      .o_ready()
    );
  
    data_out_arb data_out_arb_m (
      .i_missed_word(cmh_missed_word),
      .i_missed_word_valid(cmh_missed_word_valid),

      .i_hit_word(dac_word_data),
      .i_hit_word_valid(dac_word_data_valid),

      .i_miss_state(cdmsr_miss_state),
      
      .o_cache_word(o_data),
      .o_cache_word_valid(o_valid)
    );

endmodule