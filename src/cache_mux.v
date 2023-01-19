`timescale 1ns/1ps

module cache_mux (
    input   wire    [TAG_BITS_WIDTH-1:0]        i_tag_bits,
    input   wire    [BLOCK_OFFSET_BITS-1:0]     i_block_offset_bits,
    
    input   wire    [TAG_ARRAY_WIDTH-1:0]       i_tag_array_tag_data,
    input   wire    [DATA_ARRAY_WIDTH-1:0]      i_data_array_data,
    input   wire    [STATUS_ARRAY_WIDTH-1:0]    i_status_array_data,
    input   wire                                i_valid,

    input   wire                                clk,
    input   wire                                arst_n,
    input   wire                                i_halt,
    
    output  wire    [WORD_DATA_WIDTH-1:0]       o_word_data,
    output  reg                                 o_cache_hit, // 1 means cache hit, 0 means miss
    output  wire                                o_valid,
    output  wire                                o_ready
);
    // to aid understanding
    localparam TAG_BITS_WIDTH = 8;
    localparam BLOCK_OFFSET_BITS = 4; 
    localparam TAG_ARRAY_WIDTH = 32;
    localparam DATA_ARRAY_WIDTH = 1280;
    localparam STATUS_ARRAY_WIDTH = 8;
    localparam WORD_DATA_WIDTH = 20; // 16 instruction data + 4 predecoded bits

    localparam NUM_BLOCKS = 4;
    localparam DATA_BLOCK_WIDTH = 320;

    localparam USE_BIT_IDX      = 0;
    localparam VALID_BIT_IDX    = 1;

    reg    [TAG_BITS_WIDTH-1:0]        r_tag_bits;
    reg    [BLOCK_OFFSET_BITS-1:0]     r_block_offset_bits;
    reg    [TAG_ARRAY_WIDTH:0]         r_tag_array_tag_data;
    reg    [DATA_ARRAY_WIDTH:0]        r_data_array_data;
    reg    [STATUS_ARRAY_WIDTH-1:0]    r_status_array_data;
    reg                                r_valid;

    assign o_ready = ~i_halt;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_tag_bits              <= {TAG_BITS_WIDTH{1'b0}};
            r_block_offset_bits     <= {BLOCK_OFFSET_BITS{1'b0}};
            r_tag_array_tag_data    <= {TAG_ARRAY_WIDTH{1'b0}};
            r_data_array_data       <= {DATA_ARRAY_WIDTH{1'b0}};
            r_status_array_data     <= {STATUS_ARRAY_WIDTH{1'b0}};
            r_valid                 <= 1'b0;
        end
        else if(~i_halt) begin
            r_tag_bits              <= i_tag_bits            & {TAG_BITS_WIDTH{i_valid}};
            r_block_offset_bits     <= i_block_offset_bits   & {BLOCK_OFFSET_BITS{i_valid}};
            r_tag_array_tag_data    <= i_tag_array_tag_data  & {TAG_ARRAY_WIDTH{i_valid}};
            r_data_array_data       <= i_data_array_data     & {DATA_ARRAY_WIDTH{i_valid}};
            r_status_array_data     <= i_status_array_data   & {STATUS_ARRAY_WIDTH{i_valid}};
            r_valid                 <= i_valid;
        end
    end
    
    assign o_valid = r_valid;

    wire [NUM_BLOCKS-1:0] w_tag_hit = {
        r_tag_bits === r_tag_array_tag_data[24 +: TAG_BITS_WIDTH],
        r_tag_bits === r_tag_array_tag_data[16 +: TAG_BITS_WIDTH],
        r_tag_bits === r_tag_array_tag_data[8  +: TAG_BITS_WIDTH],
        r_tag_bits === r_tag_array_tag_data[0  +: TAG_BITS_WIDTH]
    } & {NUM_BLOCKS{r_valid}};

    reg [DATA_BLOCK_WIDTH-1:0] r_block_data;

    always @(*) begin
        case(w_tag_hit)
        4'b1000 : begin
            o_cache_hit = r_status_array_data[6];
            r_block_data = r_status_array_data[6] ?  r_data_array_data[320*4-1:320*3] : 
                                                    {WORD_DATA_WIDTH{1'b0}};
        end

        4'b0100 : begin
            
            o_cache_hit = r_status_array_data[4];
            r_block_data = r_status_array_data[4] ?  r_data_array_data[320*3-1:320*2] : 
                                                    {WORD_DATA_WIDTH{1'b0}};
        end

        4'b0010 : begin
            
            o_cache_hit = r_status_array_data[2];
            r_block_data = r_status_array_data[2] ?  r_data_array_data[320*2-1:320*1] : 
                                                    {WORD_DATA_WIDTH{1'b0}};
        end

        4'b0001 : begin
            
            o_cache_hit = r_status_array_data[0];
            r_block_data = r_status_array_data[0] ?  r_data_array_data[320*1-1:320*0] : // it's intetional
                                                    {WORD_DATA_WIDTH{1'b0}};
        end
        
        default : begin
            o_cache_hit = 1'b0;
            r_block_data = {DATA_BLOCK_WIDTH{1'b0}};
        end

        endcase
    end

    word_mux wm(
        .i_block_data(r_block_data),
        .i_block_offset_bits(r_block_offset_bits),

        .o_word_data(o_word_data)
    );
  

endmodule