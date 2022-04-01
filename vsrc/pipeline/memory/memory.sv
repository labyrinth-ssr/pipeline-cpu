`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module memory(
    mreg_intf.memory in,
    wreg_intf.memory out
);
    // assign out.dataM_nxt=in.dataE.alu_out;
    assign out.dst=in.dst;
    assign out.ra=in.alu_out;
    
endmodule

`endif 