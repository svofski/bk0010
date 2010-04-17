// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. Breakpoint match module.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

module match(inp_val,match_val,mask,hit);
    input [15:0] inp_val;
    input [15:0] match_val;
    input [15:0] mask;
    output hit;


    wire [15:0] raw;
    assign raw =  inp_val ^ match_val;
    assign hit =  (raw & mask) == 16'b0;


endmodule
