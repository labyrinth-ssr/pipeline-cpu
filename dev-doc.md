2022-03-15
16：56
学习sv语法
17：30
19:58

2022-03-19
17:18: system verilog syntax learning by video
![](https://fducslg.github.io/ICS-2021Spring-FDU/asset/lab1/5-stage.png)
![](
    https://shine-jeep-92f.notion.site/image/https%3A%2F%2Fs3-us-west-2.amazonaws.com%2Fsecure.notion-static.com%2F81a026fe-36c7-474c-bbab-b29c772284a4%2F%E6%88%AA%E5%B1%8F2022-02-28_%E4%B8%8B%E5%8D%882.37.33.png?table=block&id=07f5676e-ebb2-41c9-bffd-ada2ef083115&spaceId=ccad7152-c227-4847-9ed9-652efa1acf42&width=1750&userId=&cache=v2
)

先只做第一条addi，
addi xori ori andi lui jal beq ld sd add sub and or xor auipc jalr
   
beq:
Ifetch: 取指令并计算PC+4
- Reg/Dec:从寄存器取数，同时指令在译码器进行译码
- Exec: 执行阶段
    - ALU中比较两个寄存器的大小（做减法）
    - Adder中计算转移地址
- Mem: 如果比较相等, 则：
    - 转移目标地址写到PC
-  Wr: 加一个空写阶段
jalr:

beq和jalr指令的区别
关于如何取pc的问题，随着时钟变化，ireq变化，
如何实现跳转？
指令计数取指令。pc控制ireq。

每次都选择恐惧症发作，关于你需要几个interface的问题。除了全阶段的，暴露在core里面的都用interface吧。这样就可以看到数据的流向了。但是怎么连接呢。

竞争：
写 寄存器与存储。
regwr,regadr,
memwr,memadr

如何表示ctrl
已知这是好几位的，我肯定需要很多一位的控制信号，而不是整个ctrl，不然会变成一堆case。唉。
先把单周期情况的搞完吧。
如何实现跳转，当它译码出

我决定了！除了写后读，全部按照mips的ppt来吧。
先把架构搭出来再一点点改。

hazard做什么事？
只有stall，如何stall。从mem读数据到寄存器，然后取寄存器进行运算。
必须等到lw到writeback，and才可以到execute阶段。
指令译码完成后不执行，也就是decode fetch锁存，保持原来的值。同时flush e.

阻塞法解决数据冲突。
数据冒险在于写后读。也就是在decode阶段
确保电路图正确。
减少修改，除非严重影响后续。

lwstallD: memtoRegE & 
如何识别lw指令。以及对于lw指令
1.lw指令在memory握手后得到数据，此时的为什么不是stallE，因为寄存器在d阶段。
2.为什么branch要stall不能转发？就是说，branch取寄存器，我上一步写入的数据现在e阶段没被算出来，所以无解。
为什么还要看m阶段memtoreg？
为什么每次进度都这么慢？？不可以！
forward 两个来源。

跳转问题：多取了一条指令，草不知道发生了什么但是成功了

    //读取过程：
    // assign data = data_from_sets[get_index(addr)];
    //一个cacheline的index，
    //行为：input addr，get index，找到cacheline[index],比对valid（遍历associativity），
    //如果valid全0，miss，ram交互（fetch）
    //先看valid后看tag，若hit，返回数据

woc，看起来cache是用ram实现的？
    //关于dreq.addr，64位地址，每个地址里面存了1个byte，取的时候以word为单位，so<<3，start就是可以双字
    
    // for (genvar i = 0; i < SET_NUM; i++) begin 
    //     cache_line_t cache_line_group [ASSOCIATIVITY-1:0];
    //     always_comb begin
    //         if (i==get_index(dreq.addr)) begin
    //             line_from_cache=cache_line_group;
    //         end
    //     end
    // end 

    // for (genvar i = 0;i<ASSOCIATIVITY ; i++) begin
    //     always_comb begin
    //         if (line_from_cache.meta.valid&&(line_from_cache.meta.tag==get_tag(dreq.addr))) begin
    //             hit='1;
    //             cache_data=line_from_cache.data[get_offset(dreq.addr)];
    //         end
    //     end
    // end
    typedef struct packed {
        meta_t meta,
        u64 data [WORDS_PER_LINE-1:0],
        u1 dirty,
        index_t counter  
    } cache_line_t;
    cache_line_t line_from_cache [ASSOCIATIVITY-1:0];
                // line_rdata=data_rdata[(i+1)*DATA_BITS-1:i*DATA_BITS];
                // line_wdata=line_rdata;
                // for (int j = 0; j < 8; j++)
                //     if (req.strobe[j])
                //         line_wdata[get_offset(req.addr)][j] = req.data[j];
                // ram.wdata[(i+1)*DATA_BITS-1:i*DATA_BITS]=line_wdata;