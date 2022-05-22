`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "include/interface.svh"
`include "pipeline/decode/sext.sv"
`include "pipeline/decode/pcbranch.sv"
`include "pipeline/adder/adder.sv"
`include "pipeline/mux/mux2.sv"
`endif

//decode 
module decode 
    import common::*;
    import pipes::*;(
        input fetch_data_t dataF,
        output decode_data_t dataD,
        output creg_addr_t ra1,ra2,
        input word_t rd1,rd2,
        input u64 aluoutM,resultW,
        input u2 forwardaD,forwardbD
);
    control_t ctl;
    u64 sextimm,adder_res,adder_a;
    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl(ctl)
    );
    mux2 addera_mux(
        .d0(dataF.pc),.d1(branch_inputa),.s(ctl.pcTarget),.y(adder_a)
    );
    adder adder(
        .a(adder_a),.b(sextimm),.y(adder_res)
    );
    mux2 adderres_mux(
        .d0(adder_res),.d1(adder_res&~1),.s(ctl.pcTarget),.y(dataD.target)
    );

    u64 branch_inputa,branch_inputb;
    // mux2 branch_srca(.d0(rd1),.d1(aluoutM),.s(forwardaD),.y(branch_inputa));
    // mux2 branch_srcb(.d0(rd2),.d1(aluoutM),.s(forwardbD),.y(branch_inputb));

    mux3 branch_srca(.d0(rd1),.d1(resultW),.d2(aluoutM),.s(forwardaD),.y(branch_inputa));
    mux3 branch_srcb(.d0(rd2),.d1(resultW),.d2(aluoutM),.s(forwardbD),.y(branch_inputb));

    sext sext(
        .op(ctl.op),
        .raw_instr(dataF.raw_instr),
        .sextimm(sextimm)
    );
    pcbranch pcbranch(
        .branch(ctl.branch),.pcSrc(dataD.pcSrc),.srca(branch_inputa),.srcb(branch_inputb)
    );
    assign dataD.raw_instr=dataF.raw_instr;
    assign dataD.srca=branch_inputa;
    assign dataD.srcb=branch_inputb;
    assign dataD.ctl=ctl;
    assign dataD.rd=dataF.raw_instr[11:7];
    assign dataD.pc=dataF.pc;
    assign dataD.valid=dataF.valid;
    assign dataD.sextimm=sextimm;

    assign ra2=dataF.raw_instr[24:20];
    assign ra1=dataF.raw_instr[19:15];
    assign dataD.ra1=dataF.raw_instr[19:15];
    assign dataD.ra2=dataF.raw_instr[24:20];
    
endmodule

`endif 