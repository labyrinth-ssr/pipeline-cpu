`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/writeback/csr.sv"
`endif 

module writeback
import common::*;
	import pipes::*;
    import csr_pkg::*;(
    input u1 clk,reset,
    input memory_data_t dataM,
    output writeback_data_t dataW,
    output u64 mepc,mtvec,
    output u1 is_mret,is_INTEXC,
    output csr_regs_t regs_out,
    output u2 mode_out,
    input u1 inter_valid
);
    // always_ff @(posedge clk) begin
	// 		$display("%x %x",dataM.pc,regs_out.mepc);
        
    // end
    
    u64 csrrd;
    u1 delayed_interupt;
    assign mode_out=cmode_nxt;
    assign dataW.alu_out=dataM.alu_out;
    assign dataW.pc=dataM.pc;
    assign dataW.sextimm=dataM.sextimm;
    assign dataW.ctl=dataM.ctl;
    assign dataW.wa=dataM.dst;
    assign dataW.valid=dataM.valid;
    u64 csrwd;
    u2 cmode,cmode_nxt;
    csr_control_t newm_csr_ctl;
    u1 interrupt;
    always_ff @(posedge clk) begin
        if (reset) begin
            cmode<=2'h3;
        end else begin
            cmode<=cmode_nxt;
        end
    end
    always_comb begin
        if (dataM.csr_ctl.ctype==RET) begin
            cmode_nxt=regs_out.mstatus.mpp;
        end else if (dataM.csr_ctl.ctype==EXCEPTION || interrupt ) begin
            cmode_nxt=2'h3;
        end else begin
            cmode_nxt=cmode;
        end
    end

    always_comb begin
        dataW.wd='0;
        if (dataM.csr_ctl.ctype==EXCEPTION||dataM.csr_ctl.ctype==CSR_INSTR) begin
            dataW.wd=csrrd;
        end
        else begin
        unique case(dataM.ctl.wbSelect)
            2'b00:dataW.wd=dataM.alu_out;
            2'b01:dataW.wd=dataM.rd;
            2'b10:dataW.wd=dataM.pc+4;
            2'b11:dataW.wd=dataM.sextimm;
            default:begin end
        endcase
        end
    end
    always_comb begin
        csrwd='0;
        unique case (dataM.csr_ctl.op)
        CSRRC:begin
            if (dataM.csr_ctl.imm) begin
                csrwd=csrrd & ~ {59'b0,dataM.csr_ctl.zimm};
            end else begin
                csrwd= csrrd & ~dataM.csr_ctl.rs1rd;
            end
        end
        CSRRS:begin
            if (dataM.csr_ctl.imm) begin
                csrwd=csrrd | {59'b0,dataM.csr_ctl.zimm};
            end else begin
                csrwd= csrrd |dataM.csr_ctl.rs1rd;
            end
        end
        CSRRW:begin
            if (dataM.csr_ctl.imm) begin
                csrwd= {59'b0,dataM.csr_ctl.zimm};
            end else begin
                csrwd= dataM.csr_ctl.rs1rd;
            end
        end
        default: ;
        endcase
    end
    csr csr(
        .clk,.reset,
        .ra(dataM.csr_ctl.csra),
        .wa(dataM.csr_ctl.csra),
        .wd(csrwd),
        .rd(csrrd),
        .mepc,.mtvec,
        .valid(dataM.csr_ctl.valid),
        .is_mret(dataM.csr_ctl.ctype==RET),
        .regs_out,
        .ctype(dataM.csr_ctl.ctype),
        .pc(dataM.pc),
        .code(dataM.csr_ctl.code),
        .mode(cmode),
        .trint(dataM.int_type.trint),
        .swint(dataM.int_type.swint),
        .exint(dataM.int_type.exint),
        .interrupt,
        .inter_valid,
        .delayed_interupt
    );
    assign is_mret=(dataM.csr_ctl.ctype==RET);
    assign is_INTEXC=(dataM.csr_ctl.ctype==EXCEPTION||(interrupt&&inter_valid)||delayed_interupt);

endmodule

`endif 