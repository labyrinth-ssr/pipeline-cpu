`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`endif

module execute(
    input decode_data_t dataD,
    output execute_data_t dataE,
    // ereg_intf.execute ereg_in,
    // mreg_intf.execute out_mreg
);
u64 alu_result;
word_t alu_a,alu_b;
assign dataE.ctl=dataD.ctl;
assign dataE.pc=dataD.pc;

u64 sextimm;

always_comb begin
    unique case (dataD.ctl.op)
    sextimm='0;
        ITYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[31:20]};
        end
        UTYPE: begin
            sextimm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b0};
        end
        STYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[31:25], raw_instr[11:7]};
        end
        BTYPE: begin
            sextimm = {{52{raw_instr[31]}}, raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};
        end
        JTYPE: begin
            sextimm = {{44{raw_instr[31]}}, raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
        end
        default: begin
            
        end 
    endcase
end

always_comb begin
    alu_a=dataD.ctl.selectA?dataD.pc:dataD.srca;
    alu_b=dataD.ctl.selectB?sextimm:dataD.srcb;
end

u64 pcAdded;
assign pcAdded=dataD.pc+sextimm;
always_comb begin
    dataE.target=dataD.ctl.pcTarget?pcAdded:alu_result&~1;
end

    alu alu (
        .a(alu_a),.b(alu_b),
        .alufunc(dataD.ctl.alufunc),
        .c(alu_result)
    );
    assign dataE.pc=dataD.pc;
    assign dataE.alu_out=alu_result;
    assign dataE.sextimm=sextimm;
    assign dataE.srcb=dataD.srcb;
    assign dataE.dst=dataD.rd;
    // assign dataE_nxt.ctl=dataD.ctl;
    // always_ff @(posedge clk) begin $display("%x", alu_result); end
endmodule

`endif 