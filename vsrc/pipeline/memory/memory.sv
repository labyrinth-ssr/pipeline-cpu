`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/writedata.sv"
`endif 

module memory
    import common::*;
	import pipes::*;(
    input execute_data_t dataE,
    output execute_data_t dataE_post,
    output dbus_req_t  dreq,
    input u1 exception
);
u64 wd;
u8 strobe;
u1 store_misalign;
    always_comb begin
        dreq = '0;
        // dataE_post.rd='0;
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
    end
writedata writedata(.addr(dataE.alu_out[2:0]),._wd(dataE.srcb),.msize(dataE.ctl.msize),.wd(wd),.strobe(strobe),.store_misalign);

    always_comb begin
        dataE_post.csr_ctl=dataE.csr_ctl;
        if (dataE.ctl.memRw==2'b10&& store_misalign) begin
            dataE_post.csr_ctl.ctype=EXCEPTION;
            dataE_post.csr_ctl.code=4'h6;
        end
    end

    assign dataE_post.pc=dataE.pc;
    assign dataE_post.dst=dataE.dst;
    assign dataE_post.sextimm=dataE.sextimm;
    assign dataE_post.ctl=dataE.ctl;
    assign dataE_post.alu_out=dataE.alu_out;
    assign dataE_post.int_type=dataE.int_type;
    assign dataE_post.valid=dataE.valid;

endmodule

`endif 