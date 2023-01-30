`timescale 1ns/1ps

    localparam SET_BITS_WIDTH = 4;
    localparam B_OFFSET_BITS_WIDTH = 4; //block offset bits width
    localparam TAG_BITS_WIDTH = 8;

    localparam SA_WORD_WIDTH = 4*2; // sa = Status array
    localparam SA_SRAM_ADDR_WIDTH = 4;

    localparam TA_SRAM_WORD_WIDTH = 4*8;
    localparam TA_SRAM_ADDR_WIDTH = 4;

    localparam DA_SRAM_WORD_WIDTH = 20; // DA = Data Array 
    localparam DA_SRAM_ADDR_WIDTH = 8;

    localparam MEM_IF_ADDR = 16;
    localparam MEM_IF_DATA = 32;
    localparam NUM_BLOCKS = 4;

    localparam MEM_BLOCK_DATA_WIDTH = 320;

program main_program  (
    output	logic	 		i_cache_hit,
    output	logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits,
    output	logic	 [SET_BITS_WIDTH-1:0]	i_set_bits,
    output	logic	 [B_OFFSET_BITS_WIDTH-1:0]	i_block_offset_bits,
    output	logic	 [SA_WORD_WIDTH-1:0]	i_status_array_data,
    output	logic	 		i_valid,
    output	logic	 [MEM_IF_DATA-1:0]	i_mem_if_data,
    output	logic	 		i_mem_if_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    output	logic	 		i_mem_if_halt,
    output	logic	 		i_sa_blocks_halt,
    output	logic	 		i_ta_blocks_halt,
    output	logic	 		i_da_blocks_halt,
    input	logic	 [DA_SRAM_ADDR_WIDTH-1:0]	o_da_write_addr,
    input	logic	 [DA_SRAM_WORD_WIDTH-1:0]	o_da_write_data,
    input	logic	 [NUM_BLOCKS-1:0]	o_da_blocks_mask,
    input	logic	 		o_da_blocks_if_valid,
    input	logic	 [TA_SRAM_ADDR_WIDTH-1:0]	o_ta_write_addr,
    input	logic	 [TA_SRAM_WORD_WIDTH-1:0]	o_ta_write_data,
    input	logic	 [NUM_BLOCKS-1:0]	o_ta_blocks_mask,
    input	logic	 		o_ta_blocks_if_valid,
    input	logic	 [SA_SRAM_ADDR_WIDTH-1:0]	o_sa_write_addr,
    input	logic	 [SA_WORD_WIDTH-1:0]	o_sa_write_data,
    input	logic	 [NUM_BLOCKS-1:0]	o_sa_blocks_mask,
    input	logic	 		o_sa_blocks_if_valid,
    input	logic	 [MEM_IF_ADDR-1:0]	o_mem_if_addr,
    input	logic	 		o_mem_if_req_valid,
    input	logic	 		o_mem_if_ready,
    input	logic	 		o_miss_state,
    input	logic	 [DA_SRAM_WORD_WIDTH-1:0]	o_missed_word,
    input	logic	 		o_missed_word_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 		i_cache_hit_d;
    logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits_d;
    logic	 [SET_BITS_WIDTH-1:0]	i_set_bits_d;
    logic	 [B_OFFSET_BITS_WIDTH-1:0]	i_block_offset_bits_d;
    logic	 [SA_WORD_WIDTH-1:0]	i_status_array_data_d;
    logic	 		i_valid_d;
    logic	 [MEM_IF_DATA-1:0]	i_mem_if_data_d;
    logic	 		i_mem_if_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;
    logic	 		i_mem_if_halt_d;
    logic	 		i_sa_blocks_halt_d;
    logic	 		i_ta_blocks_halt_d;
    logic	 		i_da_blocks_halt_d;

    
    // sampled
    logic	 [DA_SRAM_ADDR_WIDTH-1:0]	o_da_write_addr_s;
    logic	 [DA_SRAM_WORD_WIDTH-1:0]	o_da_write_data_s;
    logic	 [NUM_BLOCKS-1:0]	o_da_blocks_mask_s;
    logic	 		o_da_blocks_if_valid_s;
    logic	 [TA_SRAM_ADDR_WIDTH-1:0]	o_ta_write_addr_s;
    logic	 [TA_SRAM_WORD_WIDTH-1:0]	o_ta_write_data_s;
    logic	 [NUM_BLOCKS-1:0]	o_ta_blocks_mask_s;
    logic	 		o_ta_blocks_if_valid_s;
    logic	 [SA_SRAM_ADDR_WIDTH-1:0]	o_sa_write_addr_s;
    logic	 [SA_WORD_WIDTH-1:0]	o_sa_write_data_s;
    logic	 [NUM_BLOCKS-1:0]	o_sa_blocks_mask_s;
    logic	 		o_sa_blocks_if_valid_s;
    logic	 [MEM_IF_ADDR-1:0]	o_mem_if_addr_s;
    logic	 		o_mem_if_req_valid_s;
    logic	 		o_mem_if_ready_s;
    logic	 		o_miss_state_s;
    logic	 [DA_SRAM_WORD_WIDTH-1:0]	o_missed_word_s;
    logic	 		o_missed_word_valid_s;
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
        
        i_cache_hit_d <= 1'b0;
        i_tag_bits_d <= 8'haa;
        i_set_bits_d <= 4'h4;
        i_block_offset_bits_d <= 4'b0;

        i_status_array_data_d <= 8'h0;
        i_valid_d <= 1'b1;

        @(posedge drive_clk);
        i_cache_hit_d <= 1'b1;
        @(posedge sample_clk);
        wait(o_mem_if_ready === 'b1);
        send_mem_data({10{32'haaaa_5555}});

        repeat(30) @(posedge drive_clk);
    endtask

    task send_mem_data(
        input logic [319:0] i_data
    );
        for(int i=0; i<10; ++i) begin
            i_mem_if_data_d <= i_data[i*32+:32];
            i_mem_if_valid_d <= 1'b1;
            @(posedge drive_clk);
        end
        
        i_mem_if_data_d <= 0;
        i_mem_if_valid_d <= 1'b0;
        @(posedge drive_clk);

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
    
        o_da_write_addr_s	<=	o_da_write_addr;
        o_da_write_data_s	<=	o_da_write_data;
        o_da_blocks_mask_s	<=	o_da_blocks_mask;
        o_da_blocks_if_valid_s	<=	o_da_blocks_if_valid;
        o_ta_write_addr_s	<=	o_ta_write_addr;
        o_ta_write_data_s	<=	o_ta_write_data;
        o_ta_blocks_mask_s	<=	o_ta_blocks_mask;
        o_ta_blocks_if_valid_s	<=	o_ta_blocks_if_valid;
        o_sa_write_addr_s	<=	o_sa_write_addr;
        o_sa_write_data_s	<=	o_sa_write_data;
        o_sa_blocks_mask_s	<=	o_sa_blocks_mask;
        o_sa_blocks_if_valid_s	<=	o_sa_blocks_if_valid;
        o_mem_if_addr_s	<=	o_mem_if_addr;
        o_mem_if_req_valid_s	<=	o_mem_if_req_valid;
        o_mem_if_ready_s	<=	o_mem_if_ready;
        o_miss_state_s	<=	o_miss_state;
        o_missed_word_s	<=	o_missed_word;
        o_missed_word_valid_s	<=	o_missed_word_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_cache_hit	<=	i_cache_hit_d;
        i_tag_bits	<=	i_tag_bits_d;
        i_set_bits	<=	i_set_bits_d;
        i_block_offset_bits	<=	i_block_offset_bits_d;
        i_status_array_data	<=	i_status_array_data_d;
        i_valid	<=	i_valid_d;
        i_mem_if_data	<=	i_mem_if_data_d;
        i_mem_if_valid	<=	i_mem_if_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;
        i_mem_if_halt	<=	i_mem_if_halt_d;
        i_sa_blocks_halt	<=	i_sa_blocks_halt_d;
        i_ta_blocks_halt	<=	i_ta_blocks_halt_d;
        i_da_blocks_halt	<=	i_da_blocks_halt_d;

    endtask

    task init();

        i_cache_hit_d	= 0;
        i_tag_bits_d	= 0;
        i_set_bits_d	= 0;
        i_block_offset_bits_d	= 0;
        i_status_array_data_d	= 0;
        i_valid_d	= 0;
        i_mem_if_data_d	= 0;
        i_mem_if_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;
        i_mem_if_halt_d	= 0;
        i_sa_blocks_halt_d	= 0;
        i_ta_blocks_halt_d	= 0;
        i_da_blocks_halt_d	= 0;

        i_cache_hit	= 0;
        i_tag_bits	= 0;
        i_set_bits	= 0;
        i_block_offset_bits	= 0;
        i_status_array_data	= 0;
        i_valid	= 0;
        i_mem_if_data	= 0;
        i_mem_if_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;
        i_mem_if_halt	= 0;
        i_sa_blocks_halt	= 0;
        i_ta_blocks_halt	= 0;
        i_da_blocks_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 			i_cache_hit;
    logic 	[TAG_BITS_WIDTH-1:0]	i_tag_bits;
    logic 	[SET_BITS_WIDTH-1:0]	i_set_bits;
    logic 	[B_OFFSET_BITS_WIDTH-1:0]	i_block_offset_bits;
    logic 	[SA_WORD_WIDTH-1:0]	i_status_array_data;
    logic 			i_valid;
    logic 	[MEM_IF_DATA-1:0]	i_mem_if_data;
    logic 			i_mem_if_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 			i_mem_if_halt;
    logic 			i_sa_blocks_halt;
    logic 			i_ta_blocks_halt;
    logic 			i_da_blocks_halt;
    logic 	[DA_SRAM_ADDR_WIDTH-1:0]	o_da_write_addr;
    logic 	[DA_SRAM_WORD_WIDTH-1:0]	o_da_write_data;
    logic 	[NUM_BLOCKS-1:0]	o_da_blocks_mask;
    logic 			o_da_blocks_if_valid;
    logic 	[TA_SRAM_ADDR_WIDTH-1:0]	o_ta_write_addr;
    logic 	[TA_SRAM_WORD_WIDTH-1:0]	o_ta_write_data;
    logic 	[NUM_BLOCKS-1:0]	o_ta_blocks_mask;
    logic 			o_ta_blocks_if_valid;
    logic 	[SA_SRAM_ADDR_WIDTH-1:0]	o_sa_write_addr;
    logic 	[SA_WORD_WIDTH-1:0]	o_sa_write_data;
    logic 	[NUM_BLOCKS-1:0]	o_sa_blocks_mask;
    logic 			o_sa_blocks_if_valid;
    logic 	[MEM_IF_ADDR-1:0]	o_mem_if_addr;
    logic 			o_mem_if_req_valid;
    logic 			o_mem_if_ready;
    logic 			o_miss_state;
    logic 	[DA_SRAM_WORD_WIDTH-1:0]	o_missed_word;
    logic 			o_missed_word_valid;
    logic 			o_ready;



    cache_miss_handler  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

