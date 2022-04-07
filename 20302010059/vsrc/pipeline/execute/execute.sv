`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/sext.sv"
`include "pipeline/execute/pcbranch.sv"
`include "pipeline/execute/aluabselector.sv"


`endif

module execute
import common::*;
	import pipes::*;(
    input decode_data_t dataD,
    output execute_data_t dataE
    // ereg_intf.execute ereg_in,
    // mreg_intf.execute out_mreg
);
u64 alu_result;
word_t alu_a,alu_b;

u64 sextimm;
u64 pcAdded;

    aluabselector aluabselector(
        .selectA(dataD.ctl.selectA),
        .selectB(dataD.ctl.selectB),
        .sextimm,.pc(dataD.pc),.srca(dataD.srca),
        .srcb(dataD.srcb),.alu_a,.alu_b
    );

    alu alu (
        .a(alu_a),.b(alu_b),
        .alufunc(dataD.ctl.alufunc),
        .c(alu_result)
    );
    sext sext(
        .op(dataD.ctl.op),
        .raw_instr(dataD.raw_instr),
        .sextimm(sextimm)
    );
    pcbranch pcbranch (
        .pc(dataD.pc),
        .jalrSrc(alu_result&~1),
        .pcTarget(dataD.ctl.pcTarget),
        .sextimm(sextimm),
        .target(dataE.target)
    );
    assign dataE.pc=dataD.pc;
    assign dataE.alu_out=alu_result;
    assign dataE.sextimm=sextimm;
    assign dataE.srcb=dataD.srcb;
    assign dataE.dst=dataD.rd;
    assign dataE.ctl=dataD.ctl;
    assign dataE.pc=dataD.pc;
    assign dataE.valid=dataD.valid;

    // assign dataE_nxt.ctl=dataD.ctl;
    // always_ff @(posedge clk) begin $display("%x", alu_result); end
endmodule

`endif 