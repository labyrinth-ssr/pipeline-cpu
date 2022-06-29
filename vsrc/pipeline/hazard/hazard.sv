`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/interface.svh"
`endif 

module hazard
import common::*;
import pipes::*;(
    output u1 stallF,stallD,flushD,flushE,flushM,stallM,stallE,flushW,stallM2,
    input creg_addr_t edst,mdst,wdst,mdst2,
    input dbranch,i_wait,d_wait,e_wait,dbranch2,multialud,multialuM,multialuE,d_wait2,
    input creg_addr_t ra1,ra2,ra1E,ra2E,
    input wrE,wrM,wrW,wrM2,
    input memwrE,memwrM,memwrM2,
    input mretW,
    output u2 forwardaD,forwardbD,forwardaE,forwardbE,
    input clk
);
u1 branch_stall,lwstall,multi_stall;
u1 mret_dwait,mret_dwait_nxt,mret_iwait,mret_iwait_nxt;
u64 int_save;
u1 flushM2;

always_ff @(posedge clk) begin
        mret_dwait<=mret_dwait_nxt;
        mret_iwait<=mret_iwait_nxt;
end


    always_comb begin
        stallF='0;stallD='0;flushD='0;flushE='0;flushM='0;
        stallM='0;stallE='0;branch_stall='0;lwstall='0;mret_dwait_nxt=mret_dwait;mret_iwait_nxt=mret_iwait;
        if (mretW) begin
            flushD='1;flushE='1;flushM='1;flushW='1;flushM2='1;
            if (i_wait) begin
                mret_iwait_nxt='1;
                stallF='1;flushD='1;
            end
        end
        else if (e_wait) begin
            stallE='1;flushM='1;stallF='1;stallD='1;
            if (d_wait) begin
                stallM='1;flushM='0;
            end 
        end else if(d_wait2) begin
            stallM='1;stallE='1;stallF='1;stallD='1;flushM2='0;flushW='1;stallM2='1;
        end else if(d_wait) begin
            stallM='1;stallE='1;stallF='1;stallD='1;flushM2='1;
            if (mretW) begin
                mret_dwait_nxt='1;
            end
        end  else if (i_wait) begin
            stallF='1;flushD='1;
            if (dbranch) begin
            // stallF='1;flushD='1;
                stallD='1;
                flushD='0;
                flushE='1;
            end
            multi_stall=multialud && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) || (memwrM2&& (mdst2==ra1||mdst2==ra2)) || (((ra1!=0&&ra1==mdst && wrM)||(ra2!=0&&ra2==mdst && wrM))) || ((((ra1!=0&&ra1==mdst2 && wrM2)||(ra2!=0&&ra2==mdst2 && wrM2)))));
            branch_stall=dbranch2 && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)))|| (memwrM2&& (mdst2==ra1||mdst2==ra2)) ;
            lwstall= (memwrE && (edst==ra1||edst==ra2)) || ((memwrM&& (mdst==ra1||mdst==ra2))) ;

            if (multi_stall||branch_stall||lwstall) begin
                flushD='0;
                stallD='1;
                flushE='1;
            end
            
        end  
        else begin
            branch_stall=dbranch2 && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) || (memwrM2&& (mdst2==ra1||mdst2==ra2))  );
            lwstall= (memwrE && (edst==ra1||edst==ra2)) || ((memwrM&& (mdst==ra1||mdst==ra2))) ;
            multi_stall=multialud && ((wrE&&(edst==ra1||edst==ra2))||(memwrM&& (mdst==ra1||mdst==ra2)) || (memwrM2&& (mdst2==ra1||mdst2==ra2)) || (((ra1!=0&&ra1==mdst && wrM)||(ra2!=0&&ra2==mdst && wrM))) ||((((ra1!=0&&ra1==mdst2 && wrM2)||(ra2!=0&&ra2==mdst2 && wrM2)))));
            stallD=lwstall || branch_stall || multi_stall;
            stallF=stallD;
            flushE=stallD;
            flushD=branch_stall? '0:dbranch;
        end
        if (~d_wait&&mret_dwait) begin
            flushM2='1;
            mret_dwait_nxt='0;
        end
        if (~i_wait&&mret_iwait) begin
            flushD='1;
            mret_iwait_nxt='0;
        end
    end

    always_comb begin
        forwardaE='0;forwardbE='0;forwardaD='0;forwardbD='0;
        if((ra1E!=0 && ~e_wait) ) begin
                if (ra1E==mdst && wrM ) forwardaE=2'b10;
                else if (ra1E==mdst2 && wrM2 ) forwardaE=2'b11;
                else if (ra1E==wdst && wrW ) forwardaE=2'b01;
        end
        if((ra2E!=0 && ~e_wait)) begin
                if (ra2E==mdst && wrM ) forwardbE=2'b10;
                else if (ra2E==mdst2 && wrM2 ) forwardbE=2'b11;
                else if (ra2E==wdst && wrW ) forwardbE=2'b01;
        end

        if(ra1!=0) begin
                if (ra1==mdst && wrM ) forwardaD=2'b10;
                else if (ra1==mdst2 && wrM2 ) forwardaD=2'b11;
                else if (ra1==wdst && wrW ) forwardaD=2'b01;
        end
        if(ra2!=0) begin
                if (ra2==mdst && wrM ) forwardbD=2'b10;
                else if (ra2==mdst2 && wrM2 ) forwardbD=2'b11;
                else if (ra2==wdst && wrW ) forwardbD=2'b01;
        end
    end
endmodule

`endif 