// This file is no longer used.
// localparams have been copied to modules
// file remains for users perusal
`ifndef __STATUS_ARRAY_PARAMS
`define __STATUS_ARRAY_PARAMS
    localparam NUM_ROWS = 16;
    localparam ADDR_WIDTH = 4; // $clog2(NUM_ROWS)
    localparam NUM_BLOCKS = 4;
    localparam BLOCK_WIDTH = 2;
    localparam ROW_WIDTH = 4*2; // NUM_BLOCKS*BLOCK_WIDTH

    // for use in understanding status_array_data
    localparam USE_BIT_IDX      = 0; 
    localparam VALID_BIT_IDX    = 1;
`endif