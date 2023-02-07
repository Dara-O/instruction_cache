`timescale 1ns/1ps

localparam ADDR_WIDTH = 16;
localparam WORD_WIDTH = 20;
localparam MEM_IF_DATA_WIDTH = 40; // FIXME
localparam MEM_IF_ADDR_WIDTH = 16;

localparam SET_BITS_WIDTH = 4;
localparam B_OFFSET_BITS_WIDTH = 4;
localparam TAG_BITS_WIDTH = 8;
localparam NUM_WAYS = 4;


localparam TA_WORD_WIDTH    = 32; // 8 bits x 4 ways
localparam SA_WORD_WIDTH    = 8; // 2 bits x 4 ways
localparam DA_WRITE_WIDTH   = 80;

program main_program  (
    output	logic	 [ADDR_WIDTH-1:0]	i_addr,
    output	logic	 		i_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    output	logic	 [MEM_IF_DATA_WIDTH-1:0]	i_mem_data,
    output	logic	 		i_mem_data_valid,
    input	logic	 [WORD_WIDTH-1:0]	o_data,
    input	logic	 		o_valid,
    input	logic	 		o_ready,
    input	logic	 [MEM_IF_ADDR_WIDTH-1:0]	o_mem_addr,
    input	logic	 		o_mem_req_valid,
    input	logic	 		o_mem_if_ready
);

    // driven
    logic	 [ADDR_WIDTH-1:0]	i_addr_d;
    logic	 		i_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;
    logic	 [MEM_IF_DATA_WIDTH-1:0]	i_mem_data_d;
    logic	 		i_mem_data_valid_d;

    
    // sampled
    logic	 [WORD_WIDTH-1:0]	o_data_s;
    logic	 		o_valid_s;
    logic	 		o_ready_s;
    logic	 [MEM_IF_ADDR_WIDTH-1:0]	o_mem_addr_s;
    logic	 		o_mem_req_valid_s;
    logic	 		o_mem_if_ready_s;


    localparam CLK_PERIOD = 50;
    localparam SAMPLE_SKEW = 5;
    localparam DRIVE_SKEW = 5;
    localparam MAX_CYCLES = 500;

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
            monitor();
            watch_dog();
        join_any
        disable fork;
    
        simulation_complete = 1;
        $finish;
    end

    task test_sequence();
        reset();
        
        @(posedge sample_clk);
        wait(o_ready_s === 1'b1);

        for(int i=0; i<128; ++i) begin
            if(i[6] === 0) begin
                i_addr_d    = {i[11:4], 4'b0, i[3:0]};
            end
            else begin
                i_addr_d    = {i[11:4], 4'b1, i[3:0]};
            end
            i_valid_d   = 1'b1;
            @(posedge drive_clk);
            @(posedge sample_clk);
            wait(o_ready_s === 1'b1);
        end

        i_addr_d    = 0;
        i_valid_d   = 1'b0;
        @(posedge drive_clk);

        i_addr_d    = 0;
        i_valid_d   = 1'b1;
        repeat(3) @(posedge drive_clk);

        i_addr_d    = 0;
        i_valid_d   = 1'b0;
        @(posedge drive_clk);

        repeat(30) @(posedge drive_clk);
    endtask

    task monitor();
        int miss_index;
        logic [319:0] mem_data[0:7];
        mem_data[0] = {2{
            20'h5555,   20'haaaa,
            20'h3,      20'h1,
            20'h5555,   20'haaaa,
            20'h3,      20'h1
        }};
        mem_data[1] = {2{
            20'h7777,   20'hbbbb,
            20'h4,      20'h2,
            20'h7777,   20'hbbbb,
            20'h4,      20'h2
        }};

        for(int j = 2; j<8; ++j) begin
            mem_data[j] = {2{
                20'h7777+j[19:0],   20'hbbbb+j[19:0],
                20'h3+j[19:0],      20'h1+j[19:0],
                20'h7777+j[19:0],   20'hbbbb+j[19:0],
                20'h3+j[19:0],      20'h1+j[19:0]
            }};
        end
        forever begin
            @(posedge sample_clk);
            wait(o_mem_req_valid_s == 1'b1);
            wait(o_mem_if_ready_s == 1'b1);
            for(int i=0; i<8; ++i) begin
                i_mem_data_d = mem_data[miss_index][i*40+:40];
                i_mem_data_valid_d = 1'b1;
                @(posedge drive_clk);

                ++i;
                
                i_mem_data_d = mem_data[miss_index][i*40+:40];
                i_mem_data_valid_d = 1'b1;
                @(negedge drive_clk);
                #(DRIVE_SKEW);
                drive();
            end 
            i_mem_data_d = 40'h0;
            i_mem_data_valid_d = 1'b0;
            @(posedge drive_clk);
            ++miss_index;
        end
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
    
        o_data_s	<=	o_data;
        o_valid_s	<=	o_valid;
        o_ready_s	<=	o_ready;
        o_mem_addr_s	<=	o_mem_addr;
        o_mem_req_valid_s	<=	o_mem_req_valid;
        o_mem_if_ready_s	<=	o_mem_if_ready;

    endtask

    task drive();
    
        i_addr	<=	i_addr_d;
        i_valid	<=	i_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;
        i_mem_data	<=	i_mem_data_d;
        i_mem_data_valid	<=	i_mem_data_valid_d;

    endtask

    task init();

        i_addr_d	= 0;
        i_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;
        i_mem_data_d	= 0;
        i_mem_data_valid_d	= 0;

        i_addr	= 0;
        i_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;
        i_mem_data	= 0;
        i_mem_data_valid	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
        $display("Watch dog elapsed");
    endtask
    
endprogram


module tb;
    

    logic 	[ADDR_WIDTH-1:0]	i_addr;
    logic 			i_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[MEM_IF_DATA_WIDTH-1:0]	i_mem_data;
    logic 			i_mem_data_valid;
    logic 	[WORD_WIDTH-1:0]	o_data;
    logic 			o_valid;
    logic 			o_ready;
    logic 	[MEM_IF_ADDR_WIDTH-1:0]	o_mem_addr;
    logic 			o_mem_req_valid;
    logic 			o_mem_if_ready;



    instruction_cache  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

