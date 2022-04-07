`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
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
				dataM.rd=dresp.data;
            end
            2'b10: begin//write
                dreq.valid = '1;
                dreq.strobe = '1;
                dreq.addr = dataE.alu_out;
                dreq.data = dataE.srcb;
            end
            default: begin
            end
        endcase
        dataM.ctl=dataE.ctl;
        if (dataE.ctl.branch&&(dataE.alu_out==0)) begin
                dataM.ctl.pcSrc=1'b1;
            end
    end

        
    assign dataM.pc=dataE.pc;

    assign dataM.dst=dataE.dst;
    assign dataM.sextimm=dataE.sextimm;
    assign dataM.target=dataE.target;

    assign dataM.alu_out=dataE.alu_out;
    assign dataM.valid=dataE.valid;

endmodule

`endif 