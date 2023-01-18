`timescale 1ns/1ps

/*
    Bundles the initializer and the status_array
*/

// See file for params...
`include "shared_params.vh"

module status_array_wrapper #(parameter TAG_WIDTH=1) (
    // read port
    input   wire    [TAG_WIDTH-1:0]         i_tag,
    input   wire    [ADDR_WIDTH-1:0]        i_r_addr,
    input   wire                            i_r_valid,

    // write port
    input   wire    [ADDR_WIDTH-1:0]        i_w_addr,
    input   wire    [ROW_WIDTH-1:0]         i_w_data,
    input   wire    [NUM_BLOCKS-1:0]        i_w_wmask,
    input   wire                            i_w_valid,

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  reg     [TAG_WIDTH-1:0]         o_tag,
    output  reg     [ROW_WIDTH-1:0]         o_data,
    output  reg                             o_valid,
    output  wire                            o_ready
);

    // sai == status_array_initializer output signals
    wire [ADDR_WIDTH-1:0]   sai_addr;
    wire [ROW_WIDTH-1:0]    sai_data;
    wire                    sai_wen;
    wire [NUM_BLOCKS-1:0]   sai_wmask;
    wire                    sai_valid;
    wire                    sai_init_complete;
    wire                    sai_ready;

    wire sa_ready;
    assign o_ready = sa_ready & sai_ready;

    status_array_initializer sa_initializer (
        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_addr(sai_addr),
        .o_data(sai_data),
        .o_wen(sai_wen),
        .o_wmask(sai_wmask),
        .o_valid(sai_valid),
        .o_init_complete(sai_init_complete),
        .o_ready(sai_ready)
    );

    reg [TAG_WIDTH-1:0]     r_tag;
    reg [ADDR_WIDTH-1:0]    r_w_addr;
    reg [ROW_WIDTH-1:0]     r_w_data;
    reg                     r_w_valid;
    reg [NUM_BLOCKS-1:0]    r_w_wmask;
    
    // status array signal interception
    always @(*) begin
        case (sai_init_complete)
            1'b0 : begin
                r_tag           = {TAG_WIDTH{1'h0}};
                r_w_addr        = sai_addr;
                r_w_data        = sai_data;
                r_w_valid       = sai_wen & sai_valid;
                r_w_wmask       = sai_wmask;
            end 
            1'b1 : begin
                r_tag           = i_tag;
                r_w_addr        = i_w_addr;
                r_w_data        = i_w_data;
                r_w_valid       = i_w_valid;
                r_w_wmask       = i_w_wmask;
            end
            default: begin
                r_tag           = {TAG_WIDTH{1'h0}};
                r_w_addr        = sai_addr;
                r_w_data        = sai_data;
                r_w_valid       = sai_wen & sai_valid;
                r_w_wmask       = sai_wmask;
            end
        endcase
    end

    status_array #(.TAG_WIDTH(TAG_WIDTH)) stat_array (
      .i_tag(r_tag),
      .i_r_addr(i_r_addr),
      .i_r_valid(i_r_valid),

      .i_w_addr(r_w_addr),
      .i_w_data(r_w_data),
      .i_w_wmask(r_w_wmask),
      .i_w_valid(r_w_valid),

      .clk(clk),
      .arst_n(arst_n),
      .i_halt(i_halt),

      .o_tag(o_tag),
      .o_data(o_data),
      .o_valid(o_valid),
      .o_ready(sa_ready)
    );


endmodule