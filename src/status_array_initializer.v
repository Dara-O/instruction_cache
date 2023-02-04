`timescale 1ns/1ps

module status_array_initializer(
    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  reg     [ADDR_WIDTH-1:0]        o_addr,
    output  reg     [ROW_WIDTH-1:0]         o_data,
    output  reg                             o_wen, 
    output  reg     [NUM_BLOCKS-1:0]        o_wmask,
    output  reg                             o_valid,

    output  wire                            o_init_complete,
    output  wire                            o_ready
);

    localparam NUM_ROWS     = 16;
    localparam ADDR_WIDTH   = 4; // $clog2(NUM_ROWS)
    localparam NUM_BLOCKS   = 4;
    localparam BLOCK_WIDTH  = 2;
    localparam ROW_WIDTH    = 4*2; // NUM_BLOCKS*BLOCK_WIDTH

    // for use in understanding status_array_data
    localparam USE_BIT_IDX      = 0; 
    localparam VALID_BIT_IDX    = 1;

    wire gated_clk;
    clock_gater cg (
        .clk(clk),
        .stop_clock(i_halt),
        .gated_clock(gated_clk)
    );  

    localparam [1:0] _STATE_UNINIT = 0; // uninitialized state
    localparam [1:0] _STATE_BUSY = 1;
    localparam [1:0] _STATE_READY = 2;

    reg [1:0]   r_state;
    reg [1:0]   state_next;

    assign o_init_complete = (r_state === _STATE_READY);
    assign o_ready = o_init_complete & ~i_halt;

    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            r_state <= _STATE_UNINIT;
        end
        else begin
            r_state <= state_next;
        end
    end

    reg [ADDR_WIDTH-1:0]    r_addr_next; 
    reg [ROW_WIDTH-1:0]     r_data_next; 
    reg                     r_wen_next;  
    reg [NUM_BLOCKS-1:0]    r_wmask_next;
    reg                     r_valid_next;

    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            o_addr  <= {ADDR_WIDTH{1'b0}};
            o_data  <= {ROW_WIDTH{1'b0}};
            o_wen   <= 1'b0;
            o_wmask <= {NUM_BLOCKS{1'b0}};
            o_valid <= 1'b0;
        end
        else begin
            o_addr  <= r_addr_next; 
            o_data  <= r_data_next; 
            o_wen   <= r_wen_next;  
            o_wmask <= r_wmask_next;
            o_valid <= r_valid_next;
        end
    end

    wire w_counter_stop_reached;

    // next state logic
    always @(*) begin
        case(r_state)
            _STATE_UNINIT : begin
                state_next = arst_n ? _STATE_BUSY : _STATE_UNINIT; 
            end
            
            _STATE_BUSY : begin
                state_next = w_counter_stop_reached ? _STATE_READY : _STATE_BUSY;
            end

            _STATE_READY : begin
                state_next = _STATE_READY;
            end

            default: begin
                state_next = _STATE_UNINIT;
            end
        endcase
    end

    localparam COUNTER_STOP = 2**(ADDR_WIDTH);
    reg [ADDR_WIDTH:0] r_counter;

    assign w_counter_stop_reached = (r_counter === COUNTER_STOP);

    // counter
    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            r_counter <= {ADDR_WIDTH+1{1'b0}};
        end
        else if(~w_counter_stop_reached & (r_state === _STATE_BUSY)) begin
            r_counter <= r_counter + 1;
        end
    end

    always @(*) begin
        case (r_state)
            _STATE_UNINIT, _STATE_READY : begin
                r_addr_next     = {ADDR_WIDTH{1'b0}};
                r_data_next     = {ROW_WIDTH{1'b0}};
                r_wen_next      = 1'b0;
                r_wmask_next    = {NUM_BLOCKS{1'b0}};
                r_valid_next    = 1'b0;
            end 
        
            _STATE_BUSY : begin
                r_addr_next     = r_counter[ADDR_WIDTH-1:0];
                r_data_next     = {ROW_WIDTH{1'b0}};
                r_wen_next      = 1'b1;
                r_wmask_next    = {NUM_BLOCKS{1'b1}};
                r_valid_next    = 1'b1;
            end 
            default: begin
                r_addr_next     = {ADDR_WIDTH{1'b0}};
                r_data_next     = {ROW_WIDTH{1'b0}};
                r_wen_next      = 1'b0;
                r_wmask_next    = {NUM_BLOCKS{1'b0}};
                r_valid_next    = 1'b0;
            end 
        endcase
    end

endmodule