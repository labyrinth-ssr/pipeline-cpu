`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module writeback
import common::*;
	import pipes::*;(
    input memory_data_t dataM,
    output writeback_data_t dataW
);
    assign dataW.alu_out=dataM.alu_out;
    assign dataW.pc=dataM.pc;
    assign dataW.sextimm=dataM.sextimm;
    assign dataW.ctl=dataM.ctl;
    assign dataW.wa=dataM.dst;
    assign dataW.valid=dataM.valid;

    always_comb begin
        dataW.wd='0;
        unique case(dataM.ctl.wbSelect)
            2'b00:dataW.wd=dataM.alu_out;
            2'b01:dataW.wd=dataM.rd;
            2'b10:dataW.wd=dataM.pc+4;
            2'b11:dataW.wd=dataM.sextimm;
            default:begin end
    endcase
    end
    
endmodule

`endif 