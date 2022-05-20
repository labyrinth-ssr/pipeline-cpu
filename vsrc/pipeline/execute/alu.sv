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
	input clk,reset,
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c,
	input u1 sign,cut,
	output u1 e_wait

);
	u32 shift;
	u64 norm_c,mul_c;
	u128 div_c;
	u1 done_mul,done_div;
	u1 zero;
	assign zero=~|b;
	// always_ff @( posedge clk ) begin
	// 	if () begin
	// 		pass
	// 	end
	// 	zero<=~|b;
	// end
	always_comb begin
		norm_c= '0;shift='0;
		unique case(alufunc)
			ADD: norm_c= a + b;
			SUB: norm_c= a - b;
			OR: norm_c= a | b;
			AND: norm_c= a & b;
			XOR: norm_c= a ^ b;
			LS: norm_c= a<<b[5:0];
			RS: norm_c= a>>b[5:0];
			SLS:norm_c=$signed(a) <<< b[5:0];
			SRS:norm_c=$signed(a) >>> b[5:0];
			CMP:norm_c={63'b0,(a<b)};
			SCMP:norm_c= {63'b0,$signed(a) < $signed(b)};
			RSW:begin
				shift=a[31:0] >> b[5:0];
				norm_c={{32{shift[31]}},shift};
			end 
			SRSW:norm_c={{32{a[31]}},$signed(a[31:0]) >>> b[5:0]};
			SLLW:norm_c= a<<b[4:0];
			SRLW: begin 
				shift=a[31:0] >> b[4:0];
				norm_c={{32{shift[31]}},shift};
			end
			SRAW:norm_c={{32{a[31]}},$signed(a[31:0]) >>> b[4:0]};
			default: begin
			end

		endcase
	end
	// assign c=alufunc==MUL||alufunc==DIV||alufunc==REM?muldi
	u64 res;
	always_comb begin
		c='0;res='0;
		unique case (alufunc)
			MUL: c= ~cut?mul_c:{{32{mul_c[31]}},mul_c[31:0]};
			DIV:begin
				if(zero) begin
					c='1;
				end
				else begin
					if ($signed(a)>=0&&$signed(b)<0&&sign) begin
						res=-(div_c[63:0]);
					end else if ($signed(a)<0&&$signed(b)>=0&&sign) begin
						res=-(div_c[63:0]+1);
					end else if ($signed(a)<0&&$signed(b)<0&&sign) begin
						res=(div_c[63:0]+1);
					end else begin
						res= div_c[63:0];
					end
					c=~cut?res:{{32{res[31]}},res[31:0]};
				end
			end 
			REM:if(zero) begin
					c=a;
				end
				else begin
					if ($signed(a)<0&&$signed(b)>=0&&sign) begin
						res=b -div_c[127:64];
					end else if ($signed(a)<0&&$signed(b)<0&&sign) begin
						res=-b - div_c[127:64];
					end else begin
						res= div_c[127:64];
					end
					c=~cut?res:{{32{res[31]}},res[31:0]};
				end
			default: c=norm_c;
		endcase
	end

	multiplier_multicycle_from_single mul (
		.clk,.reset,.valid(alufunc==MUL),
		.a,.b,.c(mul_c),.done(done_mul)
		);
	divider_multicycle_from_single div(
		.clk,.reset,.valid(alufunc==DIV||alufunc==REM),
		.a(sign&&$signed(a)<0?-a:a),.b(sign&&$signed(b)<0?-b:b),.c(div_c),.done(done_div)
	);

	assign e_wait=(alufunc==MUL&&~done_mul)||(alufunc==DIV&&~done_div)||(alufunc==REM&&~done_div);
endmodule

`endif
