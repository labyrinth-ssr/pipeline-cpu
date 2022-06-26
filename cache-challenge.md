命中率统计
miss，hit
放大cache，
memory 需要两个周期，
计算大小
不是做实验，看microbench里面是什么排序，然后针对性优化，周期输出也要改。
实现：可以，就放大，
纯粹就是让ram读更加花时间，，
但也因此限制
为什么需要两级memory？//不管了orz
为什么失败？
在data_ok时
当上升沿来临时，才进入该指令的管辖范围，
但是，对于hit的怎么说？
草，差点破防了
read_latency
在每个readhit的时候延迟一个周期
问题在于这到底算不算read latency。
1. 一开始hit的read，在下降沿接收到dreq后，直接返回hit，
   如果late，并不是等一周期，而是直接在本次的上升沿返回ok，这是不合理的。
   应该在下一周期的上升沿返回data_ok。
15:38 random step
别管ik了