`ifndef __TAG_ARRAY_PARAMS
`define __TAG_ARRAY_PARAMS
    localparam NUM_ROWS = 16;
    localparam ADDR_WIDTH = 4; // $clog2(NUM_ROWS)
    localparam NUM_BLOCKS = 4;
    localparam BLOCK_WIDTH = 320;
    localparam ROW_WIDTH = 4*320; // NUM_BLOCKS*BLOCK_WIDTH
`endif