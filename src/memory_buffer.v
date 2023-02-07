`timescale 1ns/1ps

module memory_buffer(
    input   wire    [EXT_MEM_DATA_WIDTH-1:0]    i_mem_data,
    input   wire                                i_mem_data_valid,

    input   wire                                clk,
    input   wire                                arst_n, 
    input   wire                                i_halt,

    output  wire    [INT_MEM_DATA_WIDTH-1:0]    o_mem_data,
    output  wire                                o_mem_data_valid,
    output  wire                                o_ready
);

    localparam EXT_MEM_DATA_WIDTH = 40;
    localparam INT_MEM_DATA_WIDTH = 80;

    assign o_ready = ~i_halt;
  
    reg r_mem_data_valid_pos;
    reg r_mem_data_valid_neg;

    assign o_mem_data_valid = r_mem_data_valid_pos & r_mem_data_valid_neg; // full packet received

    reg [EXT_MEM_DATA_WIDTH-1:0] r_mem_data_pos;
    reg [EXT_MEM_DATA_WIDTH-1:0] r_mem_data_neg;

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_mem_data_pos <= {EXT_MEM_DATA_WIDTH{1'b0}};
            r_mem_data_valid_pos <= 1'b0;
        end
        else if(~i_halt) begin
            r_mem_data_pos <= i_mem_data;
            r_mem_data_valid_pos <= i_mem_data_valid;
        end
    end

    always @(negedge clk, negedge arst_n) begin
        if(~arst_n) begin
            r_mem_data_neg <= {EXT_MEM_DATA_WIDTH{1'b0}};
            r_mem_data_valid_neg <= 1'b0;
        end
        else if(~i_halt) begin
            r_mem_data_neg <= i_mem_data;
            r_mem_data_valid_neg <= i_mem_data_valid;
        end
    end

    assign o_mem_data = {r_mem_data_pos, r_mem_data_neg};

endmodule