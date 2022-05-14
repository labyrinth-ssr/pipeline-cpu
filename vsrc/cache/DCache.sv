`ifndef __DCACHE_SV
`define __DCACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`endif

module DCache 
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
        parameter WORDS_PER_LINE = 16,
        parameter ASSOCIATIVITY = 2,
        parameter SET_NUM = 8
	)(
	input logic clk, reset,
	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE
	/* TODO: Lab3 Cache */

    localparam type state_t = enum logic[2:0] {
        IDLE,INIT,FETCH,READY,FLUSH
    };
    localparam OFFSET_BITS = $clog2(WORDS_PER_LINE);
    localparam INDEX_BITS = $clog2(SET_NUM);
    localparam TAG_BITS = 64 - 3- INDEX_BITS - OFFSET_BITS; /* Maybe 32, or smaller */
    typedef struct packed {
        u1 valid;
        u1 dirty;
        tag_t tag;
    } meta_t;
    localparam META_BITS = $bits(meta_t);
    localparam DATA_BITS = $bits(word_t)*WORDS_PER_LINE;
    localparam ASOC_BITS = $clog2(ASSOCIATIVITY);
    localparam DATA_INDEX_BITS = $clog2(SET_NUM*WORDS_PER_LINE*ASSOCIATIVITY);

    localparam type offset_t = logic [OFFSET_BITS-1:0];
    localparam type index_t = logic [INDEX_BITS-1:0];
    localparam type tag_t = logic [TAG_BITS-1:0];
    localparam type asoc_index_t = logic [ASOC_BITS-1:0];
    localparam type rmeta_t = logic [$bits(meta_t) * ASSOCIATIVITY-1:0];
    localparam type rdata_t = logic [$bits(word_t) * ASSOCIATIVITY*WORDS_PER_LINE-1:0];
    localparam type line_data_t = logic [$bits(word_t) * WORDS_PER_LINE-1:0];

    function offset_t get_offset(addr_t addr)//MSIZE8，对应一个word
    return addr[3+OFFSET_BITS-1:3];
    endfunction
    function index_t get_index(addr_t addr)
    return addr[3+INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS+3];
    endfunction
    function tag_t get_tag(addr_t addr)
    return addr[3+INDEX_BITS+OFFSET_BITS+TAG_BITS-
    1:3+INDEX_BITS+OFFSET_BITS];
    endfunction

    struct packed {
        logic en;
        logic [ASSOCIATIVITY-1:0] strobe;
        u64   wdata;
        rmeta_t wmeta;
    } ram;

    state_t state;
    index_t counter;
    u1 hit;
    u64 cache_rdata;
    index_t ram_index;
    u64 data_rdata;
    rmeta_t meta_rdata;
    assign ram_index=get_index(req.addr);
    line_data_t line_rdata;
    line_data_t line_wdata;
    logic [ASSOCIATIVITY-1:0] meta_signal;
    asoc_index_t last_empty;
    u1 fetched;
    offset_t offset;

    //ready:表示数据已获得。两种情况：cresp last 或 hit
    //每次fetch 填满一个line 12word
    // CBus driver
    //与内存交互时，从内存取：12word，写回内存：12word
    //hit:meta符合
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE8;
    assign creq.addr     = req.addr;
    assign creq.strobe   = 8'b11111111;
    assign creq.data     = ram_rdata;
    assign creq.len      = MLEN16;//word_per_line
	assign creq.burst	 = AXI_BURST_INCR;

    assign dresp.data=cache_rdata;
    assign dresp.data_ok = state == READY;

    word_t save_fetched_data_line[WORDS_PER_LINE-1:0];
    always_ff @(posedge clk ) begin
        save_fetched_data_line[offset]<=cresp.data;
    end 

    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE: if (dreq.valid) begin
            state  <= INIT;
            req    <= dreq;
            fetched<='0;
            offset<='0;
        end
        INIT:begin
            state<=hit?IDLE:FETCH;
        end
        FETCH: if (cresp.ready) begin
            offset <= offset + 1;
            if (cresp.last) begin
                state<=INIT;
                fetched<='1;
            end else begin
                state<=FETCH;
            end
        end
        READY: begin
            state  <= IDLE;
        end
        FLUSH: if (cresp.ready) begin
            state  <= cresp.last ? IDLE : FLUSH;
            offset <= offset + 1;
        end
        endcase
    end else begin
        state <= IDLE;
        offset='0;
    end

    always_comb begin
        ram = '0;line_wdata='0;hit='0;line_rdata='0;meta_signal='0;cache_rdata='0;
    unique case (state)
    last_empty=0;
    INIT: begin
        if (fetched) begin
            ram.wdata[(last_empty+1)*DATA_BITS-1:last_empty*DATA_BITS]=save_fetched_data_line;
            ram.wmeta[(last_empty+1)*META_BITS-1:last_empty*META_BITS].valid='1;
            ram.wmeta[(last_empty+1)*META_BITS-1:last_empty*META_BITS].tag=get_tag(req.addr);
            ram.strobe[last_empty]=1'b1;
            cache_rdata=save_fetched_data_line[get_offset(req.addr)];
            hit='1;
        end else begin
            for (genvar  i=0; i<ASSOCIATIVITY; i++) begin
            meta_signal[i]=meta_rdata[(i+1)*META_BITS-1:i*META_BITS].valid&(meta_rdata[(i+1)*META_BITS-1:i*META_BITS].tag==get_tag(req.addr));
            if (meta_signal[i]) begin
                ram.en='1;
                line_rdata=data_rdata[(i+1)*DATA_BITS-1:i*DATA_BITS];
                line_wdata=line_rdata;
                for (int j = 0; j < 8; j++)
                    if (req.strobe[j])
                        line_wdata[get_offset(req.addr)][j] = req.data[j];
                ram.wdata[(i+1)*DATA_BITS-1:i*DATA_BITS]=line_wdata;
                ram.wmeta[(i+1)*META_BITS-1:i*META_BITS].dirty='1;
                if (~(|req.strobe)) begin
                    ram.strobe[i]=1'b1;
                end
                cache_rdata=line_rdata[get_offset(req.addr)];
            end else if (~meta_rdata[(i+1)*META_BITS-1:i*META_BITS].valid) begin
                last_empty=i;
            end
        end
        hit=|meta_signal;
        end
    end
    FETCH: begin
        ram.strobe = req.strobe;
        ram.wdata  = cresp.data;
    end
    default: ram = '0;
    endcase
    end

    RAM_SinglePort #(
		.ADDR_WIDTH(DATA_INDEX_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
    ) data_ram (
        .clk(clk), .en(ram.en),
        .addr(ram_index),
        .strobe(ram.strobe),
        .wdata(ram.wdata),
        .rdata(data_rdata)
    );

    RAM_SinglePort #(
		.ADDR_WIDTH(INDEX_BITS),
		.DATA_WIDTH($bits(meta_t) * ASSOCIATIVITY),//meta读取,associavity个
		.BYTE_WIDTH($bits(meta_t)),
		.READ_LATENCY(0)
    ) meta_ram (
        .clk(clk), .en(ram.en),
        .addr(ram_index),
        .strobe(ram.strobe),
        .wdata(ram.wmeta),
        .rdata(meta_rdata)
    );

`else

	typedef enum u2 {
		IDLE,
		FETCH,
		READY,
		FLUSH
	} state_t /* verilator public */;

	// typedefs
    typedef union packed {
        word_t data;
        u8 [7:0] lanes;
    } view_t;

    typedef u4 offset_t;

    // registers
    state_t    state /* verilator public_flat_rd */;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.
    offset_t   offset;

    // wires
    offset_t start;
    assign start = dreq.addr[6:3];

    // the RAM
    struct packed {
        logic    en;
        strobe_t strobe;
        word_t   wdata;
    } ram;
    word_t ram_rdata;

    always_comb
    unique case (state)
    FETCH: begin
        ram.en     = 1;
        ram.strobe = 8'b11111111;
        ram.wdata  = cresp.data;
    end

    READY: begin
        ram.en     = 1;
        ram.strobe = req.strobe;
        ram.wdata  = req.data;
    end

    default: ram = '0;
    endcase

    RAM_SinglePort #(
		.ADDR_WIDTH(4),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),      
		.READ_LATENCY(0)
	) ram_inst (
        .clk(clk), .en(ram.en),
        .addr(offset),
        .strobe(ram.strobe),
        .wdata(ram.wdata),
        .rdata(ram_rdata)
    );

    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata;

    // CBus driver
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE8;//1 word?
    assign creq.addr     = req.addr;
    assign creq.strobe   = 8'b11111111;
    assign creq.data     = ram_rdata;
    assign creq.len      = MLEN16;
	assign creq.burst	 = AXI_BURST_INCR;

    // the FSM
    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE: if (dreq.valid) begin
            state  <= FETCH;
            req    <= dreq;
            offset <= start;
        end

        FETCH: if (cresp.ready) begin
            state  <= cresp.last ? READY : FETCH;
            offset <= offset + 1;
        end

        READY: begin
            state  <= (|req.strobe) ? FLUSH : IDLE;
        end

        FLUSH: if (cresp.ready) begin
            state  <= cresp.last ? IDLE : FLUSH;
            offset <= offset + 1;
        end

        endcase
    end else begin
        state <= IDLE;
        {req, offset} <= '0;
    end

`endif

endmodule

`endif
