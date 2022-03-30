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
parameter F7_ALU_I = 7'b0010011;
parameter F3_ADDI = 3'b000;
parameter F3_XORI = 3'b100;
parameter F3_ORI  = 3'b110;
parameter F3_ANDI = 3'b111;

    typedef struct packed {
	u32 raw_instr;
	u64 pc;//instruction index
    } fetch_data_t;//

typedef enum logic[5:0] { 
	UNKNOWN,ADDI,ORI,ANDI,XORI,ADD,SUB,OR,AND,XOR,LUI,LD,SD,BEQ,AUIPC,JAL,JALR
 } decoded_op_t;
typedef enum logic [4:0] {
	ALU_ADD,ALU_SUB,ALU_OR,ALU_XOR,ALU_AND
} alufunc_t;

typedef struct packed {
	decoded_op_t op;
	alufunc_t alufunc;
	// u1 regWrite;
	// u1 aluSrc;
	// u1 regDst;
	// u1 branch;
	// u1 memWrite;
	// u1 memRead;
	// u1 memtoReg;
	// u1 extOp;
	// u1 pcSrc;
} control_t;

typedef struct packed {
	word_t srca,srcb;
	control_t ctl;
	creg_addr_t rd;//2^5=32 assign the reg to be written
	creg_addr_t rs2;
	u64 pc;
	u20 imm;//signed or zero
} decode_data_t;

typedef struct packed {
	u64 pc;
	control_t ctl;
	// alufunc_t alufunc;
	// u1 regWrite;
	// u1 aluSrc;
	// u1 regDst;
	// u1 branch;
	// u1 memWrite;
	// u1 memRead;
	// u1 memtoReg;
	// u1 extOp;
	creg_addr_t dst;


} execute_data_t;

typedef struct packed {
	// u64 pc;
	u64 alu_out;
	decoded_op_t op;
	// u1 memWrite;
	// u1 branch;
	// u1 memtoReg;
	// u1 regWrite;
	creg_addr_t dst;
} memory_data_t;

typedef struct packed {
	// u1 memtoReg;
	// u1 regWrite;
	decoded_op_t op;
	creg_addr_t wa;
} writeback_data_t;

endpackage

`endif
