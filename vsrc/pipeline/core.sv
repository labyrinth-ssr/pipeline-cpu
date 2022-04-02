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
`include "pipeline/hazard/hazard.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/pipereg.sv"
`include "pipeline/regfile/pcreg.sv"
`else
`include "include/interface.svh"
`endif

module core 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp
);
	/* TODO: Add your pipeline here. */

	u64 pc,pc_nxt;
	u32 raw_instr;
	pcreg pcreg(
		.clk,.reset,
		.pc,
		.pc_nxt
		// .enable(^hazard_intf.stallF),
		// .pc_nxt(pcselect_intf.pcreg),
		// .pc(pcreg_intf.pc)
	);
	// pcreg_intf pcreg_intf(.pc(pc));
	// dreg_intf dreg_intf();
	// ereg_intf ereg_intf();
	// mreg_intf mreg_intf();
	// wreg_intf wreg_intf();
	// pcselect_intf pcselect_intf(.pcplus4(pc+4));
	// regfile_intf regfile_intf();
	assign ireq.addr=pc;
	assign ireq.valid=1'b1;
	assign raw_instr=iresp.data;
	fetch_data_t dataF,dataF_nxt;
	decode_data_t dataD,dataD_nxt;
	execute_data_t dataE,dataE_nxt;
	memory_data_t dataM,dataM_nxt;
	writeback_data_t dataW,dataW_nxt;

	u64 pc_selected,pc_branch;
	u1 pc_branch;
	pcselect pcselect(
		.pcplus4(pc+4),
		.pc_selected,
		.pc_branch,
		.branch_taken
		// .self(pcselect_intf.pcselect)
		// .in(pcreg_intf.pcselect),
		// .pc_selected(pcselect_intf.fetch)
	);
	fetch fetch(
		.raw_instr,
		.pc(pc),
		.dataF(dataF_nxt)
		// .enable(^hazard_intf.stallD)
	);
	//self(let the )
	pipereg #(.T(fetch_data_t)) dreg(
		.clk,.reset,
		.in(dataF_nxt),
		.out(dataF)
		// .hazard(hazard_intf.dreg)
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
	word_t rd1,rd2;
	decode decode(
		.dataF(dataF),
		.dataD(dataD_nxt),
		// .decode_reg(regfile_intf.decode)
		// .out_ereg(ereg_intf.decode),
		.ra1,.ra2,.rd1,.rd2
	);
	// word_t result;
	// assign result=rd1+{{52{raw_instr[31]}},raw_instr[31:20]};//52+12=64
	// assign dataD.ctl.re
	regfile regfile(
		.clk, .reset,
		// .self(regfile_intf.regfile)
		.ra1,
		.ra2,
		.rd1,//取出的数据
		.rd2,
		.wvalid(dataW.ctl.regWrite),
		.wa(dataW.wa),
		.wd(dataW.wd)
	);

	pipereg #(.T(decode_data_t)) ereg(
		.clk,.reset,
		.in(dataD_nxt),
		.out(dataD)
	);

	execute execute(
		.dataD(dataD),
		.dataE(dataE_nxt)
	);

	pipereg #(.T(execute_data_t)) mreg(
		.clk,.reset,
		.in(dataE_nxt),
		.out(dataE)
	);

	mread_req mread;
	mwrite_req mwrite;
	// u64 imin,inmax;
	// u64 dmin,dmax;
	
	memory memory(
		.dataE(dataE),
		.dataM(dataM_nxt)
	);
	// assign wreg_intf.dataM_nxt.rd=dresp.data;
	always_comb begin
        dreq = '0;
        unique case (dataE.ctl.MemRW)
            2'b01: begin
                dreq.valid = '1;
                dreq.strobe = '0;
                dreq.addr = dataE.alu;
            end
            2'b10: begin
                dreq.valid = '1;
                dreq.strobe = '1;
                dreq.addr = dataE.alu;
                dreq.data = dataE.rs2;
            end
            default: begin
            end
        endcase
    end
	assign dataM_nxt.rd=dresp.data;

	pipereg #(.T(writeback_data_t)) wreg(
		.clk,.reset,
		.in(dataW),
		.out(dataW_nxt)
	);

	writeback writeback (
		.in(dataW_nxt),
		.out(dataW)
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