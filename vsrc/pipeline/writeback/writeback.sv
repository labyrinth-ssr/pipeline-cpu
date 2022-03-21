`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module writeback(
    wreg_intf.writeback in,
    output u64 out
);
    assign out=in.dataM;

    
endmodule

`endif 