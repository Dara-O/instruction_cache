`ifndef __STATUS_ARRAY_PARAMS
`define __STATUS_ARRAY_PARAMS
    localparam NUM_ROWS = 16;
    localparam ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam NUM_BLOCKS = 4;
    localparam BLOCK_WIDTH = 2;
    localparam ROW_WIDTH = NUM_BLOCKS*BLOCK_WIDTH;
`endif