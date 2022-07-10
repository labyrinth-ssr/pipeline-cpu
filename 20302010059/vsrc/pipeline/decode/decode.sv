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
`include "pipeline/mux/mux4.sv"
`endif

//decode 
module decode 
    import common::*;
    import pipes::*;(
        input fetch_data_t dataF,
        output decode_data_t dataD,
        output creg_addr_t ra1,ra2,
        input word_t rd1,rd2,
        input u64 aluoutM,resultW,aluoutM2,
        input u2 forwardaD,forwardbD
);
    control_t ctl;
    csr_control_t csr_ctl;
    u64 branch_inputa,branch_inputb;
    u64 sextimm,adder_res,adder_a;
    u1 illegal_instr;
    u7 f7=dataF.raw_instr[6:0];
    u3 f3=dataF.raw_instr[14:12];

    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl(ctl),
        .illegal_instr
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
    // mux2 branch_srca(.d0(rd1),.d1(aluoutM),.s(forwardaD),.y(branch_inputa));
    // mux2 branch_srcb(.d0(rd2),.d1(aluoutM),.s(forwardbD),.y(branch_inputb));

    mux4 branch_srca(.d0(rd1),.d1(resultW),.d2(aluoutM),.d3(aluoutM2),.s(forwardaD),.y(branch_inputa));
    mux4 branch_srcb(.d0(rd2),.d1(resultW),.d2(aluoutM),.d3(aluoutM2),.s(forwardbD),.y(branch_inputb));

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
    assign dataD.int_type=dataF.int_type;

    always_comb begin
        dataD.csr_ctl.ctype=dataF.csr_ctl.ctype;
        dataD.csr_ctl.code=dataF.csr_ctl.code;

        dataD.csr_ctl.valid='0;
        dataD.csr_ctl.imm='0;
        dataD.csr_ctl.op='0;

        if (f7==F7_CSR) begin
            if (f3==F3_MRET) begin
                dataD.csr_ctl.ctype=RET;
                if (dataF.raw_instr[31:20]=='0) begin
                    dataD.csr_ctl.ctype=EXCEPTION;
                    dataD.csr_ctl.code=4'h8;
                end
            end
            else begin
            dataD.csr_ctl.ctype=CSR_INSTR;
            dataD.csr_ctl.valid='1;
            end
            unique case (f3)
                F3_CSRRC: dataD.csr_ctl.op=CSRRC;
                F3_CSRRCI: begin
                dataD.csr_ctl.op=CSRRC;
                dataD.csr_ctl.imm='1;
                end
                F3_CSRRS: dataD.csr_ctl.op=CSRRS;
                F3_CSRRSI: begin
                dataD.csr_ctl.op=CSRRS;
                dataD.csr_ctl.imm='1;
                end
                F3_CSRRW: dataD.csr_ctl.op=CSRRW;
                F3_CSRRWI: begin
                dataD.csr_ctl.op=CSRRW;
                dataD.csr_ctl.imm='1;
                end
                default: ;
            endcase
        end
    end

    // assign dataD.csr_ctl.rs1rd=branch_inputa;
    assign dataD.csr_ctl.zimm=dataF.raw_instr[19:15];
    assign dataD.csr_ctl.csra=dataF.raw_instr[31:20];

    
endmodule

`endif 