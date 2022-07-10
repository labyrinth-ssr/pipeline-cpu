`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/memory/m2.sv"
`include "pipeline/writeback/writeback.sv"
`include "pipeline/hazard/hazard.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/pipereg.sv"
`include "pipeline/regfile/pcreg.sv"
`include "pipeline/writeback/csr_pkg.sv"
`include "pipeline/mux/mux2.sv"

`else

`endif

module core 
	import common::*;
	import csr_pkg::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);
	/* TODO: Add your pipeline here. */
	u64 pc,pc_nxt;
	u32 raw_instr;
	u2 mode_out;
	u1 stallF,stallD,flushD,flushE,flushM,flushW,stallM,stallE,flushM2,stallM2;
	u2 forwardaD,forwardbD,forwardaE,forwardbE;
	u1 i_wait,d_wait,e_wait,d_wait2;
	u12 csra;
	u1 is_mret,is_INTEXC;
    creg_addr_t edst,mdst,wdst,mdst2;
	assign edst=dataE_nxt.dst;
	assign mdst=dataE.dst;
	assign mdst2=dataE_second.dst;
	assign wdst=dataW.wa;
	u64 mepc,mtvec;
	u1 inter_valid;
	csr_regs_t regs_out;

    // u1 ebranch;
	// assign ebranch=dataE_nxt.ctl.pcSrc;
    creg_addr_t ra1,ra2;
    u1 wrE,wrM,wrW,wrM2;
	assign wrE=dataE_nxt.ctl.regWrite;
	assign wrM=dataE.ctl.regWrite;
	assign wrM2=dataE_second.ctl.regWrite;

	assign wrW=dataW.ctl.regWrite;
	assign i_wait=ireq.valid && ~iresp.data_ok;
	assign d_wait=dreq.valid && ((|dreq.strobe && ~dresp.data_ok) || (~(|dreq.strobe) && ~dresp.get_read && dreq.addr[31]!=0)) ;
	assign d_wait2=dreq.valid && ( (~(|dreq.strobe) && ~dresp.get_read && dreq.addr[31]==0)) ;

	hazard hazard(
		.stallF,.stallD,.flushD,.flushE,.flushM,.edst,.mdst,.mdst2,.wdst,.ra1,.ra2,.wrE,.wrM,.wrM2,.wrW,.i_wait,.d_wait,.d_wait2,.stallM,.stallM2,.stallE,.memwrE(dataD.ctl.wbSelect==2'b1),.memwrM(dataE.ctl.wbSelect==2'b1),.memwrM2(dataE_second.ctl.wbSelect==2'b1),.forwardaE,.forwardbE,.forwardaD,.forwardbD,.dbranch(dataD_nxt.pcSrc),.dbranch2(dataD_nxt.ctl.branch!='0),.ra1E(dataD.ra1),.ra2E(dataD.ra2),.e_wait,.multialud(dataD_nxt.ctl.alufunc==MUL||dataD_nxt.ctl.alufunc==DIV||dataD_nxt.ctl.alufunc==REM),.multialuM(dataE.ctl.alufunc==MUL||dataE.ctl.alufunc==DIV||dataE.ctl.alufunc==REM),.multialuE(dataE_nxt.ctl.alufunc==MUL||dataE_nxt.ctl.alufunc==DIV||dataE_nxt.ctl.alufunc==REM),.clk,.flushW,.mretW(is_mret||is_INTEXC)
	);
	pcreg pcreg(
		.clk,.reset,
		.pc,
		.pc_nxt(~i_wait&&ipc_saved?ipc_save: pc_nxt),
		.en(~(stallF)),
		.flush('0)
	);
	u64 fetch_pc,fetchin_pc;
	assign ireq.addr= pc;
	assign ireq.valid=pc[1:0]!=2'b00 ? '0:1'b1;

	assign raw_instr=pc[1:0]!=2'b00 ? '0:iresp.data;
	fetch_data_t dataF,dataF_nxt;
	decode_data_t dataD,dataD_nxt;
	execute_data_t dataE,dataE_nxt,dataE_post,dataE_second;
	memory_data_t dataM,dataM_nxt;
	writeback_data_t dataW;
	u64 pc_save,pcselected_save,ipc_save;
	u32 raw_instr_save,fetchin_rawinstr;
	u1 fetched,pcselect_saved,ipc_saved;
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

	pcselect pcselect(
		.pcplus4(pc+4),
		.pc_selected(pc_nxt),
		.pc_branch(dataD_nxt.target),
		.branch_taken(dataD_nxt.pcSrc),
		.mepc,.mtvec,
		.is_mret,
		.is_INTEXC
	);

	always_ff @(posedge clk) begin
		if ((i_wait||d_wait)&&is_INTEXC) begin
			ipc_save<=pc_nxt;
			ipc_saved<='1;
		end else if (~i_wait&&~d_wait) begin
			ipc_save<='0;
			ipc_saved<='0;
		end
	end

	always_comb begin
		fetchin_pc=pc;
		fetchin_rawinstr=raw_instr;
		if (pcselect_saved&&~d_wait) begin
		fetchin_rawinstr=raw_instr;
			fetchin_pc=pc;
		end else if (fetched&&~de_wait) begin
		fetchin_rawinstr=raw_instr_save;
			fetchin_pc=pc_save;
		end
	end

	fetch fetch(
		.raw_instr(fetchin_rawinstr),
		.pc(fetchin_pc),
		.dataF(dataF_nxt),
		.exception(fetchin_pc[1:0]!=2'b00),
		.trint,
		.swint,
		.exint
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
		.aluoutM,.forwardaD,.forwardbD,.resultW(dataW.wd),.aluoutM2
	);
	u64 aluoutM;
    always_comb begin
        aluoutM='0;
        unique case(dataE.ctl.wbSelect)
            2'b00:aluoutM=dataE.alu_out;
            // 2'b01:aluoutM=dataE.rd;
            2'b10:aluoutM=dataE.pc+4;
            2'b11:aluoutM=dataE.sextimm;
            default:begin end
    endcase
    end
	u64 aluoutM2;
    always_comb begin
        aluoutM2='0;
        unique case(dataE_second.ctl.wbSelect)
            2'b00:aluoutM2=dataE_second.alu_out;
            // 2'b01:aluoutM2=dataE_second.rd;
            2'b10:aluoutM2=dataE_second.pc+4;
            2'b11:aluoutM2=dataE_second.sextimm;
            default:begin end
    endcase
    end


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
		.aluoutM,.resultW(dataW.wd),.e_wait,.aluoutM2
	);
	
	// assign stallM = dreq.valid && ~dresp.data_ok;
	assign flushM2 = d_wait2? '0:d_wait;
	

	pipereg #(.T(execute_data_t)) mreg(
		.clk,.reset,
		.in(dataE_nxt),
		.out(dataE),
		.en(~stallM),
		.flush(flushM)
	);
	memory memory(
		.dataE(dataE),
		.dataE_post(dataE_post),
		.dreq,
		.exception(is_mret||is_INTEXC)
	);
	pipereg #(.T(execute_data_t)) mreg2(
		.clk,.reset,
		.in(dataE_post),
		.out(dataE_second),
		.en(~stallM2),
		.flush(flushM2)
	);
	
	m2 m2(
		.dataE(dataE_second),
		.dataM(dataM_nxt),
		.dresp
	);
	pipereg #(.T(memory_data_t)) wreg(
		.clk,.reset,
		.in(dataM_nxt),
		.out(dataM),
		.en(1),
		.flush(flushW)
	);

	assign inter_valid=~i_wait;
	writeback writeback (
		.clk,
		.reset,
		.dataM(dataM),
		.dataW(dataW),
		.mepc,
		.mtvec,
		.is_mret,
		.is_INTEXC,
		.regs_out,
		.mode_out,
		.inter_valid
	);
	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wvalid(dataW.ctl.regWrite),
		.wa(dataW.wa),
		.wd(dataW.wd)
		
	);
	// logic [25:0] clk_cnt;
	logic [90:0] clk_cnt;

	// always_ff @(posedge clk ) begin
	// 	clk_cnt += 1;
	// 	if (dreq.addr==64'h800100f8) begin
	// 		$display("at pc:%x, clk:%d,data:%x",dataE.pc,clk_cnt,dreq.data);
	// 		end
	// 	if (dreq.addr==64'h800100f8) begin
	// 		$display("at pc:%x, clk:%d,data:%x",dataE.pc,clk_cnt,dreq.data);
	// 		end
	// 	if (dataE.pc==64'h80002004) begin
	// 		$display("at pc:%x, clk:%d",dataD_nxt.pc,clk_cnt);
	// 		end
		
	// end
	// if (dreq.addr==64'h80007ac8&&dreq.valid&&dresp.data_ok) begin
		// 	$display("at pc:%x, dreq strobe:%b,data:%x;clk:%d",dataE.pc,dreq.strobe,dreq.data,clk_cnt);
		// 	$display("at pc:%x, dresp data:%x;clk:%d",dataE.pc,dresp.data,clk_cnt);
		// 	$display("at pc:%x, dresp data:%x;clk:%d",dataE.pc,dresp.data,clk_cnt);
		// end
		// if (clk_cnt[10]==10'b0) begin
		// 	$display("at pc:%x, dresp data:%x;clk:%d",dataE.pc,dresp.data,clk_cnt);
		// end
		// else if (dreq.addr==64'h80007ac8&&(|dreq.strobe)) begin
		// 	$display("at pc 0x80007ac8, dreq:%b,%x;clk:%d",dreq.strobe,dreq.data,clk_cnt);
		// end
	// csr csr(
	// 	.clk,.reset,
	// 	.ra(csra),
	// 	.wa(csra),
	// 	.wd(dataW.)
	// );
	// input u64 wd,
	// output u64 rd,mepc,
	// input u1 valid,is_mret

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid),
		.pc                 (dataW.pc),
		.instr              (raw_instr),
		.skip               ((dataW.ctl.memRw!=2'b00&& (dataW.alu_out[31]==0))||dataW.pc[1:0]!=2'b00),
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
			.clock (clk),
			.coreid (0),
			.priviledgeMode (mode_out),
			.mstatus (regs_out.mstatus),
			.sstatus (regs_out.mstatus & 64'h800000030001e000),
			.mepc (regs_out.mepc),
			.sepc (0),
			.mtval (regs_out.mtval),
			.stval (0),
			.mtvec (regs_out.mtvec),
			.stvec (0),
			.mcause (regs_out.mcause),
			.scause (0),
			.satp (0),
			.mip (regs_out.mip),
			.mie (regs_out.mie),
			.mscratch (regs_out.mscratch),
			.sscratch (0),
			.mideleg (0),
			.medeleg (0)
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