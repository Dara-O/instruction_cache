`timescale 1ns/1ps

/*

*/

module cache_miss_handler (
    input   wire                                    i_cache_hit,
    input   wire    [TAG_BITS_WIDTH-1:0]            i_tag_bits,
    input   wire    [SET_BITS_WIDTH-1:0]            i_set_bits,
    input   wire    [B_OFFSET_BITS_WIDTH-1:0]       i_block_offset_bits,

    input   wire    [SA_WORD_WIDTH-1:0]             i_status_array_bits,
    input   wire                                    i_valid,

    input   wire    [MEM_IF_DATA-1:0]               i_mem_if_data, // pre-decoded data
    input   wire                                    i_mem_if_valid,

    input   wire                                    clk,
    input   wire                                    arst_n,
    input   wire                                    i_halt,

    input   wire                                    i_mem_if_halt,
    input   wire                                    i_sa_blocks_halt,
    input   wire                                    i_ta_blocks_halt,
    input   wire                                    i_da_blocks_halt,


    output  wire    [DA_SRAM_ADDR_WIDTH-1:0]    o_da_write_addr,
    output  wire    [DA_SRAM_WORD_WIDTH-1:0]    o_da_write_data, // data array
    output  wire    [NUM_BLOCKS-1:0]            o_da_blocks_mask,
    output  wire                                o_da_blocks_if_valid, 

    output  wire    [TA_SRAM_ADDR_WIDTH-1:0]    o_ta_write_addr,
    output  wire    [TA_SRAM_WORD_WIDTH-1:0]    o_ta_write_data, // tag array
    output  wire    [NUM_BLOCKS-1:0]            o_ta_blocks_mask,
    output  wire                                o_ta_blocks_if_valid, 

    output  wire    [SA_SRAM_ADDR_WIDTH-1:0]    o_sa_write_addr,
    output  wire    [SA_WORD_WIDTH-1:0]         o_sa_write_data, // status array
    output  wire    [NUM_BLOCKS-1:0]            o_sa_blocks_mask,
    output  wire                                o_sa_blocks_if_valid, 

    output  wire    [MEM_IF_ADDR-1:0]           o_mem_if_addr, //memory if = interface
    output  wire                                o_mem_if_req_valid,
    output  wire                                o_mem_if_ready,

    output  wire                                o_miss_state, // if 1, the cache is handling a miss, 
                                                              // if 0, cache can continue normal operation.

    output  wire                                o_ready
);
    localparam SET_BITS_WIDTH = 4;
    localparam B_OFFSET_BITS_WIDTH = 4; //block offset bits width
    localparam TAG_BITS_WIDTH = 8;

    localparam SA_WORD_WIDTH = 4*2; // sa = Status array
    localparam SA_SRAM_ADDR_WIDTH = 4;

    localparam TA_SRAM_WORD_WIDTH = 4*8;
    localparam TA_SRAM_ADDR_WIDTH = 4;

    localparam DA_SRAM_WORD_WIDTH = 20; // DA = Data Array 
    localparam DA_SRAM_ADDR_WIDTH = 8;

    localparam MEM_IF_ADDR = 16;
    localparam MEM_IF_DATA = 32;
    localparam NUM_BLOCKS = 4;

    
    assign o_ready = ~i_halt; //FIXME

    reg                             r_cache_hit;
    reg [TAG_BITS_WIDTH-1:0]        r_tag_bits;
    reg [SET_BITS_WIDTH-1:0]        r_set_bits;
    reg [B_OFFSET_BITS_WIDTH-1:0]   r_block_offset_bits;
    
    reg [SA_WORD_WIDTH-1:0]         r_status_array_bits;
    reg                             r_valid;

    reg [MEM_IF_DATA-1:0]           r_mem_if_data;
    reg                             r_mem_if_valid;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_cache_hit             <= 1'b0;
            r_tag_bits              <= {TAG_BITS_WIDTH{1'b0}};
            r_set_bits              <= {SET_BITS_WIDTH{1'b0}};
            r_block_offset_bits     <= {B_OFFSET_BITS_WIDTH{1'b0}};

            r_status_array_bits     <= {SA_WORD_WIDTH{1'b0}};
            r_valid                 <= 1'b0;;

            r_mem_if_data           <= {MEM_IF_DATA{1'b0}};
            r_mem_if_valid          <= 1'b0;
        end
        else if(o_ready) begin
            r_cache_hit             <= i_cache_hit;
            r_tag_bits              <= i_tag_bits;
            r_set_bits              <= i_set_bits;
            r_block_offset_bits     <= i_block_offset_bits;

            r_status_array_bits     <= i_status_array_bits;
            r_valid                 <= i_valid;

            r_mem_if_data           <= i_mem_if_data;
            r_mem_if_valid          <= i_mem_if_valid;
        end
    end

    wire cu_mc_initiate_mem_req;
    wire cu_mc_valid;

    control_unit ctrl_unit(
        .i_cache_hit(r_cache_hit),
        .i_valid(r_valid),

        .i_mem_data_received(),
        .i_mem_if_valid(),

        .i_arrays_update_complete(), // au == arrays update complete
        .i_auc_valid(),
        
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(), //FIXME
        
        .o_miss_state(),
        
        .o_initiate_mem_req(cu_mc_initiate_mem_req),
        .o_mem_if_valid(cu_mc_valid),
        
        .o_initiate_array_update(),
        .o_send_missed_word(), // smw == send missed word
        .o_valid(),

        .o_mem_if_ready(),
        .o_arrays_udpater_ready(),
        .o_ready()
    );

    memory_controller mem_ctrl(
        .i_block_addr(),
        .i_block_addr_valid(),
    
        .i_initiate_req(),
        .i_ir_valid(), // initiate request valid

        .i_mem_data(), // burst mode
        .i_mem_data_valid(),
        .i_mem_data_received_ack(), // ??? in case there is a delay betweeen when the memory
                                    // acknoledges our request and when the request is fulfilled

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(), //FIXME

        .o_mem_req_addr(), // burst mode
        .o_mem_req_valid(),
        .o_mem_ready(),
        
        .o_mem_data_received(),
        .o_mem_data_rcvd_valid(),

        .o_ready()
    );

    arrays_updater arrays_updater_m(
        .i_initiate_arrays_update(),
        .i_iau_valid(),

        .i_set_addr(),
        .i_set_addr_valid(),

        .i_tag_bits(),
        .i_tag_bits_valid(),

        .i_block_replacement_mask(),
        .i_brm_valid(),

        .i_mem_data(),
        .i_mem_data_valid(),

        .i_miss_state(),
    
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(), //FIXME

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

        .o_da_addr(o_da_write_addr),
        .o_da_data(o_da_write_data),
        .o_da_mask(o_da_blocks_mask),
        .o_da_valid(o_da_blocks_if_valid),


        .o_arrays_update_complete(),
        .o_auc_valid(), // arrays_update_complete_valid

        .o_ready()
    );

endmodule