`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module writeback(
    input memory_data_t dataM,
    output writeback_data_t dataW
);
    assign dataW.alu_out=dataM.alu_out;
    assign dataW.pc=dataM.pc;
    assign dataW.sextimm=dataM.sextimm;
    assign dataW.ctl=dataM.ctl;
    assign dataW.wd=dataM.rd;

    always_comb begin
        dataW.wa='0;
        unique case(dataM.ctl.wbSelect)
            2'b00:dataW.wa=dataM.alu_out;
            2'b01:dataW.wa=dataM.rd;
            2'b10:dataW.wa=dataM.pc+4;
            2'b11:dataW.wa=dataM.sextimm;
    end
    
endmodule

`endif 