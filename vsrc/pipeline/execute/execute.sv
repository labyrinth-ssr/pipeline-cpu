`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/aluabselector.sv"
`include "pipeline/mux/mux3.sv"

`endif

module execute
import common::*;
	import pipes::*;(
    input clk,reset,
    input decode_data_t dataD,
    output execute_data_t dataE,
    input u2 forwardaE,forwardbE,
    input u64 aluoutM,resultW,
    output u1 e_wait
);
u64 alu_result;
word_t alu_a,alu_b;
u64 srca,srcb;
u64 pcAdded;
    mux3 forward_rd1(.d0(dataD.srca),.d1(aluoutM),.d2(resultW),.s(forwardaE),.y(srca));
    mux3 forward_rd2(.d0(dataD.srcb),.d1(aluoutM),.d2(resultW),.s(forwardbE),.y(srcb));

    aluabselector aluabselector(
        .selectA(dataD.ctl.selectA),
        .selectB(dataD.ctl.selectB),
        .sextimm(dataD.sextimm),.pc(dataD.pc),.srca,
        .srcb,.alu_a,.alu_b
    );

    alu alu (
        .clk,.reset,
        .a(alu_a),.b(alu_b),
        .alufunc(dataD.ctl.alufunc),
        .c(alu_result),.sign(dataD.ctl.alu_sign),.e_wait,.cut(dataD.ctl.alu_cut)
    );

    assign dataE.pc=dataD.pc;
    assign dataE.sextimm=dataD.sextimm;
    assign dataE.srcb=dataD.srcb;
    assign dataE.dst=dataD.rd;
    // assign dataE.ctl=dataD.ctl;
    assign dataE.pc=dataD.pc;
    assign dataE.valid=dataD.valid;
    assign dataE.ctl=dataD.ctl;
    assign dataE.alu_out=dataD.ctl.extAluOut?{{32{alu_result[31]}},alu_result[31:0]}:alu_result;
endmodule

`endif 