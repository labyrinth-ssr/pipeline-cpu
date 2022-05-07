`ifndef __SEXT_SV
`define __SEXT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module sext
	import common::*;
	import pipes::*;(
	input decoded_op_t op,
    input u32 raw_instr,
    output u64 sextimm
);
	always_comb begin
    sextimm='0;
    unique case (op)
        ITYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[31:20]};
        end
        UTYPE: begin
            sextimm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b0};
        end
        STYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[31:25], raw_instr[11:7]};
        end
        BTYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};
        end
        JTYPE: begin
            sextimm = {{44{raw_instr[31]}}, raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
        end
        default:begin
            sextimm='0;
        end
    endcase

end
	
endmodule

`endif
