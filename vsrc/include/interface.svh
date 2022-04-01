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

interface pcreg_intf(output pc);
    u64 pc_nxt,pc;
    modport pc_select(output pc_nxt);
    modport pcreg(output pc,input pc_nxt);
    
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
    // u64 dataM;
    // u64 dataM_nxt;

    modport memory (output dataM_nxt);
    modport mreg_intf(input dataM_nxt,output dataM);
    modport writeback (input dataM);
    
endinterface

interface pcselect_intf(input u64 pcplus4);
    u1 branch_taken;
    u64 pcbranch;//(for beq,pc += sext(offset))

    u64 pc_selected;

    // modport fetch (input pc_selected);
    modport pcreg (input pc_selected);
    modport pcselect (input pcbranch,input pcplus4,input branch_taken, output pc_selected);
    
endinterface

interface regfile_intf#(
	parameter READ_PORTS = AREG_READ_PORTS,
	parameter WRITE_PORTS = AREG_WRITE_PORTS
)(input u64 [WRITE_PORTS-1:0] wd);
    output u64 [READ_PORTS-1:0] rd1, rd2;
    input creg_addr_t [READ_PORTS-1:0] ra1, ra2;
    input creg_addr_t [WRITE_PORTS-1:0] wa;
	input u1 [WRITE_PORTS-1:0] wvalid;
    modport decode (input rd1,input rd2,output ra1,output ra2);
    modport regfile(input ra1,input ra2,output rd1,output rd2,input wa,input wvalid,input wd);
    modport writeback(output wa,output wvalid)
endinterface

// interface forward_intf();
    
// endinterface

interface hazard_intf();
    

    
    modport  pcreg(input enable,flush);
    modport  dreg(input enable,flush,output ctrl);
    modport  ereg(input enable,flush);
    modport  mreg(input enable,flush);

endinterface

// interface csr_intf();
    
// endinterface


`endif 