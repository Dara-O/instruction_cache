`timescale 1ns/1ps


module cache_miss_handler (
    input   wire                                    i_cache_hit,
    input   wire    [TAG_BITS_WIDTH-1:0]            i_tag_bits,
    input   wire    [SET_BITS_WIDTH-1:0]            i_set_bits,
    input   wire    [B_OFFSET_BITS_WIDTH-1:0]       i_block_offset_bits,

    input   wire    [SA_WORD_WIDTH-1:0]             i_status_array_data,
    input   wire                                    i_valid,

    input   wire    [MEM_IF_DATA-1:0]               i_mem_if_data, // pre-decoded data
    input   wire                                    i_mem_if_valid,

    input   wire                                    clk,
    input   wire                                    arst_n,
    input   wire                                    i_halt,

    input   wire                                    i_sa_blocks_halt,
    input   wire                                    i_ta_blocks_halt,
    input   wire                                    i_da_blocks_halt,


    output  wire    [SET_BITS_WIDTH-1:0]        o_da_set_bits,
    output  wire    [$clog2(NUM_WAYS)-1:0]      o_da_way_index,
    output  wire    [B_OFFSET_BITS_WIDTH-3:0]   o_da_block_offset_bits,
    output  wire    [DA_WRITE_WIDTH-1:0]        o_da_write_data, // data array
    output  wire                                o_da_blocks_if_valid, 

    output  wire    [TA_SRAM_ADDR_WIDTH-1:0]    o_ta_write_addr,
    output  wire    [TA_SRAM_WORD_WIDTH-1:0]    o_ta_write_data, // tag array
    output  wire    [NUM_WAYS-1:0]              o_ta_blocks_mask,
    output  wire                                o_ta_blocks_if_valid, 

    output  wire    [SA_SRAM_ADDR_WIDTH-1:0]    o_sa_write_addr,
    output  wire    [SA_WORD_WIDTH-1:0]         o_sa_write_data, // status array
    output  wire    [NUM_WAYS-1:0]              o_sa_blocks_mask,
    output  wire                                o_sa_blocks_if_valid, 

    output  wire    [MEM_IF_ADDR-1:0]           o_mem_if_addr, //memory if = interface
    output  wire                                o_mem_if_req_valid,
    output  wire                                o_mem_if_ready,

    output  wire                                o_miss_state, // if 1, the cache is handling a miss, 
                                                              // if 0, cache can continue normal operation.

    output  wire    [DA_SRAM_WORD_WIDTH-1:0]    o_missed_word,
    output  wire                                o_missed_word_valid,
    output  wire                                o_ready
);
    localparam SET_BITS_WIDTH = 4;
    localparam B_OFFSET_BITS_WIDTH = 4; //block offset bits width
    localparam TAG_BITS_WIDTH = 8;

    localparam SA_WORD_WIDTH = 4*2; 
    localparam SA_SRAM_ADDR_WIDTH = 4;

    localparam TA_SRAM_WORD_WIDTH = 4*8;
    localparam TA_SRAM_ADDR_WIDTH = 4;

    localparam DA_SRAM_WORD_WIDTH = 20; 
    localparam DA_WRITE_WIDTH = 80; 
    localparam DA_SRAM_ADDR_WIDTH = 8;

    localparam MEM_IF_ADDR = 16;
    localparam MEM_IF_DATA = 40;
    localparam NUM_WAYS = 4;

    localparam MEM_BLOCK_DATA_WIDTH = 320;

    

    reg                             r_cache_hit;
    reg [TAG_BITS_WIDTH-1:0]        r_tag_bits;
    reg [SET_BITS_WIDTH-1:0]        r_set_bits;
    reg [B_OFFSET_BITS_WIDTH-1:0]   r_block_offset_bits;
    
    reg [SA_WORD_WIDTH-1:0]         r_status_array_data;
    reg                             r_valid;

    reg [MEM_IF_DATA-1:0]           r_mem_if_data;
    reg                             r_mem_if_valid;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_cache_hit             <= 1'b0;
            r_tag_bits              <= {TAG_BITS_WIDTH{1'b0}};
            r_set_bits              <= {SET_BITS_WIDTH{1'b0}};
            r_block_offset_bits     <= {B_OFFSET_BITS_WIDTH{1'b0}};

            r_status_array_data     <= {SA_WORD_WIDTH{1'b0}};
            r_valid                 <= 1'b0;;

            r_mem_if_data           <= {MEM_IF_DATA{1'b0}};
            r_mem_if_valid          <= 1'b0;
        end
        else if(o_ready) begin
            r_cache_hit             <= i_cache_hit;
            r_tag_bits              <= i_tag_bits;
            r_set_bits              <= i_set_bits;
            r_block_offset_bits     <= i_block_offset_bits;

            r_status_array_data     <= i_status_array_data;
            r_valid                 <= i_valid;

            r_mem_if_data           <= i_mem_if_data;
            r_mem_if_valid          <= i_mem_if_valid;
        end
    end

    wire [NUM_WAYS-1:0] lru_block_replacement_mask;
    wire lru_brm_valid;

    lru_unit lru_unit_m(
        .i_sa_data(r_status_array_data),
        .i_sa_data_valid(r_valid),

        .o_block_replacement_mask(lru_block_replacement_mask),
        .o_brm_valid(lru_brm_valid)
    );
  

    
    wire mc_cu_mem_data_received;
    wire mc_cu_mem_if_valid;
    // wire mc_cu_mem_ready; // unnecessary
    
    wire au_cu_arrays_update_complete;
    wire au_cu_auc_valid;
    
    wire cu_mc_initiate_mem_req;
    wire cu_mc_valid;
    wire cu_miss_state;
    wire cu_initiate_array_update; 
    wire cu_send_missed_word;
    wire cu_valid; 
    wire cu_ready;
    // wire cu_mem_if_ready; // unnecessary
    // wire cu_arrays_updater_ready; // unnecessary

    assign o_miss_state = cu_miss_state;
    assign o_ready = ~(i_halt & o_miss_state);

    control_unit ctrl_unit(
        .i_cache_hit(r_cache_hit),
        .i_valid(r_valid),

        .i_mem_data_received(mc_cu_mem_data_received),
        .i_mem_if_valid(mc_cu_mem_if_valid),

        .i_arrays_update_complete(au_cu_arrays_update_complete), // au == arrays update complete
        .i_auc_valid(au_cu_auc_valid),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt), //Future Note: all the modules should be able to halt it (only when they need to be accessed but arent ready)
        
        .o_miss_state(cu_miss_state),
        
        .o_initiate_mem_req(cu_mc_initiate_mem_req),
        .o_mem_if_valid(cu_mc_valid),
        
        .o_initiate_array_update(cu_initiate_array_update),
        .o_send_missed_word(cu_send_missed_word),
        .o_valid(cu_valid),

        .o_mem_if_ready(),
        .o_arrays_updater_ready(),
        .o_ready(cu_ready)
    );

    wire [MEM_BLOCK_DATA_WIDTH-1:0] mc_mem_block_data;
    wire mc_mem_block_data_valid;

    memory_controller mem_ctrl(
        .i_block_addr({r_tag_bits, r_set_bits, r_block_offset_bits}),
        .i_block_addr_valid(r_valid),
    
        .i_initiate_req(cu_mc_initiate_mem_req),
        .i_ir_valid(cu_mc_valid), // initiate request valid
        
        // from memory
        .i_mem_data(i_mem_if_data),
        .i_mem_data_valid(i_mem_if_valid),
    
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        // to memory
        .o_mem_req_addr(o_mem_if_addr), 
        .o_mem_req_valid(o_mem_if_req_valid),
        .o_mem_ready(o_mem_if_ready),
        
        .o_mem_data_received(mc_cu_mem_data_received),
        .o_mem_data_rcvd_valid(mc_cu_mem_if_valid),
        .o_ir_ready(), //mc_cu_mem_ready

        .o_mem_block_data(mc_mem_block_data), 
        .o_mem_block_data_valid(mc_mem_block_data_valid)
    );

    // wire au_ready;
    arrays_updater arrays_updater_m(
        .i_initiate_arrays_update(cu_initiate_array_update),
        .i_iau_valid(cu_valid),

        .i_set_addr(r_set_bits),
        .i_set_addr_valid(r_valid),

        .i_tag_bits(r_tag_bits),
        .i_tag_bits_valid(r_valid),

        .i_block_replacement_mask(lru_block_replacement_mask),
        .i_brm_valid(lru_brm_valid),

        .i_mem_data(mc_mem_block_data),
        .i_mem_data_valid(mc_mem_block_data_valid),

        .i_miss_state(cu_miss_state),
    
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .i_ta_blocks_halt(i_ta_blocks_halt),
        .i_sa_blocks_halt(i_sa_blocks_halt),
        .i_da_blocks_halt(i_da_blocks_halt),

        .o_ta_addr(o_ta_write_addr),
        .o_ta_data(o_ta_write_data),
        .o_ta_mask(o_ta_blocks_mask),
        .o_ta_valid(o_ta_blocks_if_valid),

        .o_sa_addr(o_sa_write_addr),
        .o_sa_data(o_sa_write_data),
        .o_sa_mask(o_sa_blocks_mask),
        .o_sa_valid(o_sa_blocks_if_valid),

        .o_da_addr({o_da_set_bits, o_da_way_index, o_da_block_offset_bits}),
        .o_da_data(o_da_write_data),
        .o_da_valid(o_da_blocks_if_valid),

        .o_arrays_update_complete(au_cu_arrays_update_complete),
        .o_auc_valid(au_cu_auc_valid), // arrays_update_complete_valid

        .o_ready()
    );

    missed_word_driver missed_word_driver_m(
        .i_mem_data(mc_mem_block_data),
        .i_block_offset_bits(r_block_offset_bits),
        .i_valid(cu_send_missed_word & cu_valid & r_valid & mc_mem_block_data_valid),

        .o_missed_word(o_missed_word),
        .o_valid(o_missed_word_valid)
    );
  
endmodule