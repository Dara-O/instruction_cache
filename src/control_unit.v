`timescale 1ns/1ps

module control_unit (
    input   wire    i_cache_hit,
    input   wire    i_valid, 
    
    input   wire    i_mem_data_received,
    input   wire    i_mem_if_valid,

    input   wire    i_arrays_update_complete,
    input   wire    i_auc_valid,

    input   wire    clk,
    input   wire    arst_n, 
    input   wire    i_halt, 

    output  wire    o_miss_state,
    
    output  wire    o_initiate_mem_req,
    output  wire    o_mem_if_valid,

    output  wire    o_initiate_array_update,
    output  wire    o_send_missed_word,
    output  wire    o_valid,
    
    output  wire    o_mem_if_ready,
    output  wire    o_arrays_updater_ready,
    output  wire    o_ready
);

    localparam STATE_IDLE               = 0;
    localparam STATE_MEM_REQ            = 1;
    localparam STATE_ARRAY_UPDATE       = 2;
    localparam NUM_STATES               = 3;

    reg     [$clog2(NUM_STATES)-1:0]    r_state;
    reg     [$clog2(NUM_STATES)-1:0]    w_state;
    

    assign o_ready = ~(i_halt | o_miss_state);
    assign o_arrays_updater_ready = ~i_halt;
    
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= {$clog2(NUM_STATES){1'b0}};
        end
        else if(~i_halt) begin
            r_state <= w_state;
        end
    end

    always @(*) begin
        case (r_state)
            STATE_IDLE  :   begin
                w_state = (~i_cache_hit & i_valid) ? STATE_MEM_REQ : STATE_IDLE;
            end 

            STATE_MEM_REQ : begin
                w_state = (i_mem_data_received & i_mem_if_valid) ? STATE_ARRAY_UPDATE : STATE_MEM_REQ;
            end

            STATE_ARRAY_UPDATE : begin
                w_state = (i_arrays_update_complete & i_auc_valid) ? STATE_IDLE : STATE_ARRAY_UPDATE;
            end
            default: begin
                w_state = STATE_IDLE;
            end
        endcase
    end

    assign o_miss_state         = (w_state !== STATE_IDLE); 
    
    assign o_initiate_mem_req   = (w_state === STATE_MEM_REQ) & (r_state !== STATE_MEM_REQ); // (~i_cache_hit & i_valid) & (r_state === STATE_IDLE);
    assign o_mem_if_valid       = (w_state === STATE_MEM_REQ);
    assign o_mem_if_ready       = (w_state === STATE_MEM_REQ) & ~i_halt;

    assign o_initiate_array_update = (w_state === STATE_ARRAY_UPDATE) & (r_state !== STATE_ARRAY_UPDATE);
    assign o_send_missed_word   = (w_state === STATE_IDLE) & (r_state !== STATE_IDLE);
    
    assign o_valid = (w_state !== STATE_IDLE) | (r_state !== STATE_IDLE);


endmodule