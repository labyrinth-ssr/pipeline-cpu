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