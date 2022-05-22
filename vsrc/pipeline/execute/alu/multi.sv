`ifndef __MULTI_SV
`define __MULTI_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
import common::*;
import pipes::*;

module multiplier_multicycle_from_single (
    input logic clk, reset, valid,
    input i64 a, b,
    output logic done, // 握手信号，done 上升沿时的输出是有效的
    output u64 c // c = a * b
);
    u64 areg,breg;
    u64 a_nxt,b_nxt;


    enum i1 { INIT, DOING } state, state_nxt;
    i66 count, count_nxt;
    localparam i66 MULT_DELAY = {1'b0, 1'b1, 64'b0};
    always_ff @(posedge clk) begin
        if (reset) begin
            {state, count} <= '0;
        end else if(state==INIT) begin
            {state, count} <= {state_nxt, count_nxt};
            areg<=a_nxt;
            breg<=b_nxt;
        end else begin
            {state, count} <= {state_nxt, count_nxt};
            areg<=areg;
            breg<=breg;
        end
    end
    assign done = (state_nxt == INIT);
    always_comb begin
        {state_nxt, count_nxt} = {state, count}; // default
        a_nxt='0;b_nxt='0;
        unique case(state)
            INIT: begin
                if (valid) begin
                    state_nxt = DOING;
                    count_nxt = MULT_DELAY;
                    a_nxt=a;
                    b_nxt=b;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[65:1]};
                if (count_nxt == '0) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    logic[128:0] p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {65'b0, a_nxt};
            end
            DOING: begin
                if (p_nxt[0]) begin
                    // p_nxt[64:32] = p_nxt[63:32] + b;
                    p_nxt[128:64] = p_nxt[128:64] + {1'b0,breg};
            	end
            	p_nxt = {1'b0, p_nxt[128:1]};
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if (reset) begin
            p <= '0;
        end else begin
            p <= p_nxt;
        end
    end
    assign c = p[63:0];
endmodule

`endif
