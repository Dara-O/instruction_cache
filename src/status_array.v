`timescale 1ns/1ps

/*
    Status Array should be initialized after.
*/

// See file for params...
`include "shared_params.vh"

module status_array #(parameter TAG_WIDTH=1) (
    // read port
    input   wire    [TAG_WIDTH-1:0]         i_tag,
    input   wire    [ADDR_WIDTH-1:0]        i_r_addr,
    input   wire                            i_r_valid,

    // write port
    input   wire    [ADDR_WIDTH-1:0]        i_w_addr,
    input   wire    [ROW_WIDTH-1:0]         i_w_data,
    input   wire    [NUM_BLOCKS-1:0]        i_w_wmask, // positional encoding of blocks to write. 1 means block is written.
    input   wire                            i_w_valid, // 1 means write, 0 means read

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  reg     [TAG_WIDTH-1:0]         o_tag,
    output  reg     [ROW_WIDTH-1:0]         o_data,
    output  reg                             o_valid,
    output  wire                            o_ready
);
    

    assign o_ready = ~i_halt;

    wire gated_clk;
    wire [ROW_WIDTH-1:0] ss_data;

    clock_gater cg (
      .clk(clk),
      .stop_clock(i_halt),
      .gated_clock(gated_clk)
    );  
    
    sky130_sram_0kbytes_1r1w_16x8_2 status_sram (
        .clk0(gated_clk),
        .csb0(~i_w_valid),
        .wmask0(i_w_wmask),
        .addr0(i_w_addr),
        .din0(i_w_data),
        
        .clk1(gated_clk),
        .csb1(~i_r_valid),
        .addr1(i_r_addr),
        .dout1(ss_data)
    );
        
    reg r_w_valid;
    
    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            o_valid     <= 1'b0;
            r_w_valid   <= 1'b0;
        end
        else begin
            o_valid     <= i_r_valid;
            r_w_valid   <= i_w_valid;
        end
    end
    
    assign o_data =  ss_data & {ROW_WIDTH{~r_w_valid & o_valid}};

    // tag propagation
    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            o_tag <= {TAG_WIDTH{1'h0}};
        end
        else begin
            o_tag <= i_tag & {TAG_WIDTH{i_r_valid}};
        end
    end


endmodule