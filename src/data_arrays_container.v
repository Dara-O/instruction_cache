`timescale 1ps/1ps

module data_arrays_container (
    input   wire    [SET_BITS_WIDTH-1:0]        i_r_set_bits,
    input   wire    [$clog2(NUM_WAYS)-1:0]      i_r_way_index,
    input   wire    [B_OFFSET_BITS_WIDTH-1:0]   i_r_block_offset_bits,
    input   wire                                i_r_valid,
    
    input   wire    [SET_BITS_WIDTH-1:0]        i_w_set_bits,
    input   wire    [$clog2(NUM_WAYS)-1:0]      i_w_way_index,
    input   wire    [B_OFFSET_BITS_WIDTH-3:0]   i_w_block_offset_bits,
    input   wire    [WRITE_WORD_WIDTH-1:0]      i_w_data,
    input   wire                                i_w_valid,

    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt_all,
    input   wire                                i_stop_read_clk,
    input   wire                                i_stop_write_clk,

    output  reg     [READ_WORD_WIDTH-1:0]       o_word_data,
    output  reg                                 o_valid,

    output  wire                                o_ready
);
    localparam SET_BITS_WIDTH  = 4;    
    localparam B_OFFSET_BITS_WIDTH = 4;
    
    localparam READ_WORD_WIDTH  = 20;
    localparam WRITE_WORD_WIDTH = 20*4;// 4 == number of srams
    localparam NUM_WAYS         = 4;

    assign o_ready = ~(i_halt_all);

    wire write_clk;
    clock_gater cg_read (
        .clk(clk),
        .stop_clock(i_halt_all | i_stop_write_clk),
        .gated_clock(write_clk)
    );

    wire read_clk;
    clock_gater cg_write (
        .clk(clk),
        .stop_clock(i_halt_all | i_stop_read_clk),
        .gated_clock(read_clk)
    );

    wire [READ_WORD_WIDTH-1:0]   sram0_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram0 (
        .clk0(write_clk),
        .csb0(~i_w_valid),
        .addr0({i_w_set_bits, i_w_way_index, i_w_block_offset_bits}),
        .din0(i_w_data[19:0]),

        .clk1(read_clk),
        .csb1(~(i_r_valid & (i_r_block_offset_bits[1:0] === 2'b00))),
        .addr1({i_r_set_bits, i_r_way_index, i_r_block_offset_bits[3:2]}),
        .dout1(sram0_data)
    );

    wire [READ_WORD_WIDTH-1:0]   sram1_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram1 (
        .clk0(write_clk),
        .csb0(~i_w_valid),
        .addr0({i_w_set_bits, i_w_way_index, i_w_block_offset_bits}),
        .din0(i_w_data[39:20]),

        .clk1(read_clk),
        .csb1(~(i_r_valid & (i_r_block_offset_bits[1:0] === 2'b01))),
        .addr1({i_r_set_bits, i_r_way_index, i_r_block_offset_bits[3:2]}),
        .dout1(sram1_data)
    );

    wire [READ_WORD_WIDTH-1:0]   sram2_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram2 (
        .clk0(write_clk),
        .csb0(~i_w_valid),
        .addr0({i_w_set_bits, i_w_way_index, i_w_block_offset_bits}),
        .din0(i_w_data[59:40]),

        .clk1(read_clk),
        .csb1(~(i_r_valid & (i_r_block_offset_bits[1:0] === 2'b10))),
        .addr1({i_r_set_bits, i_r_way_index, i_r_block_offset_bits[3:2]}),
        .dout1(sram2_data)
    );

    wire [READ_WORD_WIDTH-1:0]   sram3_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram3 (
        .clk0(write_clk),
        .csb0(~i_w_valid),
        .addr0({i_w_set_bits, i_w_way_index, i_w_block_offset_bits}),
        .din0(i_w_data[79:60]),

        .clk1(read_clk),
        .csb1(~(i_r_valid & (i_r_block_offset_bits[1:0] === 2'b11))),
        .addr1({i_r_set_bits, i_r_way_index, i_r_block_offset_bits[3:2]}),
        .dout1(sram3_data)
    );

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_valid <= 1'b0;
        end
        else if(~i_halt_all) begin
            o_valid <= i_r_valid & ~i_stop_read_clk;
        end
    end

    reg [$clog2(NUM_WAYS):0]    r_r_block_offset_bits;
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_r_block_offset_bits <= {$clog2(NUM_WAYS){1'b0}};
        end
        else if(~i_halt_all) begin
            r_r_block_offset_bits <= i_r_block_offset_bits[1:0] & {$clog2(NUM_WAYS){~i_stop_read_clk}};
        end
    end

    always @(*) begin
        case(r_r_block_offset_bits)
        2'b11 :   begin
            o_word_data = sram3_data;
        end

        4'b10 :   begin
            o_word_data = sram2_data;
        end
        
        4'b01 :   begin
            o_word_data = sram1_data;
        end

        4'b00 :   begin
            o_word_data = sram0_data;
        end

        default : begin
            o_word_data = {READ_WORD_WIDTH{1'b0}};
        end

        endcase
    end
  

endmodule