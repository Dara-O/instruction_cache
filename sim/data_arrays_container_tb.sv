`timescale 1ns/1ps

localparam ADDR_WIDTH   = 8;
localparam WORD_WIDTH   = 20;
localparam NUM_BLOCKS   = 4;

program main_program  (
    output	logic	 [ADDR_WIDTH-1:0]	i_r_addr,
    output	logic	 		i_r_valid,
    output	logic	 [NUM_BLOCKS-1:0]	i_r_mask,
    output	logic	 [ADDR_WIDTH-1:0]	i_w_addr,
    output	logic	 [WORD_WIDTH-1:0]	i_w_data,
    output	logic	 		i_w_valid,
    output	logic	 [NUM_BLOCKS-1:0]	i_w_mask,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt_all,
    output	logic	 		i_stop_read_clk,
    output	logic	 		i_stop_write_clk,
    input	logic	 [WORD_WIDTH-1:0]	o_word_data,
    input	logic	 		o_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 [ADDR_WIDTH-1:0]	i_r_addr_d;
    logic	 		i_r_valid_d;
    logic	 [NUM_BLOCKS-1:0]	i_r_mask_d;
    logic	 [ADDR_WIDTH-1:0]	i_w_addr_d;
    logic	 [WORD_WIDTH-1:0]	i_w_data_d;
    logic	 		i_w_valid_d;
    logic	 [NUM_BLOCKS-1:0]	i_w_mask_d;
    logic	 		arst_n_d;
    logic	 		i_halt_all_d;
    logic	 		i_stop_read_clk_d;
    logic	 		i_stop_write_clk_d;

    
    // sampled
    logic	 [WORD_WIDTH-1:0]	o_word_data_s;
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
        logic [3:0] mask;
        reset();
        
        mask = 4'b0001;

        for(int i = 0; i < 4; ++i) begin
            mask = 4'b0001 << i;
            for (int addr = 0; addr < 256; ++addr) begin
                i_w_addr_d = addr;
                i_w_data_d = 20'h2aa + i;
                i_w_valid_d = 1'b1;
                i_w_mask_d = mask;

                @(posedge drive_clk);
            end
        end

        i_w_addr_d = 0;
        i_w_data_d = 0;
        i_w_valid_d = 0;
        i_w_mask_d = 0;
        @(posedge drive_clk);
        

        for(int i = 0; i < 4; ++i) begin
            mask = 4'b0001 << i;
            for (int addr = 0; addr < 256; ++addr) begin
                i_r_addr_d = addr;
                i_r_valid_d = 1'b1;
                i_r_mask_d = mask;

                if(i == 1) begin
                    i_stop_read_clk_d = 1;
                end
                else begin
                    i_stop_read_clk_d = 0;
                end

                @(posedge drive_clk);
            end
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
    
        o_word_data_s	<=	o_word_data;
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_r_addr	<=	i_r_addr_d;
        i_r_valid	<=	i_r_valid_d;
        i_r_mask	<=	i_r_mask_d;
        i_w_addr	<=	i_w_addr_d;
        i_w_data	<=	i_w_data_d;
        i_w_valid	<=	i_w_valid_d;
        i_w_mask	<=	i_w_mask_d;
        arst_n	<=	arst_n_d;
        i_halt_all	<=	i_halt_all_d;
        i_stop_read_clk	<=	i_stop_read_clk_d;
        i_stop_write_clk	<=	i_stop_write_clk_d;

    endtask

    task init();

        i_r_addr_d	= 0;
        i_r_valid_d	= 0;
        i_r_mask_d	= 0;
        i_w_addr_d	= 0;
        i_w_data_d	= 0;
        i_w_valid_d	= 0;
        i_w_mask_d	= 0;
        arst_n_d	= 0;
        i_halt_all_d	= 0;
        i_stop_read_clk_d	= 0;
        i_stop_write_clk_d	= 0;

        i_r_addr	= 0;
        i_r_valid	= 0;
        i_r_mask	= 0;
        i_w_addr	= 0;
        i_w_data	= 0;
        i_w_valid	= 0;
        i_w_mask	= 0;
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
    

    logic 	[ADDR_WIDTH-1:0]	i_r_addr;
    logic 			i_r_valid;
    logic 	[NUM_BLOCKS-1:0]	i_r_mask;
    logic 	[ADDR_WIDTH-1:0]	i_w_addr;
    logic 	[WORD_WIDTH-1:0]	i_w_data;
    logic 			i_w_valid;
    logic 	[NUM_BLOCKS-1:0]	i_w_mask;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt_all;
    logic 			i_stop_read_clk;
    logic 			i_stop_write_clk;
    logic 	[WORD_WIDTH-1:0]	o_word_data;
    logic 			o_valid;
    logic 			o_ready;



    data_arrays_container  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

