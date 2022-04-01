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
        // output creg_addr_t ra1,ra2,
        regfile_intf.decode decode_reg
);
    control_t ctl;
    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl(ctl)
    );
    
    always_ff @(posedge clk) begin
        if (jump) instr <= '0; // Warn: this is an invalid instruction
        else instr <= instr_nxt;
    end
    assign dataD.imm=dataF.raw_instr[31:12];
    assign dataD.srca=decode_reg.rd1;
    assign dataD.srcb=decode_reg.rd2;
    assign dataD.ctl=ctl;
    assign dataD.rd=dataF.raw_instr[11:7];
    assign dataD.rs2=dataF.raw_instr[24:20];
    assign dataD.pc=dataF.pc;

    assign decode_reg.ra1=dataF.raw_instr[24:20];
    assign decode_reg.ra2=dataF.raw_instr[19:15];
    
endmodule

`endif 