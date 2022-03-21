`ifndef __INTERFACE_SVH
`define __INTERFACE_SVH

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif 
// `include "include/execute_pkg.sv"
// `include "include/memory_pkg.sv"
// `include "include/writeback_pkg.sv"
// `include "include/forward_pkg.sv"
// `include "include/csr_pkg.sv"

import common::*;
import pipes::*;
// import decode_pkg::*;// import execute_pkg::*;
// import memory_pkg::*;
// import writeback_pkg::*;
// import forward_pkg::*;
// import csr_pkg::*;

interface pcreg_intf();
    u64 pc_nxt,pc;

    modport pcselect(output pc_nxt);
    modport pcreg(output pc,input pc_nxt);
    modport fetch(input pc);
    
endinterface

interface dreg_intf();
    fetch_data_t dataF,dataF_nxt;

    modport fetch (output dataF_nxt);
    modport dreg (input dataF_nxt,output dataF);
    modport decode (input dataF);
endinterface //对于接口而言，fetch把fataF_nxt给dreg,dreg把dataF给decode

interface ereg_intf();
    decode_data_t dataD,dataD_nxt;
    modport decode(output dataD_nxt);
    modport ereg(input dataD_nxt,output dataD);
    modport execute(input dataD);
endinterface

interface mreg_intf();
    execute_data_t dataE,dataE_nxt;

    modport execute (output dataE_nxt);
    modport mreg_intf(input dataE_nxt,output dataE);
    modport memory (input dataE);
endinterface

interface wreg_intf();
    // execute_data_t dataW,dataW_nxt;
    u64 dataM;
    u64 dataM_nxt;

    modport memory (output dataM_nxt);
    modport mreg_intf(input dataM_nxt,output dataM);
    modport writeback (input dataM);
    
endinterface

interface pcselect_intf();
    // u1 branch_taken;
    // u64 pcbrach;

    // u1 jr;
    // u64 pcjr;

    u64 pc,pcplus4;

    // modport pcselect();
    modport fetch (input pcplus4);
    modport pcreg (output pc);
    modport pcselect (input pc,output pcplus4);
    // modport decode ();
    
endinterface

interface regfile_intf();
    u64 rd1,rd2;
    creg_addr_t ra1,ra2;
    modport decode (output ra1,output ra2);
    modport regfile(input ra1,input ra2,output rd1,rd2);
endinterface

interface forward_intf();
    
endinterface

interface hazard_intf();
    
endinterface

interface csr_intf();
    
endinterface


`endif 