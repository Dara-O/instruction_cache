`timescale 1ns/1ps

    localparam TAG_BITS_WIDTH = 8;
    localparam BLOCK_OFFSET_BITS = 4; 
    localparam TAG_ARRAY_WIDTH = 32;
    localparam STATUS_ARRAY_WIDTH = 8;
    localparam SET_BITS_WIDTH = 4;

    localparam NUM_BLOCKS = 4;

program main_program  (
    output	logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits,
    output	logic	 [TAG_ARRAY_WIDTH-1:0]	i_tag_array_tag_data,
    output	logic	 [STATUS_ARRAY_WIDTH-1:0]	i_status_array_data,
    output	logic	 [SET_BITS_WIDTH-1:0]	i_set_bits,
    output	logic	 [BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits,
    output	logic	 		i_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 [NUM_BLOCKS-1:0]	o_hit_blocks,
    input	logic	 		o_cache_hit,
    input	logic	 [TAG_BITS_WIDTH-1:0]	o_tag_bits,
    input	logic	 [SET_BITS_WIDTH-1:0]	o_set_bits,
    input	logic	 [BLOCK_OFFSET_BITS-1:0]	o_block_offset_bits,
    input	logic	 [STATUS_ARRAY_WIDTH-1:0]	o_status_array_data,
    input	logic	 		o_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits_d;
    logic	 [TAG_ARRAY_WIDTH-1:0]	i_tag_array_tag_data_d;
    logic	 [STATUS_ARRAY_WIDTH-1:0]	i_status_array_data_d;
    logic	 [SET_BITS_WIDTH-1:0]	i_set_bits_d;
    logic	 [BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits_d;
    logic	 		i_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [NUM_BLOCKS-1:0]	o_hit_blocks_s;
    logic	 		o_cache_hit_s;
    logic	 [TAG_BITS_WIDTH-1:0]	o_tag_bits_s;
    logic	 [SET_BITS_WIDTH-1:0]	o_set_bits_s;
    logic	 [BLOCK_OFFSET_BITS-1:0]	o_block_offset_bits_s;
    logic	 [STATUS_ARRAY_WIDTH-1:0]	o_status_array_data_s;
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
        for(int target_block = 0; target_block < 4; ++target_block) begin
            i_tag_bits_d <= 8'haa;
            i_tag_array_tag_data_d <= 32'haa << TAG_BITS_WIDTH * target_block;
            i_status_array_data_d <= 8'b11 << 2 * target_block;

            i_set_bits_d <= 4'hb;
            i_block_offset_bits_d <= 4'h1;
            i_valid_d <= 1'b1;

            if(target_block == 1) begin
                i_halt_d = 1'b1;
            end
            else begin
                i_halt_d = 1'b0;
            end

            @(posedge drive_clk);
        end


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
    
        o_hit_blocks_s	<=	o_hit_blocks;
        o_cache_hit_s	<=	o_cache_hit;
        o_tag_bits_s	<=	o_tag_bits;
        o_set_bits_s	<=	o_set_bits;
        o_block_offset_bits_s	<=	o_block_offset_bits;
        o_status_array_data_s	<=	o_status_array_data;
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_tag_bits	<=	i_tag_bits_d;
        i_tag_array_tag_data	<=	i_tag_array_tag_data_d;
        i_status_array_data	<=	i_status_array_data_d;
        i_set_bits	<=	i_set_bits_d;
        i_block_offset_bits	<=	i_block_offset_bits_d;
        i_valid	<=	i_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_tag_bits_d	= 0;
        i_tag_array_tag_data_d	= 0;
        i_status_array_data_d	= 0;
        i_set_bits_d	= 0;
        i_block_offset_bits_d	= 0;
        i_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_tag_bits	= 0;
        i_tag_array_tag_data	= 0;
        i_status_array_data	= 0;
        i_set_bits	= 0;
        i_block_offset_bits	= 0;
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
    logic 	[TAG_ARRAY_WIDTH-1:0]	i_tag_array_tag_data;
    logic 	[STATUS_ARRAY_WIDTH-1:0]	i_status_array_data;
    logic 	[SET_BITS_WIDTH-1:0]	i_set_bits;
    logic 	[BLOCK_OFFSET_BITS-1:0]	i_block_offset_bits;
    logic 			i_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[NUM_BLOCKS-1:0]	o_hit_blocks;
    logic 			o_cache_hit;
    logic 	[TAG_BITS_WIDTH-1:0]	o_tag_bits;
    logic 	[SET_BITS_WIDTH-1:0]	o_set_bits;
    logic 	[BLOCK_OFFSET_BITS-1:0]	o_block_offset_bits;
    logic 	[STATUS_ARRAY_WIDTH-1:0]	o_status_array_data;
    logic 			o_valid;
    logic 			o_ready;



    cache_mux  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

