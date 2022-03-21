`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`endif

module execute(
    input clk,
    ereg_intf.execute ereg_in,
    mreg_intf.execute out_mreg
);
u64 alu_result;

    alu alu (
        .a(ereg_in.dataD.srca),.b(ereg_in.dataD.srcb),
        .alufunc(ereg_in.dataD.ctl.alufunc),
        .c(alu_result)
    );
    assign out_mreg.dataE_nxt.pc=ereg_in.dataD.pc;
    assign out_mreg.dataE_nxt.alu_out=alu_result;
    // assign out_mreg.dataE_nxt.ctl=ereg_in.dataD.ctl;

    always_ff @(posedge clk) begin $display("%x", alu_result); end


    
endmodule

`endif 