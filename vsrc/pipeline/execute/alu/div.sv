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
    input u1 sign,
    input logic clk, resetn, valid,
    input i32 a, b,
    output logic done,
    output i64 c // c = {a % b, a / b}
);
    enum i1 { INIT, DOING } state, state_nxt;
    i35 count, count_nxt;
    localparam i35 DIV_DELAY = {'0, 1'b1, 32'b0};
    always_ff @(posedge clk) begin
        if (~resetn) begin
            {state, count} <= '0;
        end else begin
            {state, count} <= {state_nxt, count_nxt};
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
                count_nxt = {1'b0, count_nxt[34:1]};
                if (count_nxt == '0) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    i64 p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {'0, a};
            end
            DOING: begin
                p_nxt = {p_nxt[62:0], 1'b0};
                if (sign) begin
                    if ($signed(p_nxt[63:32]) >= $signed(b)) begin
                    $signed(p_nxt[63:32]) -= $signed(b);
                    p_nxt[0] = 1'b1;
                end
                end
                else begin
                    if (p_nxt[63:32] >= b) begin
                    p_nxt[63:32] -= b;
                    p_nxt[0] = 1'b1;
                end
                end
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if (~resetn) begin
            p <= '0;
        end else begin
            p <= p_nxt;
        end
    end
    assign c = p;
endmodule

`endif
