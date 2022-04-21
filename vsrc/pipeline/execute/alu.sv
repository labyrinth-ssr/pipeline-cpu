`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
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
	always_comb begin
		c = '0;
		unique case(alufunc)
			ADD: c = a + b;
			SUB: c = a - b;
			OR: c = a | b;
			AND: c = a & b;
			XOR: c = a ^ b;
			LS: c= a<<b[5:0];
			RS: c= a>>b[5:0];
			SLS:$signed(a) <<< b[5:0];
			SRS:$signed(a) >>> b[5:0];
			default: begin
			end
		endcase
	end
	
endmodule

`endif
