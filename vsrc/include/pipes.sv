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
parameter F7_ADDI = 7'b0010011;
parameter F3_ADDI = 3'b000;

    typedef struct packed {
	u32 raw_instr;
	u64 pc;//instruction index
    } fetch_data_t;//

typedef enum logic[5:0] { 
	UNKNOWN,ADDI
 } decoded_op_t;
typedef enum logic [4:0] {
	ALU_ADD
} alufunc_t;

typedef struct packed {
	decoded_op_t op;
	alufunc_t alufunc;
	u1 regwrite;
	u64 pc;
} control_t;

typedef struct packed {
	word_t srca,srcb;
	control_t ctl;
	creg_addr_t dst;//2^5=32 assign the reg to be written
	u64 pc;
	u64 signed_imm;
} decode_data_t;

typedef struct packed {
	u64 pc;
	// control_t ctl;
	u64 alu_out;

} execute_data_t;

typedef struct packed {
	// u64 pc;
	u64 alu_out;
} memory_data_t;

typedef struct packed {
	u64 result;
} mread_req;

typedef struct packed {
	u64 in;
} mwrite_req;



endpackage

`endif
