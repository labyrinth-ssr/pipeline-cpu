`ifndef __PCSELECT_SV
`define __PCSELECT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
// `include "include/pipes.sv"
`else
`endif

module pcselect
    import common::*;
    (
    // input u64 pcplus4,//a pc command
    // output u64 pc_selected
    // pcreg_intf.pcselect in,
    // pcselect_intf.fetch pc_selected
    pcselect_intf.pcselect self
);

    assign self.pcplus4=self.pc+4;
    
endmodule


`endif 