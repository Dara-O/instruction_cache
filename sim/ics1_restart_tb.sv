`timescale 1ns/1ps

localparam ADDR_WIDTH       = 16;

program main_program  (
    output	logic	 [ADDR_WIDTH-1:0]	i_curr_r_addr,
    output	logic	 		i_curr_r_addr_valid,
    output	logic	 [ADDR_WIDTH-1:0]	i_prev_r_addr,
    output	logic	 		i_prev_r_addr_valid,
    output	logic	 		i_miss_state,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 [ADDR_WIDTH-1:0]	o_r_addr,
    input	logic	 		o_r_addr_valid,
    input	logic	 		o_curr_r_addr_ready
);

    // driven
    logic	 [ADDR_WIDTH-1:0]	i_curr_r_addr_d;
    logic	 		i_curr_r_addr_valid_d;
    logic	 [ADDR_WIDTH-1:0]	i_prev_r_addr_d;
    logic	 		i_prev_r_addr_valid_d;
    logic	 		i_miss_state_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [ADDR_WIDTH-1:0]	o_r_addr_s;
    logic	 		o_r_addr_valid_s;
    logic	 		o_curr_r_addr_ready_s;


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
        
        i_curr_r_addr_d = 'ha;
        i_curr_r_addr_valid_d = 'h1;
        @(posedge drive_clk);

        i_curr_r_addr_d = 'hb;
        i_curr_r_addr_valid_d = 'h1;

        i_prev_r_addr_d = 'ha;
        i_prev_r_addr_valid_d = 'h1;
        @(posedge drive_clk);
        
        i_curr_r_addr_d = 'hc;
        i_curr_r_addr_valid_d = 'h1;

        i_prev_r_addr_d = 'hb;
        i_prev_r_addr_valid_d = 'h1;

        i_miss_state_d = 1'b1;
        @(posedge drive_clk);

        repeat(2) @(posedge clk);

        i_miss_state_d = 1'b0;
        @(posedge drive_clk);
        @(posedge sample_clk);
        wait(o_curr_r_addr_ready_s === 1'b1);
        i_curr_r_addr_d = 'hd;
        i_curr_r_addr_valid_d = 'h1;

        i_prev_r_addr_d = 'hc;
        i_prev_r_addr_valid_d = 'h1;


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
    
        o_r_addr_s	<=	o_r_addr;
        o_r_addr_valid_s	<=	o_r_addr_valid;
        o_curr_r_addr_ready_s	<=	o_curr_r_addr_ready;

    endtask

    task drive();
    
        i_curr_r_addr	<=	i_curr_r_addr_d;
        i_curr_r_addr_valid	<=	i_curr_r_addr_valid_d;
        i_prev_r_addr	<=	i_prev_r_addr_d;
        i_prev_r_addr_valid	<=	i_prev_r_addr_valid_d;
        i_miss_state	<=	i_miss_state_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_curr_r_addr_d	= 0;
        i_curr_r_addr_valid_d	= 0;
        i_prev_r_addr_d	= 0;
        i_prev_r_addr_valid_d	= 0;
        i_miss_state_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_curr_r_addr	= 0;
        i_curr_r_addr_valid	= 0;
        i_prev_r_addr	= 0;
        i_prev_r_addr_valid	= 0;
        i_miss_state	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 	[ADDR_WIDTH-1:0]	i_curr_r_addr;
    logic 			i_curr_r_addr_valid;
    logic 	[ADDR_WIDTH-1:0]	i_prev_r_addr;
    logic 			i_prev_r_addr_valid;
    logic 			i_miss_state;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[ADDR_WIDTH-1:0]	o_r_addr;
    logic 			o_r_addr_valid;
    logic 			o_curr_r_addr_ready;



    ics1_restart  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

