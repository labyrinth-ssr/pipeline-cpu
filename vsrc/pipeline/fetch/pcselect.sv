`ifndef __PCSELECT_SV
`define __PCSELECT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
// `include "include/pipes.sv"
`else
`endif

module pcselect
    import common::*;
    (
    // input u64 pcplus4,
    // output u64 pc_selected,
    // input u64 pc_branch,
    // input branch_taken
    pcselect_intf.pcselect self
);
    // assign self.pcplus4=self.pc+4;
    always_comb begin
        if (self.branch_taken) begin
            self.pc_selected=self.pcbranch;
        end else begin
            self.pc_selected=self.pcplus4;
        end
    end
endmodule
`endif 