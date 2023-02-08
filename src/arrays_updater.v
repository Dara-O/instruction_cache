`timescale 1ns/1ps

module arrays_updater (
    input   wire                                        i_initiate_arrays_update,
    input   wire                                        i_iau_valid,

    input   wire        [SET_ADDR_WIDTH-1:0]            i_set_addr,
    input   wire                                        i_set_addr_valid,

    input   wire        [TAG_BITS_WIDTH-1:0]            i_tag_bits,
    input   wire                                        i_tag_bits_valid,

    input   wire        [MASK_WIDTH-1:0]                i_block_replacement_mask,
    input   wire                                        i_brm_valid, 

    input   wire        [MEM_DATA_WIDTH-1:0]            i_mem_data,
    input   wire        [$clog2(NUM_WORDS_PER_BLOCK):0] i_mem_num_words_rcvd,
    input   wire                                        i_mem_data_valid,

    input   wire                                        i_miss_state,

    input   wire                                        clk,
    input   wire                                        arst_n,
    input   wire                                        i_halt,

    input   wire                                        i_ta_blocks_halt,
    input   wire                                        i_sa_blocks_halt,
    input   wire                                        i_da_blocks_halt,

    output  wire        [TA_ADDR_WIDTH-1:0]             o_ta_addr,
    output  reg         [TA_DATA_WIDTH-1:0]             o_ta_data,
    output  wire        [MASK_WIDTH-1:0]                o_ta_mask,
    output  wire                                        o_ta_valid,
    
    output  wire        [SA_ADDR_WIDTH-1:0]             o_sa_addr,
    output  reg         [SA_DATA_WIDTH-1:0]             o_sa_data,
    output  wire        [MASK_WIDTH-1:0]                o_sa_mask,
    output  wire                                        o_sa_valid,

    output  wire        [DA_ADDR_WIDTH-1:0]             o_da_addr,
    output  reg         [DA_DATA_WIDTH-1:0]             o_da_data,
    output  wire                                        o_da_valid,

    output  wire                                        o_arrays_update_complete,
    output  wire                                        o_auc_valid,

    output  wire                                        o_ready
);

    assign o_ready = ~(i_halt | (r_state === STATE_UPDATING_ARRAYS));

    localparam MEM_DATA_WIDTH = 320;
    localparam MASK_WIDTH = 4;

    localparam SET_ADDR_WIDTH = 4;

    // tag array params 
    localparam TA_ADDR_WIDTH = 4;
    localparam TA_DATA_WIDTH = 32;

    // status array params
    localparam SA_ADDR_WIDTH = 4;
    localparam SA_DATA_WIDTH = 8;
    
    // data array params
    localparam DA_ADDR_WIDTH = 8;
    localparam DA_DATA_WIDTH = 20*4; // we write four 20-bit words each cycle
    localparam NUM_WAYS      = 4;

    localparam TAG_BITS_WIDTH = 8;


    localparam NUM_WORDS_PER_BLOCK = 16;
    localparam NUM_DA_TRANSACTIONS = 4;

    localparam STATE_IDLE = 0;
    localparam STATE_UPDATING_ARRAYS = 1;
    localparam NUM_STATES = 2;

    reg [$clog2(NUM_STATES)-1:0] r_state;
    reg [$clog2(NUM_STATES)-1:0] w_state;

    // FSM flop
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= {$clog2(NUM_STATES){1'b0}};
        end
        else if(~(i_halt | (i_ta_blocks_halt & 
                            i_sa_blocks_halt & 
                            i_da_blocks_halt & 
                            (r_state === STATE_UPDATING_ARRAYS)))) begin

            r_state <= w_state;
        end
    end

    reg  w_ta_update_complete;
    reg  w_sa_update_complete;
    wire w_da_update_complete;

    wire w_data_is_sendable = (|i_mem_num_words_rcvd) | i_mem_data_valid;

    // only increment when a 4*n words have been received
    wire w_advance_transaction_cnt = i_mem_data_valid | (
                            ~i_mem_num_words_rcvd[1] & (|i_mem_num_words_rcvd[4:2]) &
                            (r_prev_mem_num_words_rcvd !== i_mem_num_words_rcvd)
                        );

    reg [$clog2(NUM_WORDS_PER_BLOCK):0] r_prev_mem_num_words_rcvd;
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_prev_mem_num_words_rcvd <= {$clog2(NUM_WORDS_PER_BLOCK)+1{1'b0}};
        end
        else if(~i_halt) begin
            r_prev_mem_num_words_rcvd <= i_mem_num_words_rcvd;
        end
    end

    // FSM transition logic 
    always @(*) begin
        case(r_state)
        STATE_IDLE : begin
            w_state = (i_initiate_arrays_update & i_iau_valid & w_data_is_sendable & i_miss_state) ? STATE_UPDATING_ARRAYS :
                                                                                                     STATE_IDLE;
        end 

        STATE_UPDATING_ARRAYS : begin
            w_state = (w_ta_update_complete & w_sa_update_complete & w_da_update_complete) ? STATE_IDLE : STATE_UPDATING_ARRAYS;
        end

        default :  begin
            w_state  = STATE_IDLE;
        end
        endcase
    end

    assign o_arrays_update_complete = (w_ta_update_complete & w_sa_update_complete & w_da_update_complete);
    assign o_auc_valid = o_arrays_update_complete & (r_state !== STATE_IDLE);

    reg [$clog2(NUM_DA_TRANSACTIONS):0]   r_da_transactions_counter;
    wire w_max_num_transactions_reached = (r_da_transactions_counter === NUM_DA_TRANSACTIONS);

    // counter for the number of words written to the data array
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_da_transactions_counter <= {$clog2(NUM_DA_TRANSACTIONS)+1{1'b0}};
        end
        else if(~i_halt & ((w_state === STATE_UPDATING_ARRAYS) 
                        & w_advance_transaction_cnt 
                        & ~i_da_blocks_halt 
                        | w_max_num_transactions_reached)) begin
            r_da_transactions_counter <= w_max_num_transactions_reached ? {$clog2(NUM_DA_TRANSACTIONS)+1{1'b0}} :
                                                                          r_da_transactions_counter+1;
        end
    end


    reg [$clog2(NUM_WAYS)-1:0] w_way_index;
    always @(*) begin : mask_two_way_index_converter
        casez (i_block_replacement_mask & {MASK_WIDTH{o_da_valid}})
            4'b1???: begin
                w_way_index = 2'd3;
            end
            4'b01??: begin
                w_way_index = 2'd2;
            end
            4'b001?: begin
                w_way_index = 2'd1;
            end
            4'b0001: begin
                w_way_index = 2'd0;
            end
            default: begin
                w_way_index = 2'd0;
            end
        endcase
    end

    assign o_da_addr = {i_set_addr, w_way_index, r_da_transactions_counter[1:0]}; 
    assign o_da_valid = (w_state === STATE_UPDATING_ARRAYS) & i_set_addr_valid & i_brm_valid & w_data_is_sendable;

    assign w_da_update_complete = w_max_num_transactions_reached & (r_state === STATE_UPDATING_ARRAYS);

    // autogenerated using vpp.pl (perlpp is better)
    always @(*) begin
        case(r_da_transactions_counter[1:0])
        2'd0 : begin
            o_da_data = i_mem_data[79:0];
        end
        2'd1 : begin
            o_da_data = i_mem_data[159:80];
        end
        2'd2 : begin
            o_da_data = i_mem_data[239:160];
        end
        2'd3 : begin
            o_da_data = i_mem_data[319:240];
        end

        default : begin
            o_da_data = {DA_DATA_WIDTH{1'b0}};
        end
        endcase
    end

    assign o_ta_addr = i_set_addr;
    assign o_ta_valid = i_set_addr_valid & i_brm_valid & i_tag_bits_valid & (w_state === STATE_UPDATING_ARRAYS) & ~w_ta_update_complete;
    assign o_ta_mask = i_block_replacement_mask & {MASK_WIDTH{o_ta_valid}};

    assign o_sa_addr = i_set_addr;
    assign o_sa_valid = i_set_addr_valid & i_brm_valid & (w_state === STATE_UPDATING_ARRAYS) & ~w_sa_update_complete;
    assign o_sa_mask = i_block_replacement_mask & {MASK_WIDTH{o_ta_valid}};

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            w_ta_update_complete <= 1'b0;
            w_sa_update_complete <= 1'b0;
        end
        else if(~i_halt) begin
            if(~i_ta_blocks_halt & o_ta_valid & o_sa_valid &
            ((w_state === STATE_UPDATING_ARRAYS) & (r_state !== STATE_UPDATING_ARRAYS))) begin
                w_ta_update_complete <= 1'b1;
                w_sa_update_complete <= 1'b1;
            end
            else if(~i_miss_state) begin
                    w_ta_update_complete <= 1'b0;
                    w_sa_update_complete <= 1'b0;
            end
        end
    end

    wire [TA_DATA_WIDTH-1:0]    w_ta_data = {24'b0, i_tag_bits & {TAG_BITS_WIDTH{i_tag_bits_valid}}};
    wire [SA_DATA_WIDTH-1:0]    w_sa_data = {6'b0,
                                            1'b1, // valid bit
                                            1'b1 // use bit
                                        };
    always @(*) begin
        case (i_block_replacement_mask & {MASK_WIDTH{i_brm_valid}})
            4'b0000: begin
                o_ta_data = {TA_DATA_WIDTH{1'b0}};
                o_sa_data = {SA_DATA_WIDTH{1'b0}};
            end
            4'b0001: begin
                o_ta_data = w_ta_data;
                o_sa_data = w_sa_data;
            end

            4'b0010: begin
                o_ta_data = w_ta_data << 8*1; //8 == TAG_BITS_WIDTH
                o_sa_data = w_sa_data << 2*1; //2 == status array word width
            end

            4'b0100: begin
                o_ta_data = w_ta_data << 8*2;
                o_sa_data = w_sa_data << 2*2; 
            end

            4'b1000: begin
                o_ta_data = w_ta_data << 8*3; 
                o_sa_data = w_sa_data << 2*3;
            end
            default: begin
                o_ta_data = {TA_DATA_WIDTH{1'b0}};
                o_sa_data = {SA_DATA_WIDTH{1'b0}};
            end
        endcase
    end

endmodule