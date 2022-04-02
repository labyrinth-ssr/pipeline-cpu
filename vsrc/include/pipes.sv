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
parameter F7_BEQ =   7'b1100011;
parameter F7_LUI =   7'b0110111;
parameter F7_LD =    7'b0000011;
parameter F7_SD =    7'b0100011;

parameter F3_ADD_SUB = 3'b000;
parameter F3_XOR = 3'b100;
parameter F3_OR  = 3'b110;
parameter F3_AND = 3'b111;

parameter F7_R_ADD=7'b0000000;
parameter F7_R_SUB=7'b0100000;



typedef struct packed {
	u1 valid,
	u32 raw_instr;
	u64 pc;//instruction index
    } fetch_data_t;//

typedef enum logic[5:0] {
	UNKNOWN,ITYPE,RTYPE,STYPE,BTYPE,JTYPE,UTYPE
	// ,LUI,LD,SD,BEQ,AUIPC,JAL,JALR
 } decoded_op_t;
typedef enum logic [4:0] {
	ADD,SUB,OR,XOR,AND
} alufunc_t;

typedef struct packed {
	decoded_op_t op;//for ext(imm)
	alufunc_t alufunc;
	u1 regWrite;
	u1 branch;
	u2 memRw;
	u1 pcSrc;
	u1 selectA,selectB,pcTarget;
	u2 wbSelect;
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
	u1 valid,
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
	word_t dst;
	u64 sextimm;
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
