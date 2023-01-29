`timescale 1ns/1ps

localparam SA_DATA_WIDTH = 8; // 4 blocks with 2 bits each
localparam NUM_BLOCKS = 4;

program main_program  (
    output	logic	 [SA_DATA_WIDTH-1:0]	i_sa_data,
    output	logic	 		i_sa_data_valid,
    input	logic	 [NUM_BLOCKS-1:0]	o_block_replacement_mask,
    input	logic	 		o_brm_valid
);

    // driven
    logic	 [SA_DATA_WIDTH-1:0]	i_sa_data_d;
    logic	 		i_sa_data_valid_d;

    
    // sampled
    logic	 [NUM_BLOCKS-1:0]	o_block_replacement_mask_s;
    logic	 		o_brm_valid_s;


    localparam CLK_PERIOD = 50;
    localparam SAMPLE_SKEW = 5;
    localparam DRIVE_SKEW = 5;
    localparam MAX_CYCLES = 300;

    logic drive_clk;
    logic sample_clk;
    logic dut_clk;
    logic simulation_complete;

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
        for(int i=0; i < 256; ++i) begin
            i_sa_data_d <= i;
            i_sa_data_valid_d <= 1'b1;
            @(posedge drive_clk);
        end
        repeat(10) @(posedge drive_clk);
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
    
        o_block_replacement_mask_s	<=	o_block_replacement_mask;
        o_brm_valid_s	<=	o_brm_valid;

    endtask

    task drive();
    
        i_sa_data	<=	i_sa_data_d;
        i_sa_data_valid	<=	i_sa_data_valid_d;

    endtask

    task init();

        i_sa_data_d	= 0;
        i_sa_data_valid_d	= 0;

        i_sa_data	= 0;
        i_sa_data_valid	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 	[SA_DATA_WIDTH-1:0]	i_sa_data;
    logic 			i_sa_data_valid;
    logic 	[NUM_BLOCKS-1:0]	o_block_replacement_mask;
    logic 			o_brm_valid;



    lru_unit  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

