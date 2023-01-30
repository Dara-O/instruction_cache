`timescale 1ns/1ps

    localparam SET_BITS_WIDTH  = 4;    
    localparam B_OFFSET_BITS_WIDTH = 4;
    
    localparam READ_WORD_WIDTH  = 20;
    localparam WRITE_WORD_WIDTH = 20*4;// 4 == number of srams
    localparam NUM_WAYS         = 4;

program main_program  (
    output	logic	 [SET_BITS_WIDTH-1:0]	i_r_set_bits,
    output	logic	 [$clog2(NUM_WAYS)-1:0]	i_r_way_index,
    output	logic	 [B_OFFSET_BITS_WIDTH-1:0]	i_r_block_offset_bits,
    output	logic	 		i_r_valid,
    output	logic	 [SET_BITS_WIDTH-1:0]	i_w_set_bits,
    output	logic	 [$clog2(NUM_WAYS)-1:0]	i_w_way_index,
    output	logic	 [B_OFFSET_BITS_WIDTH-3:0]	i_w_block_offset_bits,
    output	logic	 [WRITE_WORD_WIDTH-1:0]	i_w_data,
    output	logic	 		i_w_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt_all,
    output	logic	 		i_stop_read_clk,
    output	logic	 		i_stop_write_clk,
    input	logic	 [READ_WORD_WIDTH-1:0]	o_word_data,
    input	logic	 		o_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 [SET_BITS_WIDTH-1:0]	i_r_set_bits_d;
    logic	 [$clog2(NUM_WAYS)-1:0]	i_r_way_index_d;
    logic	 [B_OFFSET_BITS_WIDTH-1:0]	i_r_block_offset_bits_d;
    logic	 		i_r_valid_d;
    logic	 [SET_BITS_WIDTH-1:0]	i_w_set_bits_d;
    logic	 [$clog2(NUM_WAYS)-1:0]	i_w_way_index_d;
    logic	 [B_OFFSET_BITS_WIDTH-3:0]	i_w_block_offset_bits_d;
    logic	 [WRITE_WORD_WIDTH-1:0]	i_w_data_d;
    logic	 		i_w_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_all_d;
    logic	 		i_stop_read_clk_d;
    logic	 		i_stop_write_clk_d;

    
    // sampled
    logic	 [READ_WORD_WIDTH-1:0]	o_word_data_s;
    logic	 		o_valid_s;
    logic	 		o_ready_s;


    localparam CLK_PERIOD = 50;
    localparam SAMPLE_SKEW = 5;
    localparam DRIVE_SKEW = 5;
    localparam MAX_CYCLES = 10000;

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
        logic [79:0] data;
        reset();
        
        data = {2{40'haaaaa_55555}};

        for(int i=0; i<256; ++i) begin
            i_w_set_bits_d          = i[7:4];
            i_w_way_index_d         = i[3:2];
            i_w_block_offset_bits_d = i[1:0];
            i_w_data_d              = data;
            i_w_valid_d             = 1'b1;
            @(posedge drive_clk);
        end

        i_w_set_bits_d          = 0;
        i_w_way_index_d         = 0;
        i_w_block_offset_bits_d = 0;
        i_w_data_d              = 0;
        i_w_valid_d             = 1'b0;
        repeat(2) @(posedge drive_clk);

        for(int i=0; i<1024; ++i) begin
            i_r_set_bits_d          = i[9:6];
            i_r_way_index_d         = i[5:4];
            i_r_block_offset_bits_d = i[3:0];
            i_r_valid_d             = 1'b1;
            @(posedge drive_clk);
        end 

        i_r_set_bits_d          = 0;
        i_r_way_index_d         = 0;
        i_r_block_offset_bits_d = 0;
        i_r_valid_d             = 1'b0;
        @(posedge drive_clk);

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
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_r_set_bits	<=	i_r_set_bits_d;
        i_r_way_index	<=	i_r_way_index_d;
        i_r_block_offset_bits	<=	i_r_block_offset_bits_d;
        i_r_valid	<=	i_r_valid_d;
        i_w_set_bits	<=	i_w_set_bits_d;
        i_w_way_index	<=	i_w_way_index_d;
        i_w_block_offset_bits	<=	i_w_block_offset_bits_d;
        i_w_data	<=	i_w_data_d;
        i_w_valid	<=	i_w_valid_d;
        arst_n	<=	arst_n_d;
        i_halt_all	<=	i_halt_all_d;
        i_stop_read_clk	<=	i_stop_read_clk_d;
        i_stop_write_clk	<=	i_stop_write_clk_d;

    endtask

    task init();

        i_r_set_bits_d	= 0;
        i_r_way_index_d	= 0;
        i_r_block_offset_bits_d	= 0;
        i_r_valid_d	= 0;
        i_w_set_bits_d	= 0;
        i_w_way_index_d	= 0;
        i_w_block_offset_bits_d	= 0;
        i_w_data_d	= 0;
        i_w_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_all_d	= 0;
        i_stop_read_clk_d	= 0;
        i_stop_write_clk_d	= 0;

        i_r_set_bits	= 0;
        i_r_way_index	= 0;
        i_r_block_offset_bits	= 0;
        i_r_valid	= 0;
        i_w_set_bits	= 0;
        i_w_way_index	= 0;
        i_w_block_offset_bits	= 0;
        i_w_data	= 0;
        i_w_valid	= 0;
        arst_n	= 0;
        i_halt_all	= 0;
        i_stop_read_clk	= 0;
        i_stop_write_clk	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 	[SET_BITS_WIDTH-1:0]	i_r_set_bits;
    logic 	[$clog2(NUM_WAYS)-1:0]	i_r_way_index;
    logic 	[B_OFFSET_BITS_WIDTH-1:0]	i_r_block_offset_bits;
    logic 			i_r_valid;
    logic 	[SET_BITS_WIDTH-1:0]	i_w_set_bits;
    logic 	[$clog2(NUM_WAYS)-1:0]	i_w_way_index;
    logic 	[B_OFFSET_BITS_WIDTH-3:0]	i_w_block_offset_bits;
    logic 	[WRITE_WORD_WIDTH-1:0]	i_w_data;
    logic 			i_w_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt_all;
    logic 			i_stop_read_clk;
    logic 			i_stop_write_clk;
    logic 	[READ_WORD_WIDTH-1:0]	o_word_data;
    logic 			o_valid;
    logic 			o_ready;



    data_arrays_container  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

