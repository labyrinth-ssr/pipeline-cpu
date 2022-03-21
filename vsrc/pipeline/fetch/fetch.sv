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
    // output fetch_data_t dataF,
    // input u32 raw_instr,
    // input u64 pc,
    // pcselect_intf.fetch pcselect,
    input u32 raw_instr,
    // pcreg_intf.fetch pcreg,
    pcselect_intf.fetch pc_selected,
    dreg_intf.fetch dreg
);

    // assign dataF.raw_instr=raw_instr;
    // assign dataF.pc=pc;
    assign dreg.dataF_nxt.pc=pc_selected.pcplus4;
    assign dreg.dataF_nxt.raw_instr=raw_instr;

    
endmodule


`endif 