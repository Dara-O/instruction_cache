`timescale 1ns/1ps

module status_array #(parameter TAG_WIDTH=1) (
    input   wire    [TAG_WIDTH-1:0]         i_tag,
    input   wire    [3:0]                   i_addr,
    input   wire    [7:0]                   i_data,
    input   wire                            i_wen, // 1 means write, 0 means read
    input   wire    [3:0]                   i_wmask, // positional encoding of blocks to write. 1 means block is written. There are four blocks, 2 bits each
    input   wire                            i_valid,

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt,

    output  reg     [TAG_WIDTH-1:0]         o_tag,
    output  reg     [7:0]                   o_data,
    output  reg                             o_data_init, // 1 if the data is from an initialized word, else 0
    output  reg                             o_valid,
    output  wire                            o_ready
);
    
    assign o_ready = ~i_halt;

    wire gated_clk;
    wire [7:0] ss_data;

    assign o_data = ss_data & {8{o_valid}};

    clock_gater cg (
      .clk(clk),
      .stop_clock(i_halt),
      .gated_clock(gated_clk)
    );
  
    
    reg     [15:0]  r_word_init;
    wire    [7:0]   ss_dout;   

    sky130_sram_0kbytes_1r1w_16x8_2 status_sram (
        .clk0(gated_clk),
        .csb0(~(i_valid & i_wen)),
        .wmask0(i_wmask),
        .addr0(i_addr),
        .din0(i_data),
        
        .clk1(gated_clk),
        .csb1(~i_valid | i_wen),
        .addr1(i_addr),
        .dout1(ss_data)
    );

    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin            
            r_word_init <= 16'h0;
            o_valid     <= 1'h0;
        end
        else if(i_valid) begin                
            if(i_wen) begin
                r_word_init[i_addr] <= i_valid;
                
                // set output zero
                o_data_init <= 1'h0;
                o_valid     <= 1'h0;
            end
            else begin
                o_data_init <= r_word_init[i_addr];
                o_valid     <= i_valid;
            end
        end
        else begin
            o_data_init <= 1'h0;
            o_valid     <= 1'h0;
        end
    end

    // tag propagation
    always @(posedge gated_clk, negedge arst_n) begin
        if(~arst_n) begin
            o_tag <= {TAG_WIDTH{1'h0}};
        end
        else if(~i_halt) begin
            o_tag <= i_tag & {TAG_WIDTH{i_valid}};
        end
    end


endmodule