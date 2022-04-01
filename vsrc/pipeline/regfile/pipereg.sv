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
    input logic enable, flush,
    // hazard_intf.pipereg hazard
);
always_ff @( posedge clk ) begin
        if (~resetn | flush) begin // flush overrides enable
            out <= '0;
        end else if (enable) begin
            out <= in;
        end
    end
endmodule
`endif 