`timescale 1ns/1ps

module status_register_file #(parameter WORD_WIDTH=12, ADDR_WIDTH=3, TAG_WIDTH=1) (
    input   wire    [TAG_WIDTH-1:0]         i_tag,
    input   wire    [ADDR_WIDTH-1:0]        i_addr,
    input   wire    [WORD_WIDTH-1:0]        i_data,
    input   wire                            i_wen, // 1 means write, 0 means read
    input   wire                            i_valid,

    input   wire                            clk,
    input   wire                            arst_n,
    input   wire                            i_halt, 

    output  reg     [TAG_WIDTH-1:0]         o_tag,
    output  reg     [WORD_WIDTH-1:0]        o_data,
    output  reg                             o_data_init, // 1 if the data is from an initialized word, else 0
    output  reg                             o_valid,
    output  wire                            o_freeze_inputs
);
    
    assign o_freeze_inputs = i_halt;
    
    reg [WORD_WIDTH-1:0] reg_file [0:(2**ADDR_WIDTH)-1];
    reg [(2**ADDR_WIDTH)-1:0] r_reg_file_word_init; 

    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            
            r_reg_file_word_init <= {2**ADDR_WIDTH{1'h0}};

            o_data      <= {WORD_WIDTH{1'h0}};
            o_data_init <= 1'h0;
            o_valid     <= 1'h0;
        end
        else if(~i_halt) begin
            if(i_valid) begin                
                if(i_wen) begin
                    reg_file[i_addr] <= i_data;
                    r_reg_file_word_init[i_addr] <= i_valid;

                    // set output zero
                    o_data      <= {WORD_WIDTH{1'h0}};
                    o_data_init <= 1'h0;
                    o_valid     <= 1'h0;
                end
                else begin
                    o_data      <= reg_file[i_addr];
                    o_data_init <= r_reg_file_word_init[i_addr];
                    o_valid     <= i_valid;
                end
            end
            else begin
                o_data      <= {WORD_WIDTH{1'h0}};
                o_data_init <= 1'h0;
                o_valid     <= 1'h0;
            end
        end
    end

    // tag propagation
    always @(posedge clk, negedge arst_n) begin
        if(~arst_n) begin
            o_tag <= {TAG_WIDTH{1'h0}};
        end
        else if(~i_halt) begin
            o_tag <= i_tag & {TAG_WIDTH{i_valid}};
        end
    end


endmodule