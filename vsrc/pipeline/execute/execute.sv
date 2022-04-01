`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`endif

module execute(
    input clk,
    ereg_intf.execute ereg_in,
    mreg_intf.execute out_mreg
);
u64 alu_result;
word_t alu_a,alu_b;
assign alu_a=ereg_in.dataD.srca
always_comb begin
    unique case (ereg_in.dataD.ctl.op)
        LD:begin
            alu_b={{52{ereg_in.dataD.imm[19]}},ereg_in.dataD.imm[19:8]};
        end
        ITYPE:begin
            alu_b={{52{ereg_in.dataD.imm[19]}},ereg_in.dataD.imm[19:8]};
        end
        RTYPE:begin
            alu_b=ereg_in.dataD.srcb
        end
    endcase
end

    alu alu (
        .a(alu_a),.b(alu_b),
        .alufunc(ereg_in.dataD.ctl.alufunc),
        .c(alu_result)
    );
    assign out_mreg.dataE_nxt.pc=ereg_in.dataD.pc;
    assign out_mreg.dataE_nxt.alu_out=alu_result;
    // assign out_mreg.dataE_nxt.ctl=ereg_in.dataD.ctl;

    // always_ff @(posedge clk) begin $display("%x", alu_result); end


    
endmodule

`endif 