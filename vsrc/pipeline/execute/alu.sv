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
			SLS:c=$signed(a) <<< b[5:0];
			SRS:c=$signed(a) >>> b[5:0];
			CMP:c=a<b;
			SCMP:c= $signed(a) < $signed(b);
			RSW:c=$signed(a[31:0] >> b[5:0]);
			SRSW:c=$signed($signed(a[31:0]) >>> b[5:0]);
			
			SLLW:c= a<<b[4:0];
			SRLW:c=$signed(a[31:0] >> b[4:0]);
			SRAW:$signed($signed(a[31:0]) >>> b[4:0]);

			default: begin
			end
		endcase
	end
	
endmodule

`endif
