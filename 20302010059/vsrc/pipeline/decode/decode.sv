`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "include/interface.svh"
`endif

//decode 
module decode 
    import common::*;
    import pipes::*;(
        input fetch_data_t dataF,
        // dreg_intf.decode dreg_in,
        // ereg_intf.decode out_ereg,//dataD
        output decode_data_t dataD,
        // output u64 signed_imm,
        output creg_addr_t rs1,rs2,
        input word_t rd1,rd2
        // regfile_intf.decode decode_reg
);
    control_t ctl;
    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl(ctl)
    );
    
    assign dataD.raw_instr=dataF.raw_instr;
    assign dataD.srca=rd1;
    assign dataD.srcb=rd2;
    assign dataD.ctl=ctl;
    assign dataD.rd=dataF.raw_instr[11:7];
    assign dataD.pc=dataF.pc;
    assign dataD.valid=dataF.valid;


    assign rs2=ctl.op==ITYPE?'0:dataF.raw_instr[24:20];
    assign rs1=dataF.raw_instr[19:15];


    
endmodule

`endif 