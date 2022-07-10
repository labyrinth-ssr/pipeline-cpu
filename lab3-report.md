# lab3实验报告

20302010059-孙姝然

## 测试通过截图
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1653224471666-b2408d13-072e-46ca-8ae0-5ad853ae5cf4.png)
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1653223945996-6519195b-8e66-47b8-804f-54b939e9b7e2.png)
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1653224553131-5ce39a11-b83b-4af2-956c-d20b31f62f0f.png)

## 支持随机延迟，流水线改动

i_wait，e_wait，d_wait分别表示取指、多周期运算、取数据内存时需要等待的信号

- **e_wait与d_wait与流水线阻塞**：多周期乘除法器运算期间，stall F，D，E寄存器（阻塞E阶段之前的流水线），flush M寄存器（防止E阶段指令重复执行）e_wait期间若前一条指令正在d_wait，将flush M 改为stall M。（握手期间保持dreq不变）。d_wait先结束，变回flush M，指令依然不会重复执行。e_wait先结束，变为 stall M，E，D，F，即变回单独d_wait时的情况。
- **e_wait与数据冲突**：多周期运算若使用到前一条或两条指令写入的寄存器时，由于运算期间需阻塞的原因，无法复用转发（尝试使用寄存器存储运算数时失败了）。使用阻塞。对于一条多周期运算指令，在d阶段检测到需使用前两条指令写入寄存器时 stall F，stall D，flush E。（d_wait与e_wait期间自然阻塞前半部分流水线，所以不用考虑）
- **代码实现**：一个always_comb以i_wait，e_wait，d_awit，multi_stall，branch_stall为条件控制所有寄存器和stall。另一个always_comb中以de阶段、dm阶段读取写入寄存器比较为条件，并排除e_wait，控制forward信号