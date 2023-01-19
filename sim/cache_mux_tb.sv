`timescale 1ns/1ps

localparam TAG_BITS_WIDTH = 8;
localparam BLOCK_OFFSET_BITS = 4; 
localparam TAG_ARRAY_WIDTH = 32;
localparam DATA_ARRAY_WIDTH = 1280;
localparam STATUS_ARRAY_WIDTH = 8;
localparam WORD_DATA_WIDTH = 20; 

program main_program  (
    output	logic	 [TAG_BITS_WIDTH-1:0]	    i_tag_bits,
    output	logic	 [BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits,
    output	logic	 [TAG_ARRAY_WIDTH-1:0]	    i_tag_array_tag_data,
    output	logic	 [DATA_ARRAY_WIDTH-1:0]	    i_data_array_data,
    output	logic	 [STATUS_ARRAY_WIDTH-1:0]	i_status_array_data,
    output	logic	 		                    i_valid,
    output	logic	 		                    clk,
    output	logic	 		                    arst_n,
    output	logic	 		                    i_halt,

    input	logic	 [WORD_DATA_WIDTH-1:0]	    o_word_data,
    input	logic	 		                    o_cache_hit,
    input	logic	 		                    o_valid,
    input	logic	 		                    o_ready
);

    // driven
    logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits_d;
    logic	 [BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits_d;
    logic	 [TAG_ARRAY_WIDTH-1:0]	i_tag_array_tag_data_d;
    logic	 [DATA_ARRAY_WIDTH-1:0]	i_data_array_data_d;
    logic	 [STATUS_ARRAY_WIDTH-1:0]	i_status_array_data_d;
    logic	 		i_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [WORD_DATA_WIDTH-1:0]	o_word_data_s;
    logic	 		o_cache_hit_s;
    logic	 		o_valid_s;
    logic	 		o_ready_s;


    localparam CLK_PERIOD = 50;
    localparam SAMPLE_SKEW = 5;
    localparam DRIVE_SKEW = 5;
    localparam MAX_CYCLES = 100;

    logic drive_clk;
    logic sample_clk;
    logic dut_clk;
    logic simulation_complete;

    assign clk = dut_clk;

    initial begin
        simulation_complete = 0;
        init();
    
        fork
            clock_gen();
            test_sequence();
            watch_dog();
        join_any
        disable fork;
    
        simulation_complete = 1;
        $finish;
    end

    task test_sequence();
        reset();
        
        for(int block_idx = 0; block_idx < 4; ++block_idx) begin
            for(int block_offset = 0; block_offset < 16; ++block_offset) begin
                
                i_tag_bits_d            = 8'haa;
                i_block_offset_bits_d   = block_offset;
                
                i_tag_array_tag_data_d  = 32'haa  << TAG_BITS_WIDTH*block_idx;
                i_data_array_data_d     = 1280'hfdeed+block_idx+block_offset << 320*block_idx + 20*i_block_offset_bits_d;
                i_status_array_data_d   = 8'h11 << 2*block_idx;
                i_valid_d               = 1'b1;
                
                @(posedge drive_clk);
            end
        end

        i_tag_bits_d            = 8'h0;
        i_block_offset_bits_d   = 4'h0;
        
        i_tag_array_tag_data_d  = 32'h0;
        i_data_array_data_d     = 1280'h0;
        i_status_array_data_d   = 8'h0;
        i_valid_d               = 1'b0;


        repeat(10) @(posedge drive_clk);
    endtask

    task reset();
        arst_n_d = 0;
        @(posedge drive_clk);

        arst_n_d = 1;
        repeat(2) @(posedge drive_clk);
    endtask

    task clock_gen(); 
        forever begin
            dut_clk <= 0;
            sample_clk <= 0;
            drive_clk <= 0;
            
            #(CLK_PERIOD/2 - SAMPLE_SKEW);
            sample_clk <= 1;
            sample();
            #(SAMPLE_SKEW);
            
            dut_clk <= 1;
            
            #(DRIVE_SKEW);
            drive_clk <= 1;
            drive();
            #(CLK_PERIOD/2 - DRIVE_SKEW);
        end
    endtask 

    task sample();
    
        o_word_data_s	<=	o_word_data;
        o_cache_hit_s	<=	o_cache_hit;
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_tag_bits	<=	i_tag_bits_d;
        i_block_offset_bits	<=	i_block_offset_bits_d;
        i_tag_array_tag_data	<=	i_tag_array_tag_data_d;
        i_data_array_data	<=	i_data_array_data_d;
        i_status_array_data	<=	i_status_array_data_d;
        i_valid	<=	i_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_tag_bits_d	= 0;
        i_block_offset_bits_d	= 0;
        i_tag_array_tag_data_d	= 0;
        i_data_array_data_d	= 0;
        i_status_array_data_d	= 0;
        i_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_tag_bits	= 0;
        i_block_offset_bits	= 0;
        i_tag_array_tag_data	= 0;
        i_data_array_data	= 0;
        i_status_array_data	= 0;
        i_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 	[TAG_BITS_WIDTH-1:0]	i_tag_bits;
    logic 	[BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits;
    logic 	[TAG_ARRAY_WIDTH-1:0]	i_tag_array_tag_data;
    logic 	[DATA_ARRAY_WIDTH-1:0]	i_data_array_data;
    logic 	[STATUS_ARRAY_WIDTH-1:0]	i_status_array_data;
    logic 			i_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[WORD_DATA_WIDTH-1:0]	o_word_data;
    logic 			o_cache_hit;
    logic 			o_valid;
    logic 			o_ready;



    cache_mux  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

