`ifndef __PCREG_SV
`define __PCREG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 

module pcreg(
    input clk,reset,
    input u64 pc_nxt,
    output u64 pc
);
    always_ff @( posedge clk ) begin
		if (reset) begin
			pc<=64'h8000_0000;//
		end else begin
			pc<=pc_nxt;
		end
	end
    
endmodule


`endif 