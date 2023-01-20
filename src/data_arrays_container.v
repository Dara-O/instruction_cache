`timescale 1ps/1ps

module data_arrays_container (
    input   wire    [ADDR_WIDTH-1:0]            i_r_addr,
    input   wire                                i_r_valid,
    input   wire    [NUM_BLOCKS-1:0]            i_r_mask,
    
    input   wire    [ADDR_WIDTH-1:0]            i_w_addr,
    input   wire    [WORD_WIDTH-1:0]            i_w_data,
    input   wire                                i_w_valid,
    input   wire    [NUM_BLOCKS-1:0]            i_w_mask,


    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt_all,
    input   wire                                i_stop_read_clk,
    input   wire                                i_stop_write_clk,

    output  reg     [WORD_WIDTH-1:0]            o_word_data,
    output  reg                                 o_valid,

    output  wire                                o_ready
);
    localparam ADDR_WIDTH   = 8;
    localparam WORD_WIDTH   = 20;
    localparam NUM_BLOCKS   = 4;

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

    wire [WORD_WIDTH-1:0]   sram0_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram0 (
        .clk0(write_clk),
        .csb0(~(i_w_valid & i_w_mask[0])),
        .addr0(i_w_addr),
        .din0(i_w_data),

        .clk1(read_clk),
        .csb1(~(i_r_valid & i_r_mask[0])),
        .addr1(i_r_addr),
        .dout1(sram0_data)
    );

    wire [WORD_WIDTH-1:0]   sram1_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram1 (
        .clk0(write_clk),
        .csb0(~(i_w_valid & i_w_mask[1])),
        .addr0(i_w_addr),
        .din0(i_w_data),

        .clk1(read_clk),
        .csb1(~(i_r_valid & i_r_mask[1])),
        .addr1(i_r_addr),
        .dout1(sram1_data)
    );

    wire [WORD_WIDTH-1:0]   sram2_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram2 (
        .clk0(write_clk),
        .csb0(~(i_w_valid & i_w_mask[2])),
        .addr0(i_w_addr),
        .din0(i_w_data),

        .clk1(read_clk),
        .csb1(~(i_r_valid & i_r_mask[2])),
        .addr1(i_r_addr),
        .dout1(sram2_data)
    );

    wire [WORD_WIDTH-1:0]   sram3_data;
    sky130_sram_1kbytes_1r1w_256x20_20 sram3 (
        .clk0(write_clk),
        .csb0(~(i_w_valid & i_w_mask[3])),
        .addr0(i_w_addr),
        .din0(i_w_data),

        .clk1(read_clk),
        .csb1(~(i_r_valid & i_r_mask[3])),
        .addr1(i_r_addr),
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

    reg [NUM_BLOCKS-1:0]    r_r_mask;
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_r_mask <= {NUM_BLOCKS{1'b0}};
        end
        else if(~i_halt_all) begin
            r_r_mask <= i_r_mask & {NUM_BLOCKS{~i_stop_read_clk}};
        end
    end

    always @(*) begin
        case(r_r_mask)
        4'b1000 :   begin
            o_word_data = sram3_data;
        end

        4'b0100 :   begin
            o_word_data = sram2_data;
        end
        
        4'b0010 :   begin
            o_word_data = sram1_data;
        end

        4'b0001 :   begin
            o_word_data = sram0_data;
        end

        default : begin
            o_word_data = {WORD_WIDTH{1'b0}};
        end

        endcase
    end
  

endmodule