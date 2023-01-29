`timescale 1ns/1ps

 localparam MEM_DATA_WIDTH = 320;
 localparam MASK_WIDTH = 4;

 localparam SET_ADDR_WIDTH = 4;

 // tag array params 
 localparam TA_ADDR_WIDTH = 4;
 localparam TA_DATA_WIDTH = 32;

 // status array params
 localparam SA_ADDR_WIDTH = 4;
 localparam SA_DATA_WIDTH = 8;
 
 // data array params
 localparam DA_ADDR_WIDTH = 8;
 localparam DA_DATA_WIDTH = 20;

 localparam TAG_BITS_WIDTH = 8;


program main_program  (
    output	logic	 		i_initiate_arrays_update,
    output	logic	 		i_iau_valid,
    output	logic	 [SET_ADDR_WIDTH-1:0]	i_set_addr,
    output	logic	 		i_set_addr_valid,
    output	logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits,
    output	logic	 		i_tag_bits_valid,
    output	logic	 [MASK_WIDTH-1:0]	i_block_replacement_mask,
    output	logic	 		i_brm_valid,
    output	logic	 [MEM_DATA_WIDTH-1:0]	i_mem_data,
    output	logic	 		i_mem_data_valid,
    output  logic           i_miss_state,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    output	logic	 		i_ta_blocks_halt,
    output	logic	 		i_sa_blocks_halt,
    output	logic	 		i_da_blocks_halt,
    input	logic	 [TA_ADDR_WIDTH-1:0]	o_ta_addr,
    input	logic	 [TA_DATA_WIDTH-1:0]	o_ta_data,
    input	logic	 [MASK_WIDTH-1:0]	o_ta_mask,
    input	logic	 		o_ta_valid,
    input	logic	 [SA_ADDR_WIDTH-1:0]	o_sa_addr,
    input	logic	 [SA_DATA_WIDTH-1:0]	o_sa_data,
    input	logic	 [MASK_WIDTH-1:0]	o_sa_mask,
    input	logic	 		o_sa_valid,
    input	logic	 [DA_ADDR_WIDTH-1:0]	o_da_addr,
    input	logic	 [DA_DATA_WIDTH-1:0]	o_da_data,
    input	logic	 [MASK_WIDTH-1:0]	o_da_mask,
    input	logic	 		o_da_valid,
    input	logic	 		o_arrays_updated_complete,
    input	logic	 		o_auc_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 		i_initiate_arrays_update_d;
    logic	 		i_iau_valid_d;
    logic	 [SET_ADDR_WIDTH-1:0]	i_set_addr_d;
    logic	 		i_set_addr_valid_d;
    logic	 [TAG_BITS_WIDTH-1:0]	i_tag_bits_d;
    logic	 		i_tag_bits_valid_d;
    logic	 [MASK_WIDTH-1:0]	i_block_replacement_mask_d;
    logic	 		i_brm_valid_d;
    logic	 [MEM_DATA_WIDTH-1:0]	i_mem_data_d;
    logic	 		i_mem_data_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;
    logic	 		i_ta_blocks_halt_d;
    logic	 		i_sa_blocks_halt_d;
    logic	 		i_da_blocks_halt_d;
    logic	 		i_miss_state_d;

    
    // sampled
    logic	 [TA_ADDR_WIDTH-1:0]	o_ta_addr_s;
    logic	 [TA_DATA_WIDTH-1:0]	o_ta_data_s;
    logic	 [MASK_WIDTH-1:0]	o_ta_mask_s;
    logic	 		o_ta_valid_s;
    logic	 [SA_ADDR_WIDTH-1:0]	o_sa_addr_s;
    logic	 [SA_DATA_WIDTH-1:0]	o_sa_data_s;
    logic	 [MASK_WIDTH-1:0]	o_sa_mask_s;
    logic	 		o_sa_valid_s;
    logic	 [DA_ADDR_WIDTH-1:0]	o_da_addr_s;
    logic	 [DA_DATA_WIDTH-1:0]	o_da_data_s;
    logic	 [MASK_WIDTH-1:0]	o_da_mask_s;
    logic	 		o_da_valid_s;
    logic	 		o_arrays_updated_complete_s;
    logic	 		o_auc_valid_s;
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
        
        // ROUND 1
        i_miss_state_d = 1'b1;

        repeat(2) @(posedge drive_clk);
        
        i_mem_data_d = {10{32'haaaa_aaaa}};
        i_mem_data_valid_d = 1'b1;

        
        i_set_addr_d = 4'b0001;
        i_set_addr_valid_d = 1'b1;
        
        i_tag_bits_d = 8'h55 ;
        i_tag_bits_valid_d = 1'b1;
        
        i_block_replacement_mask_d = 4'b0100;
        i_brm_valid_d = 1'b1;

        @(posedge drive_clk);
        i_initiate_arrays_update_d = 1'b1;
        i_iau_valid_d = 1'b1;
        @(posedge drive_clk);
        i_initiate_arrays_update_d = 1'b0;
        i_iau_valid_d = 1'b0;

        @(posedge drive_clk);
        @(posedge sample_clk);
        wait(o_ready_s === 1'b1);

        i_miss_state_d = 1'b0;
        @(posedge drive_clk);
        i_miss_state_d = 1'b1;

        // ROUND 2
        repeat(2) @(posedge drive_clk);
        
        i_mem_data_d = {8{40'h00000_fffff}};
        i_mem_data_valid_d = 1'b1;

        
        i_set_addr_d = 4'b0101;
        i_set_addr_valid_d = 1'b1;
        
        i_tag_bits_d = 8'haa ;
        i_tag_bits_valid_d = 1'b1;
        
        i_block_replacement_mask_d = 4'b0001;
        i_brm_valid_d = 1'b1;

        @(posedge drive_clk);
        i_initiate_arrays_update_d = 1'b1;
        i_iau_valid_d = 1'b1;
        @(posedge drive_clk);
        i_initiate_arrays_update_d = 1'b0;
        i_iau_valid_d = 1'b0;
        @(posedge drive_clk);

        @(posedge sample_clk);
        wait(o_ready_s === 1'b1);

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
    
        o_ta_addr_s	<=	o_ta_addr;
        o_ta_data_s	<=	o_ta_data;
        o_ta_mask_s	<=	o_ta_mask;
        o_ta_valid_s	<=	o_ta_valid;
        o_sa_addr_s	<=	o_sa_addr;
        o_sa_data_s	<=	o_sa_data;
        o_sa_mask_s	<=	o_sa_mask;
        o_sa_valid_s	<=	o_sa_valid;
        o_da_addr_s	<=	o_da_addr;
        o_da_data_s	<=	o_da_data;
        o_da_mask_s	<=	o_da_mask;
        o_da_valid_s	<=	o_da_valid;
        o_arrays_updated_complete_s	<=	o_arrays_updated_complete;
        o_auc_valid_s	<=	o_auc_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_initiate_arrays_update	<=	i_initiate_arrays_update_d;
        i_iau_valid	<=	i_iau_valid_d;
        i_set_addr	<=	i_set_addr_d;
        i_set_addr_valid	<=	i_set_addr_valid_d;
        i_tag_bits	<=	i_tag_bits_d;
        i_tag_bits_valid	<=	i_tag_bits_valid_d;
        i_block_replacement_mask	<=	i_block_replacement_mask_d;
        i_brm_valid	<=	i_brm_valid_d;
        i_mem_data	<=	i_mem_data_d;
        i_mem_data_valid	<=	i_mem_data_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;
        i_ta_blocks_halt	<=	i_ta_blocks_halt_d;
        i_sa_blocks_halt	<=	i_sa_blocks_halt_d;
        i_da_blocks_halt	<=	i_da_blocks_halt_d;
        i_miss_state        <= i_miss_state_d;

    endtask

    task init();

        i_initiate_arrays_update_d	= 0;
        i_iau_valid_d	= 0;
        i_set_addr_d	= 0;
        i_set_addr_valid_d	= 0;
        i_tag_bits_d	= 0;
        i_tag_bits_valid_d	= 0;
        i_block_replacement_mask_d	= 0;
        i_brm_valid_d	= 0;
        i_mem_data_d	= 0;
        i_mem_data_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;
        i_ta_blocks_halt_d	= 0;
        i_sa_blocks_halt_d	= 0;
        i_da_blocks_halt_d	= 0;
        i_miss_state_d      = 0;

        i_initiate_arrays_update	= 0;
        i_iau_valid	= 0;
        i_set_addr	= 0;
        i_set_addr_valid	= 0;
        i_tag_bits	= 0;
        i_tag_bits_valid	= 0;
        i_block_replacement_mask	= 0;
        i_brm_valid	= 0;
        i_mem_data	= 0;
        i_mem_data_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;
        i_ta_blocks_halt	= 0;
        i_sa_blocks_halt	= 0;
        i_da_blocks_halt	= 0;
        i_miss_state        = 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    
    logic           i_miss_state;
    logic 			i_initiate_arrays_update;
    logic 			i_iau_valid;
    logic 	[SET_ADDR_WIDTH-1:0]	i_set_addr;
    logic 			i_set_addr_valid;
    logic 	[TAG_BITS_WIDTH-1:0]	i_tag_bits;
    logic 			i_tag_bits_valid;
    logic 	[MASK_WIDTH-1:0]	i_block_replacement_mask;
    logic 			i_brm_valid;
    logic 	[MEM_DATA_WIDTH-1:0]	i_mem_data;
    logic 			i_mem_data_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 			i_ta_blocks_halt;
    logic 			i_sa_blocks_halt;
    logic 			i_da_blocks_halt;
    logic 	[TA_ADDR_WIDTH-1:0]	o_ta_addr;
    logic 	[TA_DATA_WIDTH-1:0]	o_ta_data;
    logic 	[MASK_WIDTH-1:0]	o_ta_mask;
    logic 			o_ta_valid;
    logic 	[SA_ADDR_WIDTH-1:0]	o_sa_addr;
    logic 	[SA_DATA_WIDTH-1:0]	o_sa_data;
    logic 	[MASK_WIDTH-1:0]	o_sa_mask;
    logic 			o_sa_valid;
    logic 	[DA_ADDR_WIDTH-1:0]	o_da_addr;
    logic 	[DA_DATA_WIDTH-1:0]	o_da_data;
    logic 	[MASK_WIDTH-1:0]	o_da_mask;
    logic 			o_da_valid;
    logic 			o_arrays_updated_complete;
    logic 			o_auc_valid;
    logic 			o_ready;



    arrays_updater  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

