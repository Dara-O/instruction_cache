`timescale 1ns/1ps

// status array write arbiter
module sa_w_arb( 
    // from use bit updater
    input   wire    [SET_ADDR_WIDTH-1:0]    i_ubit_upd_sa_set_addr, 
    input   wire    [SA_WORD_WIDTH-1:0]     i_ubit_upd_sa_data,
    input   wire    [NUM_WAYS-1:0]          i_ubit_upd_sa_mask,
    input   wire                            i_ubit_upd_sa_valid,   

    // from miss handler
    input   wire    [SET_ADDR_WIDTH-1:0]    i_miss_write_set_addr,
    input   wire    [SA_WORD_WIDTH-1:0]     i_miss_write_data, 
    input   wire    [NUM_WAYS-1:0]          i_miss_write_mask,
    input   wire                            i_miss_if_valid, 

    input   wire                            i_miss_state,

    output  reg     [SET_ADDR_WIDTH-1:0]    o_w_set_addr, 
    output  reg     [SA_WORD_WIDTH-1:0]     o_w_data,
    output  reg     [NUM_WAYS-1:0]          o_w_mask,
    output  reg                             o_w_valid 
);

    localparam SET_ADDR_WIDTH   = 4;
    localparam SA_WORD_WIDTH    = 8;
    localparam NUM_WAYS         = 4;

    always @(*) begin
        case(i_miss_state)
        1'b0    :   begin
            o_w_set_addr    = i_ubit_upd_sa_set_addr;
            o_w_data        = i_ubit_upd_sa_data;
            o_w_mask        = i_ubit_upd_sa_mask;
            o_w_valid       = i_ubit_upd_sa_valid;
        end
        1'b1    :   begin
            o_w_set_addr    =   i_miss_write_set_addr;
            o_w_data        =   i_miss_write_data;
            o_w_mask        =   i_miss_write_mask;
            o_w_valid       =   i_miss_if_valid;
        end
        default : begin
            o_w_set_addr    =   {SET_ADDR_WIDTH{1'b0}};
            o_w_data        =   {SA_WORD_WIDTH{1'b0}};
            o_w_mask        =   {NUM_WAYS{1'b0}};
            o_w_valid       =   1'b0;
        end
        endcase
    end

endmodule