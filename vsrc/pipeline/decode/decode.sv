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
        ereg_intf.decode out_ereg,
        // output decode_data_t dataD,
        // output u64 signed_imm,
        output creg_addr_t ra1,ra2,
        input word_t rd1,rd2//
);
    control_t ctl;
    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl(ctl)
    );

    assign out_ereg.dataD_nxt.signed_imm={{52{dataF.raw_instr[31]}},dataF.raw_instr[31:20]};
    assign out_ereg.dataD_nxt.srca=rd1;
    assign out_ereg.dataD_nxt.srcb=rd2;
    assign out_ereg.dataD_nxt.ctl=ctl;
    assign out_ereg.dataD_nxt.dst=dataF.raw_instr[11:7];
    assign out_ereg.dataD_nxt.pc=dataF.pc;

    // assign dataD=out
    
endmodule

`endif 