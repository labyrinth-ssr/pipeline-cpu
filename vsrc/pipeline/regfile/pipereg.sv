`ifndef __PIPEREG_SV
`define __PIPEREG_SV
`ifdef VERILATOR
`include "include/pipes.sv"
`endif

module pipereg
import pipes::*; #(
    parameter type T=fetch_data_t
) (
    input clk,
    input reset,
    input T in,
    output T out
);
always_ff @( posedge clk ) begin
        out<=in;
    end
endmodule
`endif 