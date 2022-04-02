`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module memory(
    input execute_data_t dataE.,
    output memory_data_t dataM
);
    assign dataM.pc=dataE.pc;
    assign dataM.dst=dataE.dst;
    assign dataM.sextimm=dataE.sextimm;
    assign dataM.alu_out=dataE.alu_out;
    assign dataM.ctl=dataE.ctl;

endmodule

`endif 