# lab3（cache）实验报告
20302010059-孙姝然

## 优化
### decode阶段分支跳转
改动：sext由execute阶段移动到decode阶段
在decode阶段比较x[ra1],x[ra2]（读取寄存器，注意写后读冲突）
forward：ForwardAD = (rsD !=0) AND (rsD == WriteRegM) AND RegWriteM
stall：译码阶段获得branch，依然需要阻塞1个周期。
branchstall = BranchD AND 
	 [RegWriteE AND ((WriteRegE == rsD) OR (WriteRegE == rtD)) 
                 OR 
	 [MemtoRegM AND ((WriteRegM == rsD) OR (WriteRegM == rtD))]
（e阶段写回，且ra1==写会或者，要确保d阶段拿到正确的值，寄存器值
（如果
什么情况下需要阻塞？转发无法实现？我比如我在decode阶段要寄存器的值，但是此时拿到的转发数据来自M阶段，面对一条以前的还是需要阻塞，即E阶段有写且有寄存器重合。另外，还有一种情况是，mem解读那。
当我本条指令跳转指令处于decode阶段时，上一条指令改写了我需要的寄存器（即regwriteE），无法通过转发完成，此时阻塞；上上条指令改写，它处于M阶段，有数据未写入，直接转发数据。若上上条lw指令。还有一种情况，虽然我上上条在mem阶段检测到regwrite，但是写的是mem数据，仍然需要阻塞。这种情况会被转发读取到，然后改变pc_branch,但是同时会被阻塞，所以pc_branch还是消失了，直到下一阶段读到数据写回后接着
stall:首先考虑两条相邻的情况：lwstallD:M阶段获得数据有延迟，这个延迟显然没法发给同时进行运算的e阶段。