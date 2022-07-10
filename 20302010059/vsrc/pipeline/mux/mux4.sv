`ifndef __MUX4_SV
`define __MUX4_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 

module mux4
import common::*;
#(parameter WIDTH = 64)
( input logic [WIDTH-1:0] d0,d1,d2,d3,
    input u2 s,
    output logic [WIDTH-1:0] y
);
always_comb begin
    y='0;
    unique case (s)
    2'b00: y=d0;
    2'b01: y=d1;
    2'b10: y=d2;
    2'b11: y=d3;
    default: ;
endcase
end


endmodule

`endif 