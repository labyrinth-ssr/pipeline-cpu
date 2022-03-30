`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module writeback(
    wreg_intf.writeback in,//dataM
    output writeback_data_t out,//dataW
    regfile_intf.writeback wr_reg_data
);
    assign wr_reg_data.wa=in.dst;
    always_comb begin
        wr_reg_data.wvalid='0
        unique case(in.op)
            LD:wr_reg_data.wvalid='1
    end
    
endmodule

`endif 