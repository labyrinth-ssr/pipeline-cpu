`ifndef __PIPES_SV
`define __PIPES_SV


`ifdef VERILATOR
`include "include/common.sv"
`endif 
package pipes;

import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;


/* Define pipeline structures here */
parameter F7_ITYPE = 7'b0010011;
parameter F7_RTYPE = 7'b0110011;
parameter F7_JAL =   7'b1101111;
parameter F7_JALR =  7'b1100111;
parameter F7_AUIPC = 7'b0010111;
parameter F7_BTYPE = 7'b1100011;
// parameter F7_BEQ =   7'b1100011;
parameter F7_LUI =7'b0110111;
parameter F7_LD = 7'b0000011;
parameter F7_SD = 7'b0100011;
parameter F7_IW = 7'b0011011;
parameter F7_RW = 7'b0111011;


parameter F3_ADD_SUB = 3'b000;
parameter F3_XOR = 3'b100;
parameter F3_OR  = 3'b110;
parameter F3_AND = 3'b111;

parameter F3_BEQ = 3'b000;
parameter F3_BNE = 3'b001;
parameter F3_BLT = 3'b100;
parameter F3_BGE = 3'b101;
parameter F3_BLTU = 3'b110;
parameter F3_BGEU = 3'b111;

parameter F3_ADD_SUBW=3'b000;
parameter F3_SLLW=3'b001;
parameter F3_SRW=3'b101;

parameter F6_LOGIC=6'b000000;
parameter F6_ARITH=6'b010000;

parameter F3_SLL=3'b001;
parameter F3_SLT=3'b010;
parameter F3_SLTU=3'b011;
parameter F3_SR=3'b101;

parameter F7_R_ADD=7'b0000000;
parameter F7_R_SUB=7'b0100000;

typedef enum u3{
	NO_BRANCH,BRANCH_BEQ,BRANCH_BNE,BRANCH_BLT,BRANCH_BGE,BRANCH_BLTU,BRANCH_BGEU
} branch_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;//instruction index
    } fetch_data_t;//

typedef enum logic[5:0] {
	UNKNOWN,ITYPE,RTYPE,STYPE,BTYPE,JTYPE,UTYPE
	// ,LUI,LD,SD,BEQ,AUIPC,JAL,JALR
 } decoded_op_t;
typedef enum logic [4:0] {
	ADD,SUB,OR,XOR,AND,LS,RS,SLS,SRS,CMP,SCMP,RSW,SRSW,SLLW,SRLW,SRAW
} alufunc_t;

typedef struct packed {
	decoded_op_t op;//for ext(imm)
	alufunc_t alufunc;
	branch_t branch;
	u2 memRw;
	u1 pcSrc,regWrite,selectA,selectB,pcTarget,extAluOut;
	u2 wbSelect;//left:1,right:2
} control_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	word_t srca,srcb;
	control_t ctl;
	creg_addr_t rd;//2^5=32 assign the reg to be written
	u64 pc;
} decode_data_t;

typedef struct packed {
	u1 valid;
	u64 pc;
	control_t ctl;
	creg_addr_t dst;
	u64 alu_out;
	u64 target;
	u64 sextimm;
	word_t srcb;

} execute_data_t;

typedef struct packed {
	u1 valid;
	u64 pc;
	u64 alu_out;
	control_t ctl;
	creg_addr_t dst;
	u64 sextimm;
	u64 target;
	word_t rd;
} memory_data_t;

typedef struct packed {
	u1 valid;
	u64 alu_out;
	u64 pc;
	u64 sextimm;
	control_t ctl;
	creg_addr_t wa;
	word_t wd;
} writeback_data_t;



endpackage

`endif
