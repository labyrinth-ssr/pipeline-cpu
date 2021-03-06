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
    output control_t ctl,
    output u1 illegal_instr
);
wire [6:0] f7=raw_instr[6:0];
wire [2:0] f3=raw_instr[14:12];
wire [6:0] rf7=raw_instr[31:25];
u5 csra=raw_instr[19:15];
u6 f6=raw_instr[31:26];
always_comb begin
    ctl ='0;
    illegal_instr='0;
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
                F3_SLT:begin
                    ctl.alufunc=SCMP;
                end
                F3_SLTU:begin
                    ctl.alufunc=CMP;
                end
                F3_SLL:begin
                    ctl.alufunc=LS;
                end
                F3_SR:begin
                    unique case (f6)
                        F6_LOGIC:ctl.alufunc=RS;
                        F6_ARITH:ctl.alufunc=SRS;
                        default:begin
                            illegal_instr='1;
                        end
                    endcase
                end
                default:begin
                    illegal_instr='1;

                end 
            endcase
        end
        F7_IW:begin
            ctl.op=ITYPE;
            ctl.regWrite=1'b1;
                    ctl.selectB=1'b1;
            unique case (f3)
                F3_ADD_SUBW:begin
                    ctl.extAluOut='1;
                end
                F3_SRW:begin
                    unique case(f6)
                    F6_LOGIC:ctl.alufunc=RSW;
                    F6_ARITH:ctl.alufunc=SRSW;
                    default:begin
                        illegal_instr='1;

                    end
                endcase
                end
                F3_SLLW:begin
                    ctl.alufunc=LS;
                    ctl.extAluOut='1;
                end
                default:begin
                            illegal_instr='1;

                    end
            endcase
        end
        F7_RTYPE:begin
            ctl.op=RTYPE;
            ctl.regWrite=1'b1;
            ctl.selectB=1'b0;
            if (rf7==7'b0000001) begin
                unique case (f3)
                    F3_MUL:begin
                        ctl.alufunc=MUL;
                    end
                    F3_DIV:begin
                        ctl.alufunc=DIV;
                        ctl.alu_sign='1;
                    end
                    F3_DIVU:begin
                        ctl.alufunc=DIV;
                    end
                    F3_REM:begin
                        ctl.alufunc=REM;
                        ctl.alu_sign='1;
                    end
                    F3_REMU:begin
                        ctl.alufunc=REM;
                    end
                    default:     illegal_instr='1;

                endcase
            end
            else begin
                unique case (f3)
                F3_ADD_SUB:begin
                    unique case (rf7)
                    F7_R_ADD:ctl.alufunc=ADD;
                    F7_R_SUB:ctl.alufunc=SUB;
                    default:begin
                        ctl.alufunc=ADD;
                        //???
                    end
                endcase
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
                F3_SLT:begin
                    ctl.alufunc=SCMP;
                end
                F3_SLTU:begin
                    ctl.alufunc=CMP;
                end
                F3_SLL:begin
                    ctl.alufunc=LS;
                end
                F3_SR:begin
                    unique case (f6)
                        F6_LOGIC:ctl.alufunc=RS;
                        F6_ARITH:ctl.alufunc=SRS;
                        default:begin
                        
                    end
                    endcase
                end
                default:begin
                            illegal_instr='1;
                    
                end 
            endcase
            end
        end 
        F7_RW:begin
            ctl.op=RTYPE;
            ctl.regWrite=1'b1;
            ctl.selectB='0;
            if (rf7==7'b0000001) begin
                ctl.alu_cut='1;
                unique case (f3)
                    F3_MUL:begin
                        ctl.alufunc=MUL;
                    end
                    F3_DIV:begin
                        ctl.alufunc=DIV;
                        ctl.alu_sign='1;
                    end
                    F3_DIVU:begin
                        ctl.alufunc=DIV;
                    end
                    F3_REM:begin
                        ctl.alufunc=REM;
                        ctl.alu_sign='1;
                    end
                    F3_REMU:begin
                        ctl.alufunc=REM;
                    end
                    default:     illegal_instr='1;

                endcase
            end
            else begin
            unique case (f3)
                F3_ADD_SUBW:begin
                    ctl.extAluOut='1;
                    unique case(rf7)
                    F7_R_ADD:ctl.alufunc=ADD;
                    F7_R_SUB:ctl.alufunc=SUB;
                    default:begin
                        illegal_instr='1;

                    end
                endcase
                end
                F3_SRW:begin
                    unique case(f6)
                    F6_LOGIC:ctl.alufunc=SRLW;
                    F6_ARITH:ctl.alufunc=SRAW;
                     default:begin
                        illegal_instr='1;

                    end
                endcase
                end
                F3_SLLW:begin
                    ctl.alufunc=SLLW;
                    ctl.extAluOut='1;
                end
                 default:begin
                    illegal_instr='1;

                    end
            endcase
            end
        end
        F7_JAL:begin
            ctl.op=JTYPE;
            ctl.regWrite=1'b1;
            ctl.wbSelect=2'b10;
            ctl.branch=J;
        end
        F7_JALR:begin
            ctl.pcTarget=1'b1;
            ctl.op=ITYPE;
            ctl.regWrite=1'b1;
            ctl.wbSelect=2'b10;
            ctl.selectB=1'b1;
            ctl.branch=J;

        end
        F7_BTYPE:begin
            ctl.op=BTYPE;
            ctl.alufunc=SUB;
                unique case (f3)
                F3_BEQ:begin
                    ctl.branch=BRANCH_BEQ;
                end
                F3_BNE:begin
                    ctl.branch=BRANCH_BNE;
                end
                F3_BLT:begin
                    ctl.branch=BRANCH_BLT;
                end
                F3_BGE:begin
                    ctl.branch=BRANCH_BGE;
                end
                F3_BLTU:begin
                    ctl.branch=BRANCH_BLTU;
                end
                F3_BGEU:begin
                    ctl.branch=BRANCH_BGEU;
                end
                default:begin
                illegal_instr='1;

                end 
            endcase
        end
        F7_AUIPC:begin
            ctl.op=UTYPE;
            ctl.alufunc=ADD;
            ctl.regWrite=1'b1;
            ctl.selectA=1'b1;
            ctl.selectB=1'b1;
        end
        F7_LUI:begin
            ctl.op=UTYPE;
            ctl.regWrite=1'b1;
            ctl.wbSelect=2'b11;
        end
        F7_LD:begin
            ctl.op=ITYPE;
            ctl.regWrite=1'b1;
            ctl.selectB=1'b1;
            ctl.alufunc=ADD;
            ctl.wbSelect=2'b01;
            ctl.memRw=2'b01;
            ctl.mem_unsigned=f3[2];
            unique case (f3[1:0])
                2'b00:ctl.msize=MSIZE1;
                2'b01:ctl.msize=MSIZE2;
                2'b10:ctl.msize=MSIZE4;
                2'b11:ctl.msize=MSIZE8;
                default:begin

                end
            endcase
//            ctl.msize={1'b0,f3[1:0]};
        end
        F7_SD:begin
            ctl.op=STYPE;
            ctl.selectB=1'b1;
            ctl.alufunc=ADD;
            ctl.memRw=2'b10;
            unique case (f3[1:0])
                2'b00:ctl.msize=MSIZE1;
                2'b01:ctl.msize=MSIZE2;
                2'b10:ctl.msize=MSIZE4;
                2'b11:ctl.msize=MSIZE8;
                default:begin
                end
            endcase
        end
        F7_CSR:begin
            if (f3==F3_CSRRW||f3==F3_CSRRC||f3==F3_CSRRS) begin
                ctl.regWrite='1;
            end
        end
        default:begin
            illegal_instr='1;
        end
    endcase
end
    
endmodule
`endif 