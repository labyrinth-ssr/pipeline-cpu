`ifndef __PCREG_SV
`define __PCREG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 

module pcreg
import common::*;(
    input clk,reset,
    input u64 pc_nxt,
    output u64 pc,
	input en,flush
	// input enable
	// pcreg_intf.pcreg self
);
    always_ff @( posedge clk ) begin
		if (reset) begin
			pc<=64'h8000_0000;//
		end else if (flush) begin
			pc<='0;
		end
		else if(en) begin
			pc<=pc_nxt;
		end
	end
endmodule

`endif 