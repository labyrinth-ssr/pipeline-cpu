`ifndef __FETCH_SV
`define __FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`endif 

module fetch 
    import common::*;
    import pipes::*;(
    output fetch_data_t dataF,
    input u32 raw_instr,
    input u64 pc,
    input u1 exception,trint,swint,exint
);

    assign dataF.raw_instr=exception? '0:raw_instr;
    assign dataF.pc=pc;
    assign dataF.valid='1;
    assign dataF.csr_ctl.ctype=exception? EXCEPTION:NONE;
    assign dataF.csr_ctl.code=exception? 4'h0:'0;
    assign dataF.int_type.trint=trint;
    assign dataF.int_type.swint=swint;
    assign dataF.int_type.exint=exint;


endmodule

`endif 