`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module hazard
import common::*;
import pipes::*;(
    output u1 stallF,stallD,flushF,flushD,flushE,stallM,flushM,stallE,
    input creg_addr_t edst,mdst,wdst,
    input ebranch,i_wait,d_wait,
    input creg_addr_t rs1,rs2,
    input wrE,wrM,wrW
);
    always_comb begin
        stallF='0;stallD='0;flushF='0;flushD='0;flushE='0;
        stallM='0;flushM='0;stallE='0;
        if(d_wait) begin
            stallM='1;flushM='1;stallF='1;flushF='1;
        end else if (i_wait) begin
            stallF='1;flushF='1;
            if (ebranch) begin
                stallE='1;
                flushE='1;
            end
        end
        else if (ebranch) begin
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