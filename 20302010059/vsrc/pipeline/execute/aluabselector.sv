`ifndef __ALUABSELECTOR_SV
`define __ALUABSELECTOR_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module aluabselector
	import common::*;
	import pipes::*;(
    input u1 selectA,selectB,
    input u64 sextimm,pc,srca,srcb,
    output u64 alu_a,alu_b
);
always_comb begin
    alu_a=selectA?pc:srca;
    alu_b=selectB?sextimm:srcb;
end
endmodule

`endif
