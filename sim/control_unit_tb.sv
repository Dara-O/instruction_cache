`timescale 1ns/1ps

program main_program  (
    output	logic	 		i_cache_hit,
    output	logic	 		i_valid,
    output	logic	 		i_mem_data_received,
    output	logic	 		i_mem_if_valid,
    output	logic	 		i_arrays_update_complete,
    output	logic	 		i_auc_valid,
    output	logic	 		clk,
    output	logic	 		arst_n,
    output	logic	 		i_halt,
    input	logic	 		o_miss_state,
    input	logic	 		o_initiate_mem_req,
    input	logic	 		o_mem_if_valid,
    input	logic	 		o_initiate_array_update,
    input	logic	 		o_send_missed_word,
    input	logic	 		o_valid,
    input	logic	 		o_mem_if_ready,
    input	logic	 		o_arrays_udpater_ready,
    input	logic	 		o_ready
);

    // driven
    logic	 		i_cache_hit_d;
    logic	 		i_valid_d;
    logic	 		i_mem_data_received_d;
    logic	 		i_mem_if_valid_d;
    logic	 		i_arrays_update_complete_d;
    logic	 		i_auc_valid_d;
    logic	 		arst_n_d;
    logic	 		i_halt_d;

    
    // sampled
    logic	 		o_miss_state_s;
    logic	 		o_initiate_mem_req_s;
    logic	 		o_mem_if_valid_s;
    logic	 		o_initiate_array_update_s;
    logic	 		o_send_missed_word_s;
    logic	 		o_valid_s;
    logic	 		o_mem_if_ready_s;
    logic	 		o_arrays_udpater_ready_s;
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
        repeat(2) @(posedge drive_clk);
        
        for(int i=0; i < 1; ++i) begin
                
            i_cache_hit_d = 1'b0;
            i_valid_d = 1'b1;
            @(posedge drive_clk);
            
            @(posedge sample_clk);
            if(o_initiate_mem_req_s === 1'b1) begin
                memory_access();
            end

            @(posedge sample_clk);
            if(o_initiate_array_update_s === 1'b1) begin
                arrays_update();
            end
            
            @(posedge sample_clk);
            wait(o_miss_state_s === 1'b0);

        end

        i_cache_hit_d = 1'b0;
        i_valid_d = 1'b0;
        
        repeat(10) @(posedge drive_clk);
    endtask

    task memory_access(); 
        repeat(7) @(posedge dut_clk);

        i_mem_data_received_d  = 1'b1;
        i_mem_if_valid_d = 1'b1;
        @(posedge drive_clk);

        i_mem_data_received_d  = 1'b0;
        i_mem_if_valid_d = 1'b1;
    endtask

    task arrays_update();
        repeat(3) @(posedge dut_clk);

        i_arrays_update_complete_d    = 1'b1;
        i_auc_valid_d = 1'b1;
        @(posedge drive_clk);

        i_arrays_update_complete_d    = 1'b0;
        i_auc_valid_d = 1'b1;
        
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
    
        o_miss_state_s	<=	o_miss_state;
        o_initiate_mem_req_s	<=	o_initiate_mem_req;
        o_mem_if_valid_s	<=	o_mem_if_valid;
        o_initiate_array_update_s	<=	o_initiate_array_update;
        o_send_missed_word_s	<=	o_send_missed_word;
        o_valid_s	<=	o_valid;
        o_mem_if_ready_s	<=	o_mem_if_ready;
        o_arrays_udpater_ready_s	<=	o_arrays_udpater_ready;
        o_ready_s	<=	o_ready;

    endtask

    task drive();
    
        i_cache_hit	<=	i_cache_hit_d;
        i_valid	<=	i_valid_d;
        i_mem_data_received	<=	i_mem_data_received_d;
        i_mem_if_valid	<=	i_mem_if_valid_d;
        i_arrays_update_complete	<=	i_arrays_update_complete_d;
        i_auc_valid	<=	i_auc_valid_d;
        arst_n	<=	arst_n_d;
        i_halt	<=	i_halt_d;

    endtask

    task init();

        i_cache_hit_d	= 0;
        i_valid_d	= 0;
        i_mem_data_received_d	= 0;
        i_mem_if_valid_d	= 0;
        i_arrays_update_complete_d	= 0;
        i_auc_valid_d	= 0;
        arst_n_d	= 0;
        i_halt_d	= 0;

        i_cache_hit	= 0;
        i_valid	= 0;
        i_mem_data_received	= 0;
        i_mem_if_valid	= 0;
        i_arrays_update_complete	= 0;
        i_auc_valid	= 0;
        arst_n	= 0;
        i_halt	= 0;

    endtask

    task watch_dog();
        repeat(MAX_CYCLES) @(posedge dut_clk);
    endtask
    
endprogram


module tb;
    

    logic 			i_cache_hit;
    logic 			i_valid;
    logic 			i_mem_data_received;
    logic 			i_mem_if_valid;
    logic 			i_arrays_update_complete;
    logic 			i_auc_valid;
    logic 			clk;
    logic 			arst_n;
    logic 			i_halt;
    logic 			o_miss_state;
    logic 			o_initiate_mem_req;
    logic 			o_mem_if_valid;
    logic 			o_initiate_array_update;
    logic 			o_send_missed_word;
    logic 			o_valid;
    logic 			o_mem_if_ready;
    logic 			o_arrays_udpater_ready;
    logic 			o_ready;



    control_unit  dut(.*);
    
    main_program  main(.*);
    
    initial begin
        $dumpfile("wave.vcd");  
        $dumpvars(0, tb);
    end
endmodule

