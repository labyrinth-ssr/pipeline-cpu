`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/memory/readdata.sv"
`include "pipeline/memory/writedata.sv"
`endif 

module memory
import common::*;
	import pipes::*;(
    input execute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp
);

    always_comb begin
        dreq = '0;
        dataM.rd='0;
        unique case (dataE.ctl.memRw)
            2'b01: begin
                dreq.valid = '1;
                dreq.strobe = '0;
                dreq.addr = dataE.alu_out;
            end
            2'b10: begin//write
                dreq.valid = '1;
                dreq.addr = dataE.alu_out;
            end
            default: begin
            end
        endcase
        dataM.ctl=dataE.ctl;
    end
readdata readdata(._rd(dresp.data),.rd(dataM.rd),.addr(dataE.alu_out[2:0]),.msize(dataE.ctl.msize),.mem_unsigned(dataE.ctl.mem_unsigned));
writedata writedata(.addr(dataE.alu_out[2:0]),._wd(dataE.srcb),.msize(dataE.ctl.msize),.wd(dreq.data),.strobe(dreq.strobe));

    assign dataM.pc=dataE.pc;

    assign dataM.dst=dataE.dst;
    assign dataM.sextimm=dataE.sextimm;
    assign dataM.target=dataE.target;

    assign dataM.alu_out=dataE.alu_out;
    assign dataM.valid=dataE.valid;

endmodule

`endif 