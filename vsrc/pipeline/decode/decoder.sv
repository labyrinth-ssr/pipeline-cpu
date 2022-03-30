`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module decoder 
    import common::*;
    import pipes::*;(
    input u32 raw_instr,
    output control_t ctl
);
wire [6:0] f7=raw_instr[6:0];
wire [2:0] f3=raw_instr[14:12];
always_comb begin
    ctl ='0;//bit numbers depends on context
    unique case (f7)
        F7_ALU_I:begin
            unique case (f3)
                F3_ADDI:begin
                    ctl.op=ADDI;
                    ctl.regWrite=1'b1;
                    ctl.alufunc=ALU_ADD;
                end
                F3_XORI:begin
                    ctl.op=XORI;
                    ctl.regWrite=1'b1;
                    ctl.alufunc=ALU_XOR;
                end
                F3_ORI:begin
                    ctl.op=ORI;
                    ctl.regWrite=1'b1;
                    ctl.alufunc=ALU_OR;
                end
                F3_ANDI:begin
                    ctl.op=ANDI;
                    ctl.regWrite=1'b1;
                    ctl.alufunc=ALU_AND;
                end
                default:begin
                    
                end 
            endcase
        end 
        default:begin
            
        end
    endcase
end
    
endmodule
`endif 