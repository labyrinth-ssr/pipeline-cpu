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
    output T out,
    input en,flush
    // input enable,flush
    //use different should be included in the data_t
);
always_ff @( posedge clk ) begin
        if (reset||flush) begin // flush overrides enable
            out <= '0;
        end else if (en) begin
            out <= in;
        end
    end

endmodule

`endif 