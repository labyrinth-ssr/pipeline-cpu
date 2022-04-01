`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"
// `include "pipeline/forward/forward.sv"
// `include "pipeline/hazard/hazard.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/pipereg.sv"
`include "pipeline/regfile/pcreg.sv"

// `include "pipeline/csr/csr.sv"

`else
`include "include/interface.svh"
`endif

module core 
	import common::*;
	// import fetch_pkg::*;
	// import decode_pkg::*;
	// import execute_pkg::*;
	// import memory_pkg::*;
	// import writeback_pkg::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp
);
	/* TODO: Add your pipeline here. */

	u64 pc;
	
	pcreg_intf pcreg_intf(.pc(pc));
	dreg_intf dreg_intf();
	ereg_intf ereg_intf();
	mreg_intf mreg_intf();
	wreg_intf wreg_intf();
	pcselect_intf pcselect_intf(.pcplus4(pc+4));
	regfile_intf regfile_intf();
	// u64 imin,inmax;
	// u64 dmin,dmax;
	assign ireq.addr=pcreg_intf.pc;
	assign ireq.valid=1'b1;
	u32 raw_instr;
	assign raw_instr=iresp.data;

	fetch_data_t dataF;
	decode_data_t dataD;
	execute_data_t dataE;
	memory_data_t dataM;

	pcreg pcreg(
		.clk,.reset,
		.self(pcreg_intf.pcreg)
		// .pc_nxt(pcselect_intf.pcreg),
		// .pc(pcreg_intf.pc)
	);

	pcselect pcselect(
		// .pcplus4(pc+4),
		// .pc_selected(pcreg_intf)
		.self(pcselect_intf.pcselect)
		// .in(pcreg_intf.pcselect),
		// .pc_selected(pcselect_intf.fetch)
	);

	fetch fetch(
		.raw_instr,
		.pc(pc+4),
		.dataF(dreg_intf.fetch)
	);

	pipereg #(.T(fetch_data_t)) dreg(
		.clk,.reset,
		.in(dreg_intf.dataF_nxt),
		.out(dreg_intf.dataF)
	);

	// always_ff @( posedge clk ) begin
	// 	if (reset) begin
	// 		pc<=64'h8000_0000;//
	// 	end else begin
	// 		pc<=pc_nxt;
	// 	end
	// end

	// fetch fetch(
	// 	// .dataF(dataF),
	// 	.pc(ireq.addr),
	// 	.raw_instr(raw_instr),
	// 	.pcselect(pcselect_intf.fetch)
	// 	.pcreg(pcreg_intf.fetch)
	// 	.dreg(dreg_intf.fetch)
	// );

	// decode decode(
	// 	.clk,.reset,
	// 	// .pcselect(pcselect_intf.decode),
	// 	.dreg(dreg_intf.decode),
	// 	.ereg(ereg_intf,.decode),
	// 	.forward(forward_intf.decode),
	// 	.hazard(hazard_intf.decode),
	// 	regfile(regfile_intf.decode),
	// 	csr(csr_intf.decode)
	// )
	
	creg_addr_t ra1,ra2;
	assign 
	word_t rd1,rd2;
	decode decode(
		.dataF(dreg_intf.decode),
		.dataD(ereg_intf.decode),
		.decode_reg(regfile_intf.decode)
		// .out_ereg(ereg_intf.decode),
		// .ra1,.ra2,.rd1,.rd2
	);

	// word_t result;
	assign result=rd1+{{52{raw_instr[31]}},raw_instr[31:20]};//52+12=64
	// assign dataD.ctl.re
	regfile regfile(
		.clk, .reset,
		.self(regfile_intf.regfile)
		// .ra1,
		// .ra2,
		// .rd1,//取出的数据
		// .rd2,
		// .wvalid(ereg_intf.dataD_nxt.ctl.regWrite),
		// .wa(ereg_intf.dataD_nxt.dst),
		// .wd(result)
	);

	pipereg #(.T(decode_data_t)) ereg(
		.clk,.reset,
		.in(ereg_intf.dataD_nxt),
		.out(ereg_intf.dataD)
	);

	execute execute(
		.clk,
		.ereg_in(ereg_intf.execute),
		.out_mreg(mreg_intf.execute)
	);

	pipereg #(.T(execute_data_t)) mreg(
		.clk,.reset,
		.in(mreg_intf.dataE_nxt),
		.out(mreg_intf.dataE)
	);

	mread_req mread;
	mwrite_req mwrite;
	u64 imin,inmax;
	u64 dmin,dmax;
	
	memory memory(
		.in(mreg_intf.memory),
		.out(wreg_intf.memory)
	);
	assign mread.addr=wreg_intf.dataM_nxt.ra;
	// assign wreg_intf.dataM_nxt.rd=dresp.data;
	always_ff @(posedge clk) begin
		if (reset) begin
			dmin<=64'h8010_0000;
			dmax<=64'h8000_0000;
		end else begin
			if (dreq.addr[31:28]==4'd8 && dreq.valid) begin
				wreg_intf.dataM_nxt.rd=dresp.data;
			end
		end
	end

	pipereg #(.T(u64)) wreg(
		.clk,.reset,
		.in(wreg_intf.dataM_nxt),
		.out(wreg_intf.dataM)
	);

	writeback writeback (
		.in(wreg_intf.writeback),
		.out(regfile_intf.writeback)
	);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (~reset),
		.pc                 (pcreg_intf.pc),
		.instr              (0),
		.skip               (0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataD.ctl.regWrite),
		.wdest              ({3'b0,dataD.dst}),
		.wdata              (result)
	);
	      
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	      
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	      );
	      
	DifftestArchFpRegState DifftestArchFpRegState(
		.clock              (clk),
		.coreid             (0),
		.fpr_0              (0),
		.fpr_1              (0),
		.fpr_2              (0),
		.fpr_3              (0),
		.fpr_4              (0),
		.fpr_5              (0),
		.fpr_6              (0),
		.fpr_7              (0),
		.fpr_8              (0),
		.fpr_9              (0),
		.fpr_10             (0),
		.fpr_11             (0),
		.fpr_12             (0),
		.fpr_13             (0),
		.fpr_14             (0),
		.fpr_15             (0),
		.fpr_16             (0),
		.fpr_17             (0),
		.fpr_18             (0),
		.fpr_19             (0),
		.fpr_20             (0),
		.fpr_21             (0),
		.fpr_22             (0),
		.fpr_23             (0),
		.fpr_24             (0),
		.fpr_25             (0),
		.fpr_26             (0),
		.fpr_27             (0),
		.fpr_28             (0),
		.fpr_29             (0),
		.fpr_30             (0),
		.fpr_31             (0)
	);
	
`endif
endmodule
`endif