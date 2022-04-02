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
wire [6:0] rf7=raw_instr[31:25];
always_comb begin
    ctl ='0;//bit numbers depends on context
    unique case (f7)
        F7_ITYPE:begin
            ctl.regWrite=1'b1;
            ctl.selectB=1'b1;
            ctl.op=ITYPE;
            unique case (f3)
                F3_ADD_SUB:begin
                    ctl.alufunc=ADD;
                end
                F3_XOR:begin
                    ctl.alufunc=XOR;
                end
                F3_OR:begin
                    ctl.alufunc=OR;
                end
                F3_AND:begin
                    ctl.alufunc=AND;
                end
                default:begin
                    
                end 
            endcase
        end
        F7_RTYPE:begin
            ctl.op=RTYPE;
            ctl.regWrite=1'b1;
            unique case (f3)
                F3_ADD_SUB:begin
                    unique case (rf7)
                    F7_R_ADD:ctl.alufunc=ADD;
                    F7_R_SUB:ctl.alufunc=SUB;
                end
                F3_XOR:begin
                    ctl.alufunc=XOR;
                end
                F3_OR:begin
                    ctl.alufunc=OR;
                end
                F3_AND:begin
                    ctl.alufunc=AND;
                end
                default:begin
                    
                end 
            endcase
        end 
        default:begin
            
        end
        F7_JAL:begin
            ctl.regWrite=1'b1;
            ctl.pcTarget=1'b1;
            ctl.pcSrc=1'b1;
            ctl.wbSelect=2'b10;
        end
        F7_JALR:begin
            ctl.regWrite=1'b1;
            ctl.pcSrc=1'b1;
            ctl.wbSelect=2'b10;
        end
        F7_BEQ:begin
            ctl.branch=1'b1;
            ctl.alufunc=SUB;
        end
        F7_AUIPC:begin
            ctl.alufunc=ADD;
            ctl.regWrite=1'b1;
            ctl.selectA=1'b1;
            ctl.selectB=1'b1;
        end
        F7_LUI:begin
            ctl.regWrite=1'b1;
            ctl.wbSelect=2'b11;
        end
        F7_LD:begin
            ctl.regWrite=1'b1;
            ctl.selectB=1'b1;
            ctl.alufunc=ADD;
            ctl.wbSelect=2'b01;
            ctl.memRw=2'b01;

        end
        F7_SD:begin
            ctl.selectB=1'b1;
            ctl.alufunc=ADD;
            ctl.memRw=2'b10;
        end
    endcase
end
    
endmodule
`endif 