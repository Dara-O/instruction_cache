`timescale 1ns/1ps

module lru_unit(
    input   wire    [SA_DATA_WIDTH-1:0]     i_sa_data,
    input   wire                            i_sa_data_valid,

    output  reg     [NUM_BLOCKS-1:0]        o_block_replacement_mask,
    output  wire                            o_brm_valid // brm == block replacement mask
);

    localparam SA_DATA_WIDTH = 8; // 4 blocks with 2 bits each
    localparam NUM_BLOCKS = 4;

    // for use in understanding status_array_data
    localparam USE_BIT_IDX      = 0; 
    localparam VALID_BIT_IDX    = 1;

    wire [NUM_BLOCKS-1:0] w_blk_stat = {
        &i_sa_data[7:6],
        &i_sa_data[5:4],
        &i_sa_data[3:2],
        &i_sa_data[1:0]
    } & {NUM_BLOCKS{i_sa_data_valid}};

    assign o_brm_valid = i_sa_data_valid;

    always @(*) begin
        casez(w_blk_stat) 
        4'b00??, 4'b1111 : begin
            o_block_replacement_mask = 4'b1000;
        end
        4'b0111, 4'b1011, 4'b1101, 4'b1110 : begin
            o_block_replacement_mask = ~w_blk_stat;
        end
        4'b100?, 4'b1010 : begin
            o_block_replacement_mask = 4'b0100;
        end
        4'b1100, 4'b0110 : begin
            o_block_replacement_mask = 4'b0001;
        end
        4'b010? : begin
            o_block_replacement_mask = 4'b1000;
        end
        default : begin
            o_block_replacement_mask = 4'b0000;
        end
        endcase
    end

endmodule