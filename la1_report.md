# lab1五级流水线实验报告

20302010059-孙姝然

## 简易电路图

![](https://cdn.nlark.com/yuque/0/2022/jpeg/22909236/1648990446807-0c00de68-4d29-4030-b9bd-662375686345.jpeg?x-oss-process=image%2Fresize%2Cw_1754%2Climit_0)
![](https://cdn.nlark.com/yuque/0/2022/jpeg/22909236/1648991828425-805d04b2-e41f-49c1-b21d-074b6068de64.jpeg?x-oss-process=image%2Fresize%2Cw_1536%2Climit_0)

## 流水线冲突
### 跳转
- jal和jalr:根据电路图，在execute阶段算出跳转指令后在memory阶段写回，写回数据包括跳转地址和跳转控制信号。采用插nop指令的方法，在execute阶段将图中的dreg和ereg数据清空。在memory阶段将图中dreg，ereg，mreg数据清空。
- beq指令：在memory获得aluout=0的结果后与branch指令相与得到跳转控制信号写回fetch阶段pcselect。同样采用插nop指令的方式，延迟三周期等到获得正确跳转地址后再开始实行，具体做法为，在execute阶段将图中的dreg和ereg数据清空。
### 数据冲突（写后读冲突）
以输出信号（datapath输出控制信号作为hazard模块的输入，如图所示）产生的阶段分为三种：
execute、memory、writeback阶段分别输出此阶段是否为写寄存器指令以及写入寄存器的地址），并将写入地址与decode阶段rs1、rs2进行比较（这里ITYPE指令最特殊，不需要比较rs2，增加一个mux，将其rs2置为0），比较相同，满足写后读冲突，就阻塞dreg、freg（防止数据丢失），flush ereg（防止指令重复执行）