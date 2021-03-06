`ifndef __ICACHE_SV
`define __ICACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`endif

module ICache
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
        parameter WORDS_PER_LINE = 16,
        parameter ASSOCIATIVITY = 4,
        parameter SET_NUM = 4
	)(
	input logic clk, reset,
	input  ibus_req_t  ireq,
    output ibus_resp_t iresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE
	/* TODO: Lab3 Cache */
    // dbus_req_t req;
	dbus_req_t dreq;
	dbus_resp_t dresp;
	assign iresp = `DRESP_TO_IRESP(dresp, ireq);
	assign dreq=`IREQ_TO_DREQ(ireq);
    localparam DATA_BITS = $bits(word_t)*WORDS_PER_LINE;
    localparam ASOC_BITS = $clog2(ASSOCIATIVITY);
    localparam DATA_INDEX_BITS = $clog2(SET_NUM*WORDS_PER_LINE*ASSOCIATIVITY);
    localparam type state_t = enum logic[2:0] {
        INIT,FETCH,FLUSH,UNCACHE
    };
    localparam type offset_t = logic [OFFSET_BITS-1:0];
    localparam type index_t = logic [INDEX_BITS-1:0];
    localparam type tag_t = logic [TAG_BITS-1:0];
    localparam type asoc_index_t = logic [ASOC_BITS-1:0];
    localparam OFFSET_BITS = $clog2(WORDS_PER_LINE);
    localparam INDEX_BITS = $clog2(SET_NUM);
    localparam TAG_BITS = 31 - 3- INDEX_BITS - OFFSET_BITS; /* Maybe 32, or smaller */
    typedef struct packed {
        u1 valid;
        u1 dirty;
        tag_t tag;
    } meta_t;
    u2 [ASSOCIATIVITY-1:0] set_lru;
    u2 [SET_NUM*ASSOCIATIVITY-1:0] lru_reg;

    localparam META_BITS = $bits(meta_t);
    localparam type rmeta_t = logic [$bits(meta_t) * ASSOCIATIVITY-1:0];
    localparam type data_index_t = logic [DATA_INDEX_BITS-1:0];
    function offset_t get_offset(addr_t addr);//MSIZE8，对应一个word
        return addr[3+OFFSET_BITS-1:3];
    endfunction
    function index_t get_index(addr_t addr);
    return addr[3+INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS+3];
    endfunction
    function tag_t get_tag(addr_t addr);
    return addr[3+INDEX_BITS+OFFSET_BITS+TAG_BITS-
    1:3+INDEX_BITS+OFFSET_BITS];
    endfunction
    struct packed {
        logic en;
        strobe_t strobe;
        u64   wdata;
    } data_ram;
        struct packed {
        logic en;
        logic [ASSOCIATIVITY-1:0] strobe;
        rmeta_t wdata;
        } meta_ram;
    state_t state;
    index_t counter;
    u1 hit,is_full,ram_reset;
    u64 cache_rdata;
    index_t set_index;
    u64 data_rdata;
    rmeta_t meta_rdata;
    meta_t [ASSOCIATIVITY-1:0] meta_rdata_arr;
    meta_t [ASSOCIATIVITY-1:0] meta_wdata_arr;
    logic [ASSOCIATIVITY-1:0] meta_signal;
    logic [ASSOCIATIVITY-1:0] valid_signal;
    asoc_index_t hit_index,empty_index;
    asoc_index_t replace_index;
    asoc_index_t replace_index_in;

    u1 fetched;
    offset_t offset;
    data_index_t data_index;

    for (genvar i = 0; i < SET_NUM; i++) begin
		assign meta_rdata_arr[i] = meta_rdata[META_BITS*(i+1)-1:i*META_BITS];
        assign meta_ram.wdata[META_BITS*(i+1)-1:i*META_BITS]=meta_wdata_arr[i];
	end
    assign set_index=ram_reset?counter: get_index(dreq.addr);

    // assign meta_rdata_arr[1]=meta_rdata[META_BITS*2-1:META_BITS];
    // assign meta_rdata_arr[0]=meta_rdata[META_BITS-1:0];
    assign creq.valid    = state == FETCH || state == FLUSH ||state == UNCACHE ;
    assign creq.is_write = state == FLUSH ||(state == UNCACHE&&(|dreq.strobe));
    assign creq.size     = state == UNCACHE? dreq.size:MSIZE8;
    // assign creq.addr     = state == FLUSH? {meta_rdata_arr[replace_index].tag,set_index,7'b0} : {dreq.addr[63:7],7'b0};
    assign creq.strobe   = state == UNCACHE? dreq.strobe: 8'b11111111; 
    assign creq.data     = state == UNCACHE?dreq.data: data_rdata;
    assign creq.len      = state ==UNCACHE?MLEN1:MLEN16;//word_per_line
	assign creq.burst	 = state ==UNCACHE?AXI_BURST_FIXED:AXI_BURST_INCR;
    assign cache_rdata=data_rdata;
    assign dresp.data= state == UNCACHE? cresp.data:cache_rdata;
    assign dresp.data_ok = state==UNCACHE? cresp.last:hit;
    assign dresp.addr_ok = state == INIT||state==UNCACHE;
    // assign meta_ram.wdata={meta_wdata_arr[1],meta_wdata_arr[0]};

    always_comb begin
        creq.addr='0;
        if (state==FLUSH) begin
            creq.addr={dreq.addr[63:31],meta_rdata_arr[replace_index].tag,set_index,7'b0};
        end else if (state==UNCACHE) begin
            creq.addr=dreq.addr;
        end else begin
            creq.addr={dreq.addr[63:7],7'b0};
            
        end
    end

    always_ff @(posedge clk) begin
    if (~reset) begin
        unique case (state)
        // IDLE: if (dreq.valid) begin
        //     ram_reset<='0;
        //     state  <= dreq.addr[31] == 0?UNCACHE:INIT;
        //     // req    <= dreq;
        //     fetched<='0;
        //     offset<='0;
        //     flushed<='0;
        // end
        UNCACHE: if (cresp.ready) begin
            if (cresp.last) begin
                state<=INIT;
            end else begin
                state<=UNCACHE;
            end
        end
        INIT:begin if (dreq.valid) begin
            for (int i=0; i<ASSOCIATIVITY; ++i) begin
                lru_reg[set_index*ASSOCIATIVITY+i]<=set_lru[i];
            end
            ram_reset<='0;
            // req    <= dreq;
            fetched<='0;
            offset<='0;
            if (dreq.addr[31] == 0) begin
                state<=UNCACHE;
            end else
            if (hit) begin
                state<=INIT;
            end else if (is_full&& meta_rdata_arr[replace_index_in].dirty) begin
                state<=FLUSH;
                replace_index<=replace_index_in;
            end else begin
                state<=FETCH;
                replace_index<=empty_index;
            end
        end
        end
        FETCH: begin
            offset<='0;
        if (cresp.ready) begin
            offset <= offset + 1;
            if (cresp.last) begin
                state<=INIT;
                fetched<='1;
            end else begin
                state<=FETCH;
            end
        end
        end
        FLUSH: begin
            if (cresp.ready) begin
            state  <= cresp.last ? FETCH : FLUSH;
            offset <= offset + 1;
        end
        end
            
        default:;
        endcase
    end else begin
        // {req, offset} <= '0;
        // offset<='0;
        counter_temp<=SET_NUM-1;
        counter<= counter==counter_temp[INDEX_BITS-1:0]?0:(counter+1);
        ram_reset<=reset;
        // fetched<='0;
        // flushed<='0;
    end
    end
    int counter_temp;

    always_comb begin
        meta_ram.en = '0;data_ram='0; hit='0;meta_signal='0;data_index='0;empty_index='0;valid_signal='0;is_full='0;
        meta_wdata_arr=meta_rdata;replace_index_in='0; meta_ram.strobe = '0;
        for (int i=0; i<ASSOCIATIVITY; ++i) begin
                set_lru[i]=lru_reg[set_index*ASSOCIATIVITY+i];
            end
    unique case (state)
    // IDLE:begin
    //     if (ram_reset) begin
    //         meta_ram.en='1;
    //         meta_wdata_arr[0].valid='0;
    //         meta_wdata_arr[1].valid='0;
    //         meta_ram.strobe='1;
    //     end
    // end
    INIT: begin
        if (ram_reset) begin
            meta_ram.en='1;
            for (int i=0; i<SET_NUM; ++i) begin
                meta_wdata_arr[i].valid='0;
                meta_wdata_arr[i].valid='0;
            end
            meta_ram.strobe='1;
        end else begin
        if (fetched) begin
            meta_wdata_arr[replace_index].valid='1;
            meta_wdata_arr[replace_index].tag=get_tag(dreq.addr);
            meta_ram.strobe[replace_index]=1'b1;
            meta_ram.en='1;
            data_ram.en='1;
            data_ram.strobe=dreq.strobe;
            data_index= set_index*(ASSOCIATIVITY*WORDS_PER_LINE)+replace_index*WORDS_PER_LINE+{4'b0,get_offset(dreq.addr)};
            data_ram.wdata=dreq.data;
            hit='1;
            if (|dreq.strobe) begin
                meta_wdata_arr[replace_index].dirty='1;
            end
        end else begin
            for (int  i=0; i<ASSOCIATIVITY; i++) begin
            meta_signal[i]=meta_rdata_arr[i].valid&(meta_rdata_arr[i].tag==get_tag(dreq.addr));
            valid_signal[i]=meta_rdata_arr[i].valid;
            if (meta_signal[i]) begin      
                meta_ram.en='1;
                data_ram.en='1;
                data_ram.strobe=dreq.strobe;
                data_index=set_index*(ASSOCIATIVITY*WORDS_PER_LINE)+i[INDEX_BITS-1:0]*WORDS_PER_LINE+{4'b0,get_offset(dreq.addr)};
                data_ram.wdata=dreq.data;
                if (~(|dreq.strobe)) begin
                    meta_ram.strobe[i]=1'b1;
                    meta_wdata_arr[i].dirty='1;
                end
                for ( int j= 0 ;j<SET_NUM ; ++j) begin
                    if (set_lru[j]<set_lru[i]) begin
                        set_lru[j]+=1;
                    end
                end
                set_lru[i]='0;
            end else if (~meta_rdata_arr[i].valid) begin
                empty_index=i[INDEX_BITS-1:0];
            end 
        end
        hit=|meta_signal;
        is_full=&valid_signal;
        if ((~hit)) begin
            if (~is_full) begin
                for ( int j= 0;j<SET_NUM  ; ++j) begin
                    if (j[INDEX_BITS-1:0]!=empty_index) begin
                    set_lru[j]+=1;
                    end
                end
                set_lru[empty_index]='0;
            end else begin
                for ( int j= 0;j<SET_NUM  ; ++j) begin
                    if (set_lru[j]==3) begin
                        replace_index_in=j[INDEX_BITS-1:0];
                        set_lru[j]='0;
                    end else begin
                        set_lru[j]+=1;
                    end
                end
            end
            // data_index=set_index*(ASSOCIATIVITY*WORDS_PER_LINE)+empty_index*WORDS_PER_LINE+{4'b0,get_offset(dreq.addr)};
        end 
        end
        end
    end
    FETCH: begin
        data_index= set_index*(ASSOCIATIVITY*WORDS_PER_LINE)+replace_index*WORDS_PER_LINE+{4'b0,offset};
        data_ram.strobe = '1;
        data_ram.wdata=cresp.data;
        data_ram.en=1;
    end
    FLUSH:begin
        data_index= set_index*(ASSOCIATIVITY*WORDS_PER_LINE)+replace_index*WORDS_PER_LINE+{4'b0,offset};
    end
    UNCACHE: ;
    default: ;
    endcase
    end

    RAM_SinglePort #(
		.ADDR_WIDTH(DATA_INDEX_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
    ) ram_data (
        .clk(clk), .en(data_ram.en),
        .addr(data_index),
        .strobe(data_ram.strobe),
        .wdata(data_ram.wdata),
        .rdata(data_rdata)
    );

    RAM_SinglePort #(
		.ADDR_WIDTH(INDEX_BITS),
		.DATA_WIDTH($bits(meta_t) * ASSOCIATIVITY),//meta读取,associavity�?
		.BYTE_WIDTH($bits(meta_t)),
		.READ_LATENCY(0)
    ) ram_meta(
        .clk(clk), .en(meta_ram.en),
        .addr(set_index),
        .strobe(meta_ram.strobe),
        .wdata(meta_ram.wdata),
        .rdata(meta_rdata)
    );



	
`else

	dbus_resp_t dresp;
	DCache lazy (
		.clk, .reset,
		.dreq(`IREQ_TO_DREQ(ireq)),
		.dresp,
		.creq,
		.cresp
	);
	assign iresp = `DRESP_TO_IRESP(dresp, ireq);
`endif

endmodule

`endif
