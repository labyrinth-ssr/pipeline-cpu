`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module hazard
import common::*;
import pipes::*;(
    output u1 stallF,stallD,flushD,flushE,flushM,stallM,flushW,stallE,
    input creg_addr_t edst,mdst,wdst,
    input dbranch,i_wait,d_wait,e_wait,
    input creg_addr_t ra1,ra2,ra1E,ra2E,
    input wrE,wrM,wrW,
    input memwrE,memwrM,
    output u1 forwardaD,forwardbD,
    output u2 forwardaE,forwardbE
);
u1 branch_stall,lwstall;

    always_comb begin
        stallF='0;stallD='0;flushD='0;flushE='0;flushM='0;
        stallM='0;flushW='0;stallE='0;branch_stall='0;lwstall='0;
        forwardaE='0;forwardbE='0;forwardaD='0;forwardbD='0;
        if (e_wait) begin
            stallE='1;flushM='1;stallF='1;flushD='1;
        end
        else if(d_wait) begin
            stallM='1;flushW='1;stallF='1;flushD='1;
        end else if (i_wait) begin
            stallF='1;flushD='1;
            if (dbranch) begin
            stallF='0;flushD='1;
            end
        end  
        else begin
            flushD=dbranch;
            branch_stall=dbranch && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) );
            lwstall=memwrE && (edst==ra1||edst==ra2);
            stallD=lwstall || branch_stall;
            stallF=stallD;
            flushE=stallD;
            if(ra1E!=0) begin
                if (ra1E==mdst && wrM ) forwardaE=2'b10;
                else if (ra1E==wdst && wrW ) forwardaE=2'b01;
            end
            if(ra2E!=0) begin
                if (ra2E==mdst && wrM ) forwardbE=2'b10;
                else if (ra2E==wdst && wrW ) forwardbE=2'b01;
            end
            forwardaD=(ra1!=0&&ra1==mdst && wrM);
            forwardbD=(ra2!=0&&ra2==mdst && wrM);

        end
    end
endmodule

`endif 