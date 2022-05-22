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
	u1 done_mul,done_div1,done_div2,done_div;
	u1 zero;
	assign zero=~|b;
	always_comb begin
		if ((alufunc==DIV||alufunc==REM)&&cut) begin
			done_div=done_div1;
		end else  begin
			done_div=done_div2;
		end
	end

	u64 areg,breg;
	// always_ff @(posedge clk) begin
    //     if((alufunc==DIV||alufunc==REM||alufunc==MUL)&&~e_wait) begin
    //         areg<=a;
    //         breg<=b;
    //     end else begin
    //         areg<=areg;
    //         breg<=breg;
    //     end
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
	u32 res32;
	u64 divc32;
	always_comb begin
		c='0;res='0;
		unique case (alufunc)
			MUL: c= ~cut?mul_c:{{32{mul_c[31]}},mul_c[31:0]};
			DIV:begin
				if(zero) begin
					c='1;
				end
				else begin
					if (cut) begin
					if ((($signed(aincw)>=0&&$signed(bincw)<0)||($signed(aincw)<0&&$signed(bincw)>0))&&sign) begin
						res32=-(divc32[31:0]);
					end else begin
						res32= divc32[31:0];
					end
					c={{32{res32[31]}},res32};
					end else begin
						if ((($signed(a)>=0&&$signed(b)<0)||($signed(a)<0&&$signed(b)>0))&&sign) begin
						res=-(div_c[63:0]);
					end else begin
						res= div_c[63:0];
					end
					c=res;
					end
					
				end
			end 
			REM:if(zero) begin
					c= cut?{{32{a[31]}},a[31:0]}:a;
				end
				else begin
					if (cut) begin
						if ($signed(aincw)<0&&sign) begin
						res32=-divc32[63:32];
					end else begin
						res32= divc32[63:32];
					end
					c={{32{res32[31]}},res32};
					end else begin
						if ($signed(a)<0&&sign) begin
						res=-div_c[127:64];
					end else begin
						res= div_c[127:64];
					end
					c=res;
					end
					
				end
			default: c=norm_c;
		endcase
	end

	multiplier_multicycle_from_single mul (
		.clk,.reset,.valid(alufunc==MUL),
		.a,.b,.c(mul_c),.done(done_mul)
		);
	
	divider_multicycle_from_single #(.WIDTH(32)) div32 (
		.clk,.reset,.valid((alufunc==DIV||alufunc==REM)&&cut),
		.a(sign&&$signed(aincw)<0?-aincw:aincw),.b(sign&&$signed(bincw)<0?-bincw:bincw),.c(divc32),.done(done_div1)
	);
	divider_multicycle_from_single #(.WIDTH(64)) div64 (
		.clk,.reset,.valid((alufunc==DIV||alufunc==REM)&&~cut),
		.a(sign&&$signed(a)<0?-a:a),.b(sign&&$signed(b)<0?-b:b),.c(div_c),.done(done_div2)
	);
	u32 ainc,binc;
	u32 aincw,bincw;
	assign aincw=a[31:0];
	assign bincw=b[31:0];

	// always_comb begin
	// 	{ainc,binc}='0;
	// 	if (cut) begin
	// 		ainc=a[31:0];
	// 		binc=b[31:0];
	// 	end 
	// end
	assign e_wait=(alufunc==MUL&&~done_mul)||(alufunc==DIV&&~done_div)||(alufunc==REM&&~done_div);
endmodule

`endif
