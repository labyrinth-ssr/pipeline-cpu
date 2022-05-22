`ifndef __DIV_SV
`define __DIV_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
import common::*;
import pipes::*;

module divider_multicycle_from_single 
#(parameter WIDTH = 64)
(
    input logic clk, reset, valid,
    input logic [WIDTH-1:0] a, b,
    output logic done,
    output logic [WIDTH*2-1:0] c

);
    enum i1 { INIT, DOING } state, state_nxt;
    logic [WIDTH+1:0] count, count_nxt;
    // u1 zero;

    logic [WIDTH-1:0] areg,breg;
    logic [WIDTH-1:0] a_nxt,b_nxt;
    localparam logic [WIDTH+1:0] DIV_DELAY = {1'b0, 1'b1, {WIDTH{1'b0}}};
    always_ff @(posedge clk) begin
        if (reset) begin
            {state, count} <= '0;
            // zero<='0;
        end else if(state==INIT) begin
            {state, count} <= {state_nxt, count_nxt};
            // zero<=~(|b_nxt);
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
                    count_nxt = DIV_DELAY;
                    a_nxt=a;
                    b_nxt=b;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[WIDTH+1:1]};
                if (count_nxt == '0) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    logic [2*WIDTH-1:0] p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {{WIDTH{1'b0}}, a_nxt};
            end
            DOING: begin
                p_nxt = {p_nxt[WIDTH*2-2:0], 1'b0};
                    if (p_nxt[WIDTH*2-1:WIDTH] >= breg) begin
                    p_nxt[WIDTH*2-1:WIDTH] -= breg;
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
