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
    input dbranch,i_wait,d_wait,e_wait,dbranch2,multialud,multialuM,multialuE,
    input creg_addr_t ra1,ra2,ra1E,ra2E,
    input wrE,wrM,wrW,
    input memwrE,memwrM,
    output u2 forwardaD,forwardbD,forwardaE,forwardbE
);
u1 branch_stall,lwstall,multi_stall;

    always_comb begin
        stallF='0;stallD='0;flushD='0;flushE='0;flushM='0;
        stallM='0;flushW='0;stallE='0;branch_stall='0;lwstall='0;
        if ((multialuE&&multialuM&&~e_wait)||()) begin
            flushM='1;
        end
        if (e_wait) begin
            stallE='1;flushM='1;stallF='1;stallD='1;
            if (d_wait) begin
                stallM='1;flushM='0;
            end else if (forwardaE!=0||forwardbE!=0) begin
                stallM='1;flushM='0;flushW='1;
            end
        end
        else if(d_wait) begin
            stallM='1;stallE='1;stallF='1;stallD='1;
        end else if (i_wait) begin
            stallF='1;flushD='1;
            if (dbranch) begin
            stallF='0;flushD='1;
            end
        end  
        else begin
            branch_stall=dbranch2 && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) );
            lwstall= (memwrE && (edst==ra1||edst==ra2));
            multi_stall=multialud && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) ) && ~multialuE;

            stallD=lwstall || branch_stall || multi_stall;
            stallF=stallD;
            flushE=stallD;
            flushD=branch_stall? '0:dbranch;

        end
    end

    always_comb begin
        forwardaE='0;forwardbE='0;forwardaD='0;forwardbD='0;
        if((ra1E!=0 && ~e_wait) || (ra1E!=0 && e_wait && multialuM)) begin
                if (ra1E==mdst && wrM ) forwardaE=2'b10;
                else if (ra1E==wdst && wrW ) forwardaE=2'b01;
            end
        if((ra2E!=0 && ~e_wait)|| (ra2E!=0 && e_wait && multialuM)) begin
            if (ra2E==mdst && wrM ) forwardbE=2'b10;
            else if (ra2E==wdst && wrW ) forwardbE=2'b01;
        end
            // forwardaD=(ra1!=0&&ra1==mdst && wrM);
            // forwardbD=(ra2!=0&&ra2==mdst && wrM);

        if(ra1!=0) begin
                if (ra1==mdst && wrM ) forwardaD=2'b10;
                else if (ra1==wdst && wrW ) forwardaD=2'b01;
            end
        if(ra2!=0) begin
            if (ra2==mdst && wrM ) forwardbD=2'b10;
            else if (ra2==wdst && wrW ) forwardbD=2'b01;
        end
    end
endmodule

`endif 