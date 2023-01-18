`timescale 1ns/1ps

`include "../src/tag_array_params.vh"

program main_program #(parameter TAG_WIDTH=1) (
    output	logic	 [TAG_WIDTH-1:0]	i_tag,
    output	logic	 [ADDR_WIDTH-1:0]	i_r_addr,
    output	logic	 		i_r_valid,
    output	logic	 [ADDR_WIDTH-1:0]	i_w_addr,
    output	logic	 [ROW_WIDTH-1:0]	i_w_data,
    output	logic	 [NUM_BLOCKS-1:0]	i_w_wmask,
    output	logic	 		i_w_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 [TAG_WIDTH-1:0]	o_tag,
    input	logic	 [ROW_WIDTH-1:0]	o_data,
    input	logic	 		o_valid,
    input	logic	 		o_ready
);

    // driven
    logic	 [TAG_WIDTH-1:0]	i_tag_d;
    logic	 [ADDR_WIDTH-1:0]	i_r_addr_d;
    logic	 		i_r_valid_d;
    logic	 [ADDR_WIDTH-1:0]	i_w_addr_d;
    logic	 [ROW_WIDTH-1:0]	i_w_data_d;
    logic	 [NUM_BLOCKS-1:0]	i_w_wmask_d;
    logic	 		i_w_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [TAG_WIDTH-1:0]	o_tag_s;
    logic	 [ROW_WIDTH-1:0]	o_data_s;
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

        @(posedge clk);
        for(int i=0; i < 16; ++i) begin
            
            i_w_addr_d  <= i;
            i_w_data_d  <= 'haaaa_aaaa ^ {ROW_WIDTH{i[0]}};
            i_w_valid_d <= 1'h1;
            i_w_wmask_d <= 4'b1111;
            
            if(i == 4 || i == 8) begin
                i_halt_d <= 1'h1; 
            end
            else begin
                i_halt_d <= 1'h0;
            end

            @(posedge drive_clk);            
        end

        i_w_addr_d    <= 4'b0;
        i_w_data_d    <= 'h0;
        i_w_valid_d     <= 1'h0;
        i_w_wmask_d   <= 4'b0000;
        
        @(posedge drive_clk);

        for(int i=0; i < 16; ++i) begin
            
            i_tag_d     <= i;
            i_r_addr_d    <= i;
            i_r_valid_d   <= 1'b1;
            
            @(posedge drive_clk);
        end

        i_tag_d     <= 1'h0;
        i_r_addr_d    <= 4'b0;
        i_r_valid_d   <= 1'b0;
        
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
    
        o_tag_s	<=	o_tag;
        o_data_s	<=	o_data;
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_tag	<=	i_tag_d;
        i_r_addr	<=	i_r_addr_d;
        i_r_valid	<=	i_r_valid_d;
        i_w_addr	<=	i_w_addr_d;
        i_w_data	<=	i_w_data_d;
        i_w_wmask	<=	i_w_wmask_d;
        i_w_valid	<=	i_w_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_tag_d	= 0;
        i_r_addr_d	= 0;
        i_r_valid_d	= 0;
        i_w_addr_d	= 0;
        i_w_data_d	= 0;
        i_w_wmask_d	= 0;
        i_w_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_tag	= 0;
        i_r_addr	= 0;
        i_r_valid	= 0;
        i_w_addr	= 0;
        i_w_data	= 0;
        i_w_wmask	= 0;
        i_w_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    
    parameter TAG_WIDTH = 1;

    logic 	[TAG_WIDTH-1:0]	i_tag;
    logic 	[ADDR_WIDTH-1:0]	i_r_addr;
    logic 			i_r_valid;
    logic 	[ADDR_WIDTH-1:0]	i_w_addr;
    logic 	[ROW_WIDTH-1:0]	i_w_data;
    logic 	[NUM_BLOCKS-1:0]	i_w_wmask;
    logic 			i_w_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[TAG_WIDTH-1:0]	o_tag;
    logic 	[ROW_WIDTH-1:0]	o_data;
    logic 			o_valid;
    logic 			o_ready;



    tag_array #(.TAG_WIDTH(TAG_WIDTH)) dut(.*);
    
    main_program #(.TAG_WIDTH(TAG_WIDTH)) main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

