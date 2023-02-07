`timescale 1ns/1ps

module memory_controller(
    input   wire    [ADDR_WIDTH-1:0]                i_block_addr, // from miss handler
    input   wire                                    i_block_addr_valid,

    input   wire                                    i_initiate_req, // from contorl unit
    input   wire                                    i_ir_valid, // ir == initiate request

    input   wire    [EXT_MEM_DATA_WIDTH-1:0]        i_mem_data, // from memory
    input   wire                                    i_mem_data_valid, 

    input   wire                                    clk,
    input   wire                                    arst_n, 
    input   wire                                    i_halt, 

    output  wire    [ADDR_WIDTH-1:0]                o_mem_req_addr, // to memory
    output  wire                                    o_mem_req_valid,
    output  wire                                    o_mem_ready,

    output  wire                                    o_mem_data_received, // to control unit 
    output  wire                                    o_mem_data_rcvd_valid,
    output  wire                                    o_ir_ready, 

    output  reg     [MEM_BLOCK_DATA_WIDTH-1:0]      o_mem_block_data,
    output  wire    [$clog2(NUM_WORDS_P_BLOCK):0]   o_mem_num_words_rcvd, 
    output  wire                                    o_mem_block_data_valid
   
);
    localparam ADDR_WIDTH           = 16;
    localparam EXT_MEM_DATA_WIDTH   = 40;
    localparam INT_MEM_DATA_WIDTH   = 80;
    localparam MEM_BLOCK_DATA_WIDTH = 320;
    
    localparam  NUM_MEM_TRANSACTIONS    = 4; //  MEM_BLOCK_DATA_WIDTH = NUM_MEM_TRANSACTIONS*INT_MEM_DATA_WIDTH
    localparam  NUM_WORDS_P_BLOCK     = 16;

    localparam STATE_IDLE           = 0;
    localparam STATE_MEM_REQUESTED  = 1;
    localparam STATE_MEM_RECEIVING  = 2;
    localparam NUM_STATES = 3;

    // uncomment if post-sta period is too small
    // reg r_initiate_req;
    // reg r_ir_valid;

    // always @(posedge clk, negedge arst_n) begin
    //     if(~arst_n) begin
    //         r_initiate_req <= 1'b0;
    //         r_ir_valid <= 1'b0;
    //     end
    //     else if(~i_halt) begin
    //         r_initiate_req  <= i_initiate_req;
    //         r_ir_valid      <= i_ir_valid;
    //     end
    // end

    wire [INT_MEM_DATA_WIDTH-1:0]   mb_mem_data;
    wire                            mb_mem_data_valid;

    memory_buffer memory_buffer_m(
        .i_mem_data(i_mem_data),
        .i_mem_data_valid(i_mem_data_valid),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_mem_data(mb_mem_data),
        .o_mem_data_valid(mb_mem_data_valid),
        .o_ready(o_ir_ready)
    );
  


    reg [$clog2(NUM_STATES)-1:0]    r_state;
    reg [$clog2(NUM_STATES)-1:0]    w_state; 
    
    reg [$clog2(NUM_MEM_TRANSACTIONS):0] r_transactions_counter;
    wire w_all_words_received;

    assign w_all_words_received = (r_transactions_counter === NUM_MEM_TRANSACTIONS); 
    assign o_mem_num_words_rcvd = r_transactions_counter << 2;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= {$clog2(NUM_STATES){1'b0}};
        end
        else if(~i_halt) begin
            r_state <= w_state;
        end
    end

    // FSM Next state logic
    always @(*) begin
        case(r_state)
        STATE_IDLE : begin
            w_state = (i_initiate_req & i_ir_valid) ? STATE_MEM_REQUESTED : STATE_IDLE;
        end
        STATE_MEM_REQUESTED :  begin
            w_state = (mb_mem_data_valid) ? STATE_MEM_RECEIVING : STATE_MEM_REQUESTED;
        end
        STATE_MEM_RECEIVING : begin
            w_state = (w_all_words_received) ? STATE_IDLE : STATE_MEM_RECEIVING;
        end 

        default : begin
            w_state = STATE_IDLE;
        end
        endcase
    end

    always @(negedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_transactions_counter <= {($clog2(NUM_MEM_TRANSACTIONS)+1){1'b0}};
        end
        else if(~i_halt & (
                ((w_state === STATE_MEM_RECEIVING) & mb_mem_data_valid) | 
                (r_transactions_counter === NUM_MEM_TRANSACTIONS)
            )) begin
                
            r_transactions_counter <= (r_transactions_counter === NUM_MEM_TRANSACTIONS) ? {($clog2(NUM_MEM_TRANSACTIONS)+1){1'b0}} :
                                                                                           r_transactions_counter + 1;
        end
    end

    always @(negedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_mem_block_data <= {MEM_BLOCK_DATA_WIDTH{1'b0}};
        end
        else if(~i_halt & mb_mem_data_valid &
                (~w_all_words_received | (w_state === STATE_MEM_RECEIVING))) begin
            case(r_transactions_counter) // elaborated to avoid synthesizing multiplier
            4'd0: begin
                o_mem_block_data[79:0] <= mb_mem_data;
            end
            4'd1: begin
                o_mem_block_data[159:80] <= mb_mem_data;
            end
            4'd2: begin
                o_mem_block_data[239:160] <= mb_mem_data;
            end
            4'd3: begin
                o_mem_block_data[319:240] <= mb_mem_data;
            end
            endcase
        end
    end
    
    reg r_mem_block_data_valid;
    assign o_mem_block_data_valid = w_all_words_received | r_mem_block_data_valid;
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_mem_block_data_valid <= 1'b0;
        end
        else if(~i_halt) begin
            if(w_all_words_received) begin
                r_mem_block_data_valid <= 1'b1;
            end 
            else if(w_state === STATE_MEM_REQUESTED) begin
                r_mem_block_data_valid <= 1'b0;
            end
        end
    end

    assign o_mem_req_addr = ((w_state === STATE_MEM_REQUESTED) & r_state !== STATE_MEM_REQUESTED)  ? i_block_addr :
                                                                                            {ADDR_WIDTH{1'b0}};

    assign o_mem_req_valid = ((w_state === STATE_MEM_REQUESTED) & r_state !== STATE_MEM_REQUESTED) ? i_block_addr_valid : 1'b0;

    assign o_mem_ready = ((r_state === STATE_MEM_REQUESTED) | (w_state === STATE_MEM_RECEIVING)) & ~i_halt;
    assign o_mem_data_received = (w_all_words_received & (r_state === STATE_MEM_RECEIVING));
    assign o_mem_data_rcvd_valid = ~i_halt; 
endmodule