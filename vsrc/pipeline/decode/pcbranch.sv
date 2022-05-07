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
        input branch_t branch,
        output u1 pcSrc,
        input u64 srca,srcb
);
    always_comb begin
        pcSrc='0;
        if (branch!=NO_BRANCH) begin
            pcSrc=(branch==BRANCH_BEQ&&srca==srcb)||(branch==BRANCH_BNE&&srca!=srcb)||(branch==BRANCH_BLT&&$signed(srca)<$signed(srcb))||(branch==BRANCH_BGE&&$signed(srca)>=$signed(srcb))||(branch==BRANCH_BLTU&&srca<srcb)||(branch==BRANCH_BGEU&&srca>=srcb)||(branch==J);
        end
    end

endmodule

`endif
