`ifndef __MUX2_SV
`define __MUX2_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 

module mux2
import common::*;
#(parameter WIDTH = 64)
( input [WIDTH-1:0] d0,d1,
    input s,
    output [WIDTH-1:0] y
);
assign y = s?d1:d0;

endmodule

`endif 