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
    input u64 pcplus4,
    output u64 pc_selected,
    input u64 pc_branch,
    input branch_taken,
    input u64 mepc,mtvec,
    input u1 is_mret,
    input u1 is_INTEXC
);
    always_comb begin
    pc_selected='0;
    if (is_mret) begin
        pc_selected=mepc;
    end else if (is_INTEXC) begin
        pc_selected=mtvec;
    end 
    else if (branch_taken) begin
            pc_selected=pc_branch;
        end else begin
            pc_selected=pcplus4;
        end
    end
endmodule
`endif 