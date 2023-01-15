`timescale 1ns/1ps

module stat_reg_file_wrapper #(parameter ADDR_WIDTH=3) (
    input   wire    [ADDR_WIDTH-1:0]    i_addr,
    input   wire                        i_use,
    input   wire                        i_block_valid,
    input   wire                        i_spare_bit,
    input   wire                        i_wen, // 1 means write, 0 means read
    input   wire                        i_valid, 
    
    input   wire                        clk,
    input   wire                        arst_n,
    input   wire                        i_halt, 

    output  wire                        o_use,
    output  wire                        o_block_valid,
    input   wire                        o_spare_bit,
    output  wire                        o_valid,

    output  wire                        o_freeze_inputs
);

    wire srf_block_init;
    wire srf_block_valid;

    assign o_block_valid = srf_block_valid & srf_block_init; //  an uninitialized block cannot be valid

    status_register_file #(
        .WORD_WIDTH(12),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TAG_WIDTH(1)
    ) stat_reg_file (
        .i_tag(1'h0),
        .i_addr(i_addr),
        .i_data({i_use, i_block_valid, i_spare_bit}),
        .i_wen(i_wen),
        .i_valid(i_valid),

        .clk(clk),
        .arst_n(arst_n),
        .i_halt(i_halt),

        .o_tag(),
        .o_data({o_use, srf_block_valid, o_spare_bit}),
        .o_data_init(srf_block_init),
        .o_valid(o_valid),

        .o_freeze_inputs(o_freeze_inputs)
    );
  

endmodule