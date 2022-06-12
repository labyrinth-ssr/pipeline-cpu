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
    input  dbus_resp_t dresp,
    input u1 exception
);
u64 wd;
u8 strobe;
u1 load_misalign,store_misalign;
    always_comb begin
        dreq = '0;
        // dataM.rd='0;
        unique case (dataE.ctl.memRw)
            2'b01: begin//read
                dreq.valid = exception? '0: '1;
                dreq.strobe = '0;
                dreq.addr = dataE.alu_out;
                dreq.size=dataE.ctl.msize;
            end
            2'b10: begin//write
                dreq.valid =  exception? '0:'1;
                dreq.addr = dataE.alu_out;
                dreq.data=wd;
                dreq.strobe=strobe;
                dreq.size=dataE.ctl.msize;
            end
            default: begin
            end
        endcase
        dataM.ctl=dataE.ctl;
    end
readdata readdata(._rd(dresp.data),.rd(dataM.rd),.addr(dataE.alu_out[2:0]),.msize(dataE.ctl.msize),.mem_unsigned(dataE.ctl.mem_unsigned),.load_misalign);
writedata writedata(.addr(dataE.alu_out[2:0]),._wd(dataE.srcb),.msize(dataE.ctl.msize),.wd(wd),.strobe(strobe),.store_misalign);

    always_comb begin
        dataM.csr_ctl=dataE.csr_ctl;
        if (dataE.ctl.memRw==2'b01&& load_misalign) begin
            dataM.csr_ctl.code=4'h4;
            dataM.csr_ctl.ctype=EXCEPTION;
        end
        else if (dataE.ctl.memRw==2'b10&& store_misalign) begin
            dataM.csr_ctl.ctype=EXCEPTION;
            dataM.csr_ctl.code=4'h6;
        end
    end

    assign dataM.pc=dataE.pc;
    assign dataM.dst=dataE.dst;
    assign dataM.sextimm=dataE.sextimm;
    // assign dataM.target=dataE.target;

    assign dataM.alu_out=dataE.alu_out;
    assign dataM.int_type=dataE.int_type;
    assign dataM.valid=dataE.valid;

endmodule

`endif 