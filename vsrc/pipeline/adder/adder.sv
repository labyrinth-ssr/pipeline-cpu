`ifndef __ADDER_SV
`define __ADDER_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 

module adder
import common::*;
#(parameter WIDTH = 64)
( input [WIDTH-1:0] a,b,
    output [WIDTH-1:0] y
);
assign y = a+b;

endmodule

`endif 