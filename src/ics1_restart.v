`timescale 1ns/1ps

module ics1_restart(
    input   wire    [ADDR_WIDTH-1:0]        i_curr_r_addr,
    input   wire                            i_curr_r_addr_valid,

    input   wire    [ADDR_WIDTH-1:0]        i_prev_r_addr,
    input   wire                            i_prev_r_addr_valid,

    input   wire                            i_miss_state,

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  reg     [ADDR_WIDTH-1:0]        o_r_addr,
    output  reg                             o_r_addr_valid,

    output  reg                             o_curr_r_addr_ready
);

    localparam ADDR_WIDTH       = 16;

    localparam STATE_IDLE       = 0;
    localparam STATE_RESTARTING = 1;
    localparam NUM_STATES       = 2;

    reg w_curr_r_addr_ready;
    assign o_curr_r_addr_ready = w_curr_r_addr_ready & ~i_halt;

    reg [$clog2(NUM_STATES)-1:0]    r_state;
    reg [$clog2(NUM_STATES)-1:0]    w_state;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= STATE_IDLE;
        end
        else if(~i_halt) begin
            r_state <= w_state;
        end
    end

    reg    [ADDR_WIDTH-1:0]    r_prev_r_addr;
    reg                        r_prev_r_addr_valid;
    reg                        r_miss_state;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_miss_state        <= 1'b0;
        end
        else if(~i_halt) begin
            r_miss_state        <= i_miss_state;
        end
    end

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_prev_r_addr       <= {ADDR_WIDTH{1'b0}};
            r_prev_r_addr_valid <= 1'b0;
        end
        else if(~i_halt & (~r_miss_state & i_miss_state)) begin
            r_prev_r_addr       <= i_prev_r_addr;
            r_prev_r_addr_valid <= i_prev_r_addr_valid;
        end
    end

    always @(*) begin
        case(r_state)
        STATE_IDLE  :   begin
            w_state = (i_miss_state) ? STATE_RESTARTING : STATE_IDLE;
        end
        STATE_RESTARTING : begin
            w_state = ~i_miss_state ? STATE_IDLE : STATE_RESTARTING;
        end 
        default : begin
            w_state = STATE_IDLE;
        end
        endcase
    end

    always @(*) begin
        case({w_state, r_state})
        {STATE_RESTARTING, STATE_IDLE},   
        {STATE_RESTARTING, STATE_RESTARTING}   :   begin
            o_r_addr = {ADDR_WIDTH{1'h0}};
            o_r_addr_valid = 1'b0;
            
            w_curr_r_addr_ready = 1'b0;
        end

        {STATE_IDLE, STATE_RESTARTING}  :   begin
            o_r_addr = r_prev_r_addr_valid ? r_prev_r_addr : i_curr_r_addr;
            o_r_addr_valid = r_prev_r_addr_valid | i_curr_r_addr_valid;
            
            w_curr_r_addr_ready = ~r_prev_r_addr_valid;
        end

        {STATE_IDLE, STATE_IDLE}  :   begin
            o_r_addr = i_curr_r_addr;
            o_r_addr_valid = i_curr_r_addr_valid;

            w_curr_r_addr_ready = 1'b1;
        end

        default : begin
            o_r_addr = {ADDR_WIDTH{1'h0}};
            o_r_addr_valid = 1'b0;

            w_curr_r_addr_ready = 1'b0;
        end

        endcase
    end

endmodule