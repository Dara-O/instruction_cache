`timescale 1ns/1ps

program main_program #(parameter WORD_WIDTH=12, ADDR_WIDTH=3, TAG_WIDTH=1) (
    output	logic	 [TAG_WIDTH-1:0]	i_tag,
    output	logic	 [ADDR_WIDTH-1:0]	i_addr,
    output	logic	 [WORD_WIDTH-1:0]	i_data,
    output	logic	 		i_wen,
    output	logic	 		i_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 [TAG_WIDTH-1:0]	o_tag,
    input	logic	 [WORD_WIDTH-1:0]	o_data,
    input	logic	 		o_valid,
    input	logic	 		o_freeze_inputs
);

    // driven
    logic	 [TAG_WIDTH-1:0]	i_tag_d;
    logic	 [ADDR_WIDTH-1:0]	i_addr_d;
    logic	 [WORD_WIDTH-1:0]	i_data_d;
    logic	 		i_wen_d;
    logic	 		i_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [TAG_WIDTH-1:0]	o_tag_s;
    logic	 [WORD_WIDTH-1:0]	o_data_s;
    logic	 		o_valid_s;
    logic	 		o_freeze_inputs_s;


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
        for(int i=0; i < 8; ++i) begin
            
            i_tag_d     <= i;
            i_addr_d    <= i;
            i_data_d    <= 12'ha+i;
            i_wen_d     <= 1'h1;
            i_valid_d   <= 1'b1;
            
            if(i == 4) begin
                i_halt_d <= 1'h1; 
            end
            else begin
                i_halt_d <= 1'h0;
            end

            @(posedge drive_clk);            
        end

        i_tag_d     <= 1'h0;
        i_addr_d    <= 3'b0;
        i_data_d    <= 12'h0;
        i_wen_d     <= 1'h0;
        i_valid_d   <= 1'b0;
        
        @(posedge drive_clk);

        for(int i=0; i < 8; ++i) begin
            
            i_tag_d     <= i;
            i_addr_d    <= i;
            i_data_d    <= 12'h0;
            i_wen_d     <= 1'h0;
            i_valid_d   <= 1'b1;
            
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
    
        o_tag_s	<=	o_tag;
        o_data_s	<=	o_data;
        o_valid_s	<=	o_valid;
        o_freeze_inputs_s	<=	o_freeze_inputs;

    endtask

    task drive();
    
        i_tag	<=	i_tag_d;
        i_addr	<=	i_addr_d;
        i_data	<=	i_data_d;
        i_wen	<=	i_wen_d;
        i_valid	<=	i_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_tag_d	= 0;
        i_addr_d	= 0;
        i_data_d	= 0;
        i_wen_d	= 0;
        i_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_tag	= 0;
        i_addr	= 0;
        i_data	= 0;
        i_wen	= 0;
        i_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
        $display("WARNING: Watch dog timer finished.");
    endtask
    
endprogram


module tb;
    
    parameter WORD_WIDTH = 12;
    parameter ADDR_WIDTH = 3;
    parameter TAG_WIDTH = 1;

    logic 	[TAG_WIDTH-1:0]	i_tag;
    logic 	[ADDR_WIDTH-1:0]	i_addr;
    logic 	[WORD_WIDTH-1:0]	i_data;
    logic 			i_wen;
    logic 			i_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[TAG_WIDTH-1:0]	o_tag;
    logic 	[WORD_WIDTH-1:0]	o_data;
    logic 			o_valid;
    logic 			o_freeze_inputs;



    status_register_file #(.WORD_WIDTH(WORD_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .TAG_WIDTH(TAG_WIDTH)) dut(.*);
    
    main_program #(.WORD_WIDTH(WORD_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .TAG_WIDTH(TAG_WIDTH)) main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule
