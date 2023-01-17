`timescale 1ns/1ps

/*
    Bundles the initializer and the status_array
*/

// See file for params...
`include "shared_params.vh"

module status_array_wrapper #(parameter TAG_WIDTH=1) (
    input   wire    [TAG_WIDTH-1:0]         i_tag,
    input   wire    [ADDR_WIDTH-1:0]        i_addr,
    input   wire    [ROW_WIDTH-1:0]         i_data,
    input   wire                            i_wen, 
    input   wire    [NUM_BLOCKS-1:0]        i_wmask,
    input   wire                            i_valid,

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
    reg [ADDR_WIDTH-1:0]    r_addr;
    reg [ROW_WIDTH-1:0]     r_data;
    reg                     r_wen;
    reg [NUM_BLOCKS-1:0]    r_wmask;
    reg                     r_valid;
    
    // status array signal interception
    always @(*) begin
        case (sai_init_complete)
            1'b0 : begin
                r_tag           = {TAG_WIDTH{1'b0}};
                r_addr          = sai_addr;
                r_data          = sai_data;
                r_wen           = sai_wen;
                r_wmask         = sai_wmask;
                r_valid         = sai_valid;
            end 
            1'b1 : begin
                r_tag           = i_tag;
                r_addr          = i_addr;
                r_data          = i_data;
                r_wen           = i_wen;
                r_wmask         = i_wmask;
                r_valid         = i_valid;
            end
            default: begin
                r_tag           = {TAG_WIDTH{1'b0}};
                r_addr          = sai_addr;
                r_data          = sai_data;
                r_wen           = sai_wen;
                r_wmask         = sai_wmask;
                r_valid         = sai_valid;
            end
        endcase
    end
endmodule