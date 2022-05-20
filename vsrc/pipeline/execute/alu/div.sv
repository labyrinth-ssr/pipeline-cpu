`ifndef __DIV_SV
`define __DIV_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
import common::*;
import pipes::*;

module divider_multicycle_from_single (
    input logic clk, reset, valid,
    input i64 a, b,
    output logic done,
    output u128 c
);
    enum i1 { INIT, DOING } state, state_nxt;
    i66 count, count_nxt;
    u1 zero;
    localparam i66 DIV_DELAY = {1'b0, 1'b1, 64'b0};
    always_ff @(posedge clk) begin
        if (reset) begin
            {state, count} <= '0;
            zero<='0;
        end else begin
            {state, count} <= {state_nxt, count_nxt};
            zero<=~(|b);
        end
    end
    assign done = (state_nxt == INIT);
    always_comb begin
        {state_nxt, count_nxt} = {state, count}; // default
        unique case(state)
            INIT: begin
                if (valid) begin
                    state_nxt = DOING;
                    count_nxt = DIV_DELAY;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[65:1]};
                if (count_nxt == '0||zero) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    u128 p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {64'b0, a};
            end
            DOING: begin
                p_nxt = {p_nxt[126:0], 1'b0};
                    if (p_nxt[127:64] >= b) begin
                    p_nxt[127:64] -= b;
                    p_nxt[0] = 1'b1;
                end
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
    assign c = p;
endmodule

`endif
