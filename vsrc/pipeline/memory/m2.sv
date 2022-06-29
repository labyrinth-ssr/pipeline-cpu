`ifndef __M2_SV
`define __M2_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/readdata.sv"
`endif 

module m2
    import common::*;
	import pipes::*;(
    input execute_data_t dataE,
    output memory_data_t dataM,
    input  dbus_resp_t dresp
);
u64 wd;
u8 strobe;
u1 load_misalign;

assign dataM.ctl=dataE.ctl;

readdata readdata(._rd(dresp.data),.rd(dataM.rd),.addr(dataE.alu_out[2:0]),.msize(dataE.ctl.msize),.mem_unsigned(dataE.ctl.mem_unsigned),.load_misalign);

    always_comb begin
        dataM.csr_ctl=dataE.csr_ctl;
        if (dataE.ctl.memRw==2'b01&& load_misalign) begin
            dataM.csr_ctl.code=4'h4;
            dataM.csr_ctl.ctype=EXCEPTION;
        end
    end

    assign dataM.pc=dataE.pc;
    assign dataM.dst=dataE.dst;
    assign dataM.sextimm=dataE.sextimm;
    assign dataM.alu_out=dataE.alu_out;
    assign dataM.int_type=dataE.int_type;
    assign dataM.valid=dataE.valid;
    

endmodule

`endif 