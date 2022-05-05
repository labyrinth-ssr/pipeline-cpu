# lab2（握手总线）实验报告
20302010059-孙姝然
## 改动
1. 更多指令：主要修改了decoder和execute。将原本memory阶段的beq跳转放到execute阶段。rtype和itype指令的新增主要通过在alu中添加alufunc完成。
2. 握手总线：修改hazard。设置i_wait=ireq.valid && ~iresp.data_ok,d_wait=dreq.valid && ~dresp.data_ok作为hazard输入信号。i_wait期间，阻塞pcreg，flush freg。如果在i_wait期间有跳转信号产生，则还要阻塞ereg（维持跳转信号和跳转地址）flush mreg（防止重复执行）。在d_wait期间阻塞pcreg，flush freg（相当于插入nop），阻塞mreg（防止地址丢失），flushwreg（防止重复执行）。
3. 根据提供的代码在memory中新增readdata和writedata模块。适当修改防止多驱动。

## 测试通过截图
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1650803873135-6693c88c-c926-4862-b5af-d0684dcd6f8f.png?x-oss-process=image%2Fresize%2Cw_1651%2Climit_0)
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1650807194499-7019f473-1e98-4620-aaed-880f2b89c531.png)