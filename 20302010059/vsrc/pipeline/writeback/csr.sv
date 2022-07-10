`ifndef __CSR_SV
`define __CSR_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/writeback/csr_pkg.sv"
`else
`endif

module csr
	import common::*;
	import csr_pkg::*;(
	input logic clk, reset,
	input u12 ra,wa,
	input u64 wd,
	output u64 rd,mepc,mtvec,
	input u1 valid,is_mret,
	output csr_regs_t regs_out,
	input u64 pc,
	input u4 code,
	input u2 mode,
	input csr_type_t ctype,
	input u1 trint,swint,exint,
	output u1 interrupt,
	input u1 inter_valid,
	output u1 delayed_interupt
);
	csr_regs_t regs, regs_nxt;
	assign regs_out=regs_nxt;
	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
		end else begin
			regs <= regs_nxt;
		end
	end
	u4 inter_code;
	always_comb begin
		if (trint) begin
			inter_code=4'h7;
		end else if (swint) begin
			inter_code=4'h3;
		end else if (exint) begin
			inter_code=4'hb;
		end
	end
	// read
	always_comb begin
		rd = '0;
		unique case(ra)
			CSR_MIE: rd = regs.mie;
			CSR_MIP: rd = regs.mip;
			CSR_MTVEC: rd = regs.mtvec;
			CSR_MSTATUS: rd = regs.mstatus;
			CSR_MSCRATCH: rd = regs.mscratch;
			CSR_MEPC: rd = regs.mepc;
			CSR_MCAUSE: rd = regs.mcause;
			CSR_MCYCLE: rd = regs.mcycle;
			CSR_MTVAL: rd = regs.mtval;
			default: begin
				rd = '0;
			end
		endcase
	end

	typedef struct packed {
		u64 pc;
		u4 inter_code;
		u1 mie;
		u2 mode;
		u1 trint;
		u1 swint;
		u1 exint;
	} int_save_t;
	int_save_t int_save;
	u1 int_saved;
	// write

	always_ff @(posedge clk) begin
		if (interrupt&&~inter_valid&&~int_saved) begin
			int_save.pc<=pc;
			int_save.inter_code<=inter_code;
			int_save.mie<=regs_nxt.mstatus.mie;
			int_save.mode<=mode;
			int_save.trint<=trint;
			int_save.swint<=swint;
			int_save.exint<=exint;
			int_saved<='1;
		end else if (inter_valid) begin
			int_save<='0;
			int_saved<='0;
		end
	end

	always_comb begin
		regs_nxt = regs;
		regs_nxt.mcycle = regs.mcycle + 1;
		interrupt=((trint&&regs_nxt.mie[7])||(swint&&regs_nxt.mie[3])||(exint&&regs_nxt.mie[11]))&&regs_nxt.mstatus.mie;
		delayed_interupt='0;
		if (ctype==EXCEPTION||(interrupt&&inter_valid&&~int_saved)) begin
					regs_nxt.mepc=pc;
					regs_nxt.mcause[63]= interrupt?1:0;
					regs_nxt.mcause [62:0]= interrupt? {59'b0,inter_code}:{59'b0,code};
					regs_nxt.mstatus.mpie = regs_nxt.mstatus.mie ;
					regs_nxt.mstatus.mie = 0;
					regs_nxt.mstatus.mpp = mode;
					regs_nxt.mip[7]=trint;
					regs_nxt.mip[3]=swint;
					regs_nxt.mip[11]=exint;
		end  else if (int_saved&&inter_valid) begin
					regs_nxt.mepc= int_save.pc;
					regs_nxt.mcause[63]= 1;
					regs_nxt.mcause [62:0]= {59'b0,int_save.inter_code};
					regs_nxt.mstatus.mpie = int_save.mie;
					regs_nxt.mstatus.mie = 0;
					regs_nxt.mstatus.mpp = int_save.mode;
					regs_nxt.mip[7]=int_save.trint;
					regs_nxt.mip[3]=int_save.swint;
					regs_nxt.mip[11]=int_save.exint;
					delayed_interupt='1;
				end
				 else if (valid) begin
			unique case(wa)
				CSR_MIE: regs_nxt.mie = wd;
				CSR_MIP:  regs_nxt.mip = wd;
				CSR_MTVEC: regs_nxt.mtvec = wd;
				CSR_MSTATUS: regs_nxt.mstatus = wd;
				CSR_MSCRATCH: regs_nxt.mscratch = wd;
				CSR_MEPC: regs_nxt.mepc = wd;
				CSR_MCAUSE: regs_nxt.mcause = wd;
				CSR_MCYCLE: regs_nxt.mcycle = wd;
				CSR_MTVAL: regs_nxt.mtval = wd;
				default: begin
				end
			endcase
			regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
		end else if (is_mret) begin
			regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
			regs_nxt.mstatus.xs = 0;
		end 
		else begin end
	end
	assign mepc = regs.mepc;
	assign mtvec=regs.mtvec;
	
endmodule

`endif