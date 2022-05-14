`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu/div.sv"
`include "pipeline/execute/alu/multi.sv"
`include "pipeline/execute/alu/hilo.sv"

`else

`endif

module alu
	import common::*;
	import pipes::*;(
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c
	// output alu_zero
);
	u32 shift;
	always_comb begin
		c = '0;shift='0;
		unique case(alufunc)
			ADD: c = a + b;
			SUB: c = a - b;
			OR: c = a | b;
			AND: c = a & b;
			XOR: c = a ^ b;
			LS: c= a<<b[5:0];
			RS: c= a>>b[5:0];
			SLS:c=$signed(a) <<< b[5:0];
			SRS:c=$signed(a) >>> b[5:0];
			CMP:c={63'b0,(a<b)};
			SCMP:c= {63'b0,$signed(a) < $signed(b)};
			RSW:begin
				shift=a[31:0] >> b[5:0];
				c={{32{shift[31]}},shift};
			end 
			SRSW:c={{32{a[31]}},$signed(a[31:0]) >>> b[5:0]};
			SLLW:c= a<<b[4:0];
			SRLW: begin 
				shift=a[31:0] >> b[4:0];
				c={{32{shift[31]}},shift};
			end
			SRAW:c={{32{a[31]}},$signed(a[31:0]) >>> b[4:0]};
			default: begin
			end

		endcase
	end
	
endmodule

`endif
