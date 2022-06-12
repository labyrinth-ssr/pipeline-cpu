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

parameter F3_LB=3'b000;
parameter F3_LBU=3'b100;
parameter F3_LH=3'b001;
parameter F3_LHU=3'b101;
parameter F3_LW=3'b010;
parameter F3_LWU=3'b110;
parameter F3_LD=3'b011;

parameter F3_MUL=3'b000;
parameter F3_DIV=3'b100;
parameter F3_DIVU=3'b101;
parameter F3_REM=3'b110;
parameter F3_REMU=3'b111;

parameter F3_CSRRWI=3'b101;
parameter F3_CSRRCI=3'b111;
parameter F3_CSRRSI=3'b110;
parameter F3_CSRRW=3'b001;
parameter F3_CSRRC=3'b011;
parameter F3_CSRRS=3'b010;
parameter F3_MRET=3'b000;


parameter F7_R_ADD=7'b0000000;
parameter F7_R_SUB=7'b0100000;
parameter F7_R_MUL_DIV=7'b0000001;

parameter F7_CSR = 7'b1110011;



typedef enum u3{
	NO_BRANCH,BRANCH_BEQ,BRANCH_BNE,BRANCH_BLT,BRANCH_BGE,BRANCH_BLTU,BRANCH_BGEU,J
} branch_t;



typedef enum logic[5:0] {
	UNKNOWN,ITYPE,RTYPE,STYPE,BTYPE,JTYPE,UTYPE
	// ,LUI,LD,SD,BEQ,AUIPC,JAL,JALR
 } decoded_op_t;
typedef enum logic [4:0] {
	ADD,SUB,OR,XOR,AND,LS,RS,SLS,SRS,CMP,SCMP,RSW,SRSW,SLLW,SRLW,SRAW,MUL,REM,DIV
} alufunc_t;
typedef enum u3 { 
	NONE,EXCEPTION,INTERUPT,RET,CSR_INSTR
 } csr_type_t;
 typedef enum u2 { 
	CSRRW,CSRRC,CSRRS
 } csr_op_t;
typedef struct packed {
	u1 trint;
	u1 swint;
	u1 exint;
} int_type_t;

typedef struct packed {
	decoded_op_t op;//for ext(imm)
	alufunc_t alufunc;
	branch_t branch;
	u2 memRw;
	u1 regWrite,selectA,selectB,pcTarget,extAluOut,mem_unsigned,alu_sign,alu_cut;
	u2 wbSelect;//left:1,right:2
	msize_t msize;
} control_t;

typedef struct packed {
	csr_type_t ctype;
	csr_op_t op;
	u4 code;
	u1 valid;
	u1 imm;
	u12 csra;
	u5 zimm;
	u64 rs1rd;
} csr_control_t;
typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;//instruction index
	csr_control_t csr_ctl;
	int_type_t int_type;

    } fetch_data_t;//

typedef struct packed {
	int_type_t int_type;
	u1 valid;
	u32 raw_instr;
	word_t srca,srcb;
	control_t ctl;
	creg_addr_t rd,ra1,ra2;//2^5=32 assign the reg to be written
	u64 pc;
	u64 sextimm;
	u64 target;
	u1 pcSrc;
	csr_control_t csr_ctl;
	
} decode_data_t;

typedef struct packed {
	int_type_t int_type;
	u1 valid;
	u64 pc;
	control_t ctl;
	creg_addr_t dst;
	u64 alu_out;
	// u64 target;
	u64 sextimm;
	word_t srcb;
	// u64 rs1rd;
	csr_control_t csr_ctl;
} execute_data_t;

typedef struct packed {
	u1 valid;
	int_type_t int_type;
	u64 pc;
	u64 alu_out;
	control_t ctl;
	creg_addr_t dst;
	u64 sextimm;
	csr_control_t csr_ctl;
	// u64 target;
	word_t rd;
	// u64 rs1rd;
} memory_data_t;

typedef struct packed {
	u1 valid;
	u64 alu_out;
	u64 pc;
	u64 sextimm;
	csr_control_t csr_ctl;
	control_t ctl;
	creg_addr_t wa;
	word_t wd;
} writeback_data_t;



endpackage

`endif
