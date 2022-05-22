`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
//`include "include/interface.svh"
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
`include "pipeline/hazard/hazard.sv"
`include "pipeline/mux/mux2.sv"

`else
//`include "include/interface.svh"
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
	u1 stallF,stallD,flushD,flushE,flushM,flushW,stallM,stallE;
	u2 forwardaD,forwardbD,forwardaE,forwardbE;
	u1 i_wait,d_wait,e_wait;
    creg_addr_t edst,mdst,wdst;
	assign edst=dataE_nxt.dst;
	assign mdst=dataM_nxt.dst;
	assign wdst=dataW.wa;
    // u1 ebranch;
	// assign ebranch=dataE_nxt.ctl.pcSrc;
    creg_addr_t ra1,ra2;
    u1 wrE,wrM,wrW;
	assign wrE=dataE_nxt.ctl.regWrite;
	assign wrM=dataM_nxt.ctl.regWrite;
	assign wrW=dataW.ctl.regWrite;
	assign i_wait=ireq.valid && ~iresp.data_ok;
	assign d_wait=dreq.valid && ~dresp.data_ok;
	hazard hazard(
		.stallF,.stallD,.flushD,.flushE,.flushM,.edst,.mdst,.wdst,.ra1,.ra2,.wrE,.wrM,.wrW,.i_wait,.d_wait,.stallM,.stallE,.flushW,.memwrE(dataD.ctl.wbSelect==2'b1),.memwrM(dataE.ctl.wbSelect==2'b1),.forwardaE,.forwardbE,.forwardaD,.forwardbD,.dbranch(dataD_nxt.pcSrc),.dbranch2(dataD_nxt.ctl.branch!='0),.ra1E(dataD.ra1),.ra2E(dataD.ra2),.e_wait,.multialud(dataD_nxt.ctl.alufunc==MUL||dataD_nxt.ctl.alufunc==DIV||dataD_nxt.ctl.alufunc==REM),.multialuM(dataM_nxt.ctl.alufunc==MUL||dataM_nxt.ctl.alufunc==DIV||dataM_nxt.ctl.alufunc==REM),.multialuE(dataE_nxt.ctl.alufunc==MUL||dataE_nxt.ctl.alufunc==DIV||dataE_nxt.ctl.alufunc==REM)
	);
	pcreg pcreg(
		.clk,.reset,
		.pc,
		.pc_nxt,
		.en(~(stallF)),
		.flush('0)
	);
	assign ireq.addr=pc;
	assign ireq.valid=1'b1;

	assign raw_instr=iresp.data;
	fetch_data_t dataF,dataF_nxt;
	decode_data_t dataD,dataD_nxt;
	execute_data_t dataE,dataE_nxt;
	memory_data_t dataM,dataM_nxt;
	writeback_data_t dataW;
	u64 pc_save;
	u32 raw_instr_save;
	u1 fetched;
	u1 de_wait;
	assign de_wait=e_wait|d_wait;

	always_ff @(posedge clk ) begin
		if (de_wait&&iresp.data_ok) begin
			pc_save<=pc;
			raw_instr_save<=raw_instr;
			fetched<='1;
		end else if (~de_wait) begin
			{pc_save,raw_instr_save,fetched}<='0;
		end
	end

	always_ff @(posedge clk ) begin
		// $display("%x %d %d %d",pc,i_wait,d_wait,stallF);
	end

	pcselect pcselect(
		.pcplus4(pc+4),
		.pc_selected(pc_nxt),
		.pc_branch(dataD_nxt.target),
		.branch_taken(dataD_nxt.pcSrc)
	);

	fetch fetch(
		.raw_instr(fetched&&~de_wait ?raw_instr_save:raw_instr),
		.pc(fetched&&~de_wait?pc_save:pc),
		.dataF(dataF_nxt)
	);

	pipereg #(.T(fetch_data_t)) dreg(
		.clk,.reset,
		.in(dataF_nxt),
		.out(dataF),
		.en(~stallD),
		.flush(flushD)
	);
	word_t rd1,rd2;
	decode decode(
		.dataF(dataF),
		.dataD(dataD_nxt),
		.ra1,.ra2,.rd1,.rd2,
		.aluoutM,.forwardaD,.forwardbD,.resultW(dataW.wd)
	);
	u64 aluoutM;
    always_comb begin
        aluoutM='0;
        unique case(dataM_nxt.ctl.wbSelect)
            2'b00:aluoutM=dataM_nxt.alu_out;
            2'b01:aluoutM=dataM_nxt.rd;
            2'b10:aluoutM=dataM_nxt.pc+4;
            2'b11:aluoutM=dataM_nxt.sextimm;
            default:begin end
    endcase
    end

	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,//取出的数�?
		.rd2,
		.wvalid(dataW.ctl.regWrite),
		.wa(dataW.wa/* 5'h0) */),
		.wd(dataW.wd)
	);
	pipereg #(.T(decode_data_t)) ereg(
		.clk,.reset,
		.in(dataD_nxt),
		.out(dataD),
		.en(~(stallE)),
		.flush(flushE)
	);
	execute execute(
		.clk,.reset,
		.dataD(dataD),
		.dataE(dataE_nxt),
		.forwardaE,.forwardbE,
		.aluoutM,.resultW(dataW.wd),.e_wait
	);
	assign stallM = dreq.valid && ~dresp.data_ok;
	assign flushW = dreq.valid && ~dresp.data_ok;

	pipereg #(.T(execute_data_t)) mreg(
		.clk,.reset,
		.in(dataE_nxt),
		.out(dataE),
		.en(~stallM),
		.flush(flushM)
	);
	memory memory(
		.dataE(dataE),
		.dataM(dataM_nxt),
		.dresp,
		.dreq
	);
	pipereg #(.T(memory_data_t)) wreg(
		.clk,.reset,
		.in(dataM_nxt),
		.out(dataM),
		.en(1),
		.flush(flushW)
	);

	writeback writeback (
		.dataM(dataM),
		.dataW(dataW)
	);
`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid),
		.pc                 (dataW.pc),
		.instr              (raw_instr),
		.skip               (dataW.ctl.memRw!=2'b00&& (dataW.alu_out[31]==0)),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.ctl.regWrite),
		.wdest              ({3'b0,dataW.wa}),
		.wdata              (dataW.wd)
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