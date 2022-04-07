`ifndef __PCBRANCH_SV
`define __PCBRANCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module pcbranch
	import common::*;
	import pipes::*;(
	output u64 target,
    input u1 pcTarget,
    input u64 sextimm,
    input u64 jalrSrc,pc
);
always_comb begin
    target='0;
    if (pcTarget) begin
        target=jalrSrc;
    end else begin
        target=pc+sextimm;
    end
end
endmodule

`endif
