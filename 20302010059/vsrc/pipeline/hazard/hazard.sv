`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module hazard
import common::*;
import pipes::*;(
    output u1 stallF,stallD,flushF,flushD,flushE,
    input creg_addr_t edst,mdst,wdst,
    input ebranch,mbranch,
    input creg_addr_t rs1,rs2,
    input wrE,wrM,wrW
);
    always_comb begin
            stallF='0;stallD='0;flushF='0;flushD='0;flushE='0;

        if (mbranch) begin
            flushD=1;
            flushF='1;
            flushE='1;
        end else if (ebranch) begin
            flushD='1;flushF='1;
        end else if (wrE&&(edst==rs1||edst==rs2)) begin
            stallD='1;stallF='1;flushD='1;
        end else if (wrM&&(mdst==rs1||mdst==rs2)) begin
            stallD='1;stallF='1;flushD='1;
        end else if (wrW&&(wdst==rs1||wdst==rs2)) begin
            stallD='1;stallF='1;flushD='1;
        end else begin
            stallF='0;stallD='0;flushF='0;flushD='0;flushE='0;
        end
    end
endmodule

`endif 