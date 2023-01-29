`timescale 1ns/1ps

module memory_controller(
    input   wire    [ADDR_WIDTH-1:0]            i_block_addr, // from miss handler flop
    input   wire                                i_block_addr_valid,

    input   wire                                i_initiate_req, // from contorl unit
    input   wire                                i_ir_valid, // ir == initiate request

    input   wire    [MEM_DATA_WIDTH-1:0]        i_mem_data, // from memory
    input   wire                                i_mem_data_valid, // expect to be valid for 10 cycles after first assertion

    input   wire                                clk,
    input   wire                                arst_n, 
    input   wire                                i_halt, 

    output  wire    [ADDR_WIDTH-1:0]            o_mem_req_addr, // to memory
    output  wire                                o_mem_req_valid,
    output  wire                                o_mem_ready,

    output  wire                                o_mem_data_received, // to control unit 
    output  wire                                o_mem_data_rcvd_valid,
    output  wire                                o_ir_ready, // to control unit; ir == initiate request 

    output  reg     [MEM_BLOCK_DATA_WIDTH-1:0]  o_mem_block_data, // to data dispatcher (array updater and user readout)
    output  wire                                o_mem_block_data_valid
   
);
    localparam ADDR_WIDTH           = 8;
    localparam MEM_DATA_WIDTH       = 32;
    localparam MEM_BLOCK_DATA_WIDTH = 320;
    
    localparam  NUM_MEM_TRANSACTIONS = 10; // NUM_MEM_TRANSACTIONS*MEM_DATA_WIDTH = MEM_BLOCK_DATA_WIDTH

    assign o_ir_ready = ~i_halt;

    localparam STATE_IDLE           = 0;
    localparam STATE_MEM_REQUESTED  = 1;
    localparam STATE_MEM_RECEIVING  = 2;
    localparam NUM_STATES = 3;

    reg r_initiate_req;
    reg r_ir_valid;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_initiate_req <= 1'b0;
            r_ir_valid <= 1'b0;
        end
        else if(~i_halt) begin
            r_initiate_req  <= i_initiate_req;
            r_ir_valid      <= i_ir_valid;
        end
    end

    reg [$clog2(NUM_STATES)-1:0]    r_state;
    reg [$clog2(NUM_STATES)-1:0]    w_state; 
    
    reg [$clog2(NUM_MEM_TRANSACTIONS):0] r_transactions_counter;
    wire w_all_words_received;

    assign w_all_words_received = (r_transactions_counter === NUM_MEM_TRANSACTIONS); 

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= {$clog2(NUM_STATES){1'b0}};
        end
        else begin
            r_state <= w_state;
        end
    end

    // FSM Next state logic
    always @(*) begin
        case(r_state)
        STATE_IDLE : begin
            w_state = (r_initiate_req & r_ir_valid) ? STATE_MEM_REQUESTED : STATE_IDLE;
        end
        STATE_MEM_REQUESTED :  begin
            w_state = (i_mem_data_valid) ? STATE_MEM_RECEIVING : STATE_MEM_REQUESTED;
        end
        STATE_MEM_RECEIVING : begin
            w_state = (w_all_words_received) ? STATE_IDLE : STATE_MEM_RECEIVING;
        end 

        default : begin
            w_state = STATE_IDLE;
        end
        endcase
    end

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_transactions_counter <= {($clog2(NUM_MEM_TRANSACTIONS)+1){1'b0}};
        end
        else if(~i_halt & (
                (w_state === STATE_MEM_RECEIVING) | 
                (r_transactions_counter !== {($clog2(NUM_MEM_TRANSACTIONS)+1){1'b0}})
            )) begin
                
            r_transactions_counter <= (r_transactions_counter === NUM_MEM_TRANSACTIONS) ? {($clog2(NUM_MEM_TRANSACTIONS)+1){1'b0}} :
                                                                                           r_transactions_counter + 1;
        end
    end

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_mem_block_data <= {MEM_BLOCK_DATA_WIDTH{1'b0}};
        end
        else if(~i_halt & i_mem_data_valid &
                (~w_all_words_received | (w_state === STATE_MEM_RECEIVING))) begin
            case(r_transactions_counter) // elaborated to avoid synthesizing mula multiplier
            4'd0: begin
                o_mem_block_data[31:0] <= i_mem_data;
            end
            4'd1: begin
                o_mem_block_data[63:32] <= i_mem_data;
            end
            4'd2: begin
                o_mem_block_data[95:64] <= i_mem_data;
            end
            4'd3: begin
                o_mem_block_data[127:96] <= i_mem_data;
            end
            4'd4: begin
                o_mem_block_data[159:128] <= i_mem_data;
            end
            4'd5: begin
                o_mem_block_data[191:160] <= i_mem_data;
            end
            4'd6: begin
                o_mem_block_data[223:192] <= i_mem_data;
            end
            4'd7: begin
                o_mem_block_data[255:224] <= i_mem_data;
            end
            4'd8: begin
                o_mem_block_data[287:256] <= i_mem_data;
            end
            4'd9: begin
                o_mem_block_data[319:288] <= i_mem_data;
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
    //assign o_mem_block_data_valid = (w_all_words_received & (w_state === STATE_IDLE));

    assign o_mem_req_addr = ((w_state === STATE_MEM_REQUESTED) & r_state !== STATE_MEM_REQUESTED)  ? i_block_addr :
                                                                                            {ADDR_WIDTH{1'b0}};

    assign o_mem_req_valid = ((w_state === STATE_MEM_REQUESTED) & r_state !== STATE_MEM_REQUESTED) ? i_block_addr_valid : 1'b0;

    assign o_mem_ready = (r_state === STATE_MEM_REQUESTED) | (w_state === STATE_MEM_RECEIVING);
    assign o_mem_data_received = (w_all_words_received & (r_state === STATE_MEM_RECEIVING));
    assign o_mem_data_rcvd_valid = ~i_halt;
endmodule