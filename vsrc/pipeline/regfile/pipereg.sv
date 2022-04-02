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
    input enable,flush
    //use different should be included in the data_t
);
always_ff @( posedge clk ) begin
        if (/* ~resetn |  */hazard.flush) begin // flush overrides enable
            out <= '0;
        end else if (hazard.enable) begin
            out <= in;
        end
    end
endmodule
always_comb begin
    if (T.ctrl.op==) begin
        pass
    end
end
`endif 