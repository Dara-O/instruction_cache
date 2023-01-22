`timescale 1ns/1ps

localparam ADDR_WIDTH           = 8;
localparam MEM_DATA_WIDTH       = 32;
localparam MEM_BLOCK_DATA_WIDTH = 320;

localparam  NUM_MEM_TRANSACTIONS = 10; // NUM_MEM_TRANSACTIONS*MEM_DATA_WIDTH = MEM_BLOCK_DATA_WIDTH

program main_program  (
    output	logic	 [ADDR_WIDTH-1:0]	i_block_addr,
    output	logic	 		i_block_addr_valid,
    output	logic	 		i_initiate_req,
    output	logic	 		i_ir_valid,
    output	logic	 [MEM_DATA_WIDTH-1:0]	i_mem_data,
    output	logic	 		i_mem_data_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 [ADDR_WIDTH-1:0]	o_mem_req_addr,
    input	logic	 		o_mem_req_valid,
    input	logic	 		o_mem_ready,
    input	logic	 		o_mem_data_received,
    input	logic	 		o_mem_data_rcvd_valid,
    input	logic	 		o_ir_ready,
    input	logic	 [MEM_BLOCK_DATA_WIDTH-1:0]	o_mem_block_data,
    input	logic	 		o_mem_block_data_valid
);

    // driven
    logic	 [ADDR_WIDTH-1:0]	i_block_addr_d;
    logic	 		i_block_addr_valid_d;
    logic	 		i_initiate_req_d;
    logic	 		i_ir_valid_d;
    logic	 [MEM_DATA_WIDTH-1:0]	i_mem_data_d;
    logic	 		i_mem_data_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 [ADDR_WIDTH-1:0]	o_mem_req_addr_s;
    logic	 		o_mem_req_valid_s;
    logic	 		o_mem_ready_s;
    logic	 		o_mem_data_received_s;
    logic	 		o_mem_data_rcvd_valid_s;
    logic	 		o_ir_ready_s;
    logic	 [MEM_BLOCK_DATA_WIDTH-1:0]	o_mem_block_data_s;
    logic	 		o_mem_block_data_valid_s;


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
        
        i_block_addr_d = 'haa;
        i_block_addr_valid_d = 1'b1;
        
        i_initiate_req_d = 1'b1;
        i_ir_valid_d = 1'b1;
        @(posedge drive_clk);
        i_initiate_req_d = 1'b0;
        i_ir_valid_d = 1'b0;
        @(posedge sample_clk);
        wait(o_mem_ready_s === 1'b1);
        mem_req_handler('haaaa_aaaaa);
        repeat(2) @(posedge dut_clk);


        i_block_addr_d = 'hbb;
        i_block_addr_valid_d = 1'b1;
        
        i_initiate_req_d = 1'b1;
        i_ir_valid_d = 1'b1;
        @(posedge drive_clk);
        i_initiate_req_d = 1'b0;
        i_ir_valid_d = 1'b0;

        @(posedge sample_clk);
        wait(o_mem_ready_s === 1'b1);
        mem_req_handler('h5555_5555);

        repeat(10) @(posedge drive_clk);
    endtask

    task mem_req_handler(input logic [31:0] mem_val);
        for(int i=0; i < 10; ++i) begin
            i_mem_data_d =  mem_val;
            i_mem_data_valid_d <= 'b1;
            @(posedge drive_clk);
        end
        i_mem_data_d = 'h0;
        i_mem_data_valid_d <= 'b0;
        @(posedge dut_clk);
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
    
        o_mem_req_addr_s	<=	o_mem_req_addr;
        o_mem_req_valid_s	<=	o_mem_req_valid;
        o_mem_ready_s	<=	o_mem_ready;
        o_mem_data_received_s	<=	o_mem_data_received;
        o_mem_data_rcvd_valid_s	<=	o_mem_data_rcvd_valid;
        o_ir_ready_s	<=	o_ir_ready;
        o_mem_block_data_s	<=	o_mem_block_data;
        o_mem_block_data_valid_s	<=	o_mem_block_data_valid;

    endtask

    task drive();
    
        i_block_addr	<=	i_block_addr_d;
        i_block_addr_valid	<=	i_block_addr_valid_d;
        i_initiate_req	<=	i_initiate_req_d;
        i_ir_valid	<=	i_ir_valid_d;
        i_mem_data	<=	i_mem_data_d;
        i_mem_data_valid	<=	i_mem_data_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_block_addr_d	= 0;
        i_block_addr_valid_d	= 0;
        i_initiate_req_d	= 0;
        i_ir_valid_d	= 0;
        i_mem_data_d	= 0;
        i_mem_data_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_block_addr	= 0;
        i_block_addr_valid	= 0;
        i_initiate_req	= 0;
        i_ir_valid	= 0;
        i_mem_data	= 0;
        i_mem_data_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 	[ADDR_WIDTH-1:0]	i_block_addr;
    logic 			i_block_addr_valid;
    logic 			i_initiate_req;
    logic 			i_ir_valid;
    logic 	[MEM_DATA_WIDTH-1:0]	i_mem_data;
    logic 			i_mem_data_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 	[ADDR_WIDTH-1:0]	o_mem_req_addr;
    logic 			o_mem_req_valid;
    logic 			o_mem_ready;
    logic 			o_mem_data_received;
    logic 			o_mem_data_rcvd_valid;
    logic 			o_ir_ready;
    logic 	[MEM_BLOCK_DATA_WIDTH-1:0]	o_mem_block_data;
    logic 			o_mem_block_data_valid;



    memory_controller  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

