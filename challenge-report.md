# 挑战课题报告
20302010059-孙姝然

## microbench截图
![](https://cdn.nlark.com/yuque/0/2022/png/22909236/1656341858470-0ed27660-4281-4d64-b0ed-35ffdcc5303f.png)
## 内容
Read_Latency = 1 的 data RAM，和read_latency=0 的meta RAM 。两级 Memory 流水段 ，data RAM 大小为 64KB，meta RAM 大小 < 2 KB。
## DCache改动
- 增加一个flag（late_read_cnt），控制data_ok在读取命中的后一周期置1
- 在flush状态下，增加read_buffer数组，率先遍历cache line，记录下要通过cbus写回的数据，接着根据传输协议，控制数组index传输数据
- 每隔2^25个周期，打印累计命中率。
## 流水线改动
memory分为两个流水段。
m1：给出dreq，完成writedata
m2:一周期延迟的read给出数据，完成readdata。
harzard：与load指令相关的写后读冲突增加一周期阻塞，在m1与m2阶段均类似原本的memory设置阻塞信号。其他写后读冲突增加一个转发的出发点。