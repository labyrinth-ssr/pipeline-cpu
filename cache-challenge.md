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
草啊，我想出去玩啊orz。去商场逛逛？唉，还有两天。
不想写了orzorzorzorz。你不写还能做什么呢，肚子不舒服吗？
read_latency=0
输入后当周期返回
==1
下一周期返回
==2，下下周期返回
懂了吗？没懂，真没懂。

当 cache 的逻辑变得复杂以后，加上大容量 cache 访存的延时，如果要求 cache 单周期返回数据可能会拉低整个 CPU 的频率。经典的解决办法就是把 cache 切成多级流水线。这样虽然增加了访存的延时，但是提高了访存并行度，从而提高了 cache 的带宽。
事实上清华的是没有多端口cache的。
cache第一个阶段只是在计算地址。
我差不多懂了！

首先，如何在cache部分改造，使其能够完成正常的功能
<!-- cache内部的流水线，其实就是增加一个状态。 -->
把这个状态完成之后，再来解决冲突的问题。
增加一个流水段，会发生什么？
对于read latency==1，m1阶段对应delay state，m2阶段对应init阶段。
冲突？lwstall增加一种情况。所以不会出现新的情况。
md，如果是三级呢？lwstall再增加一种咯。
1.cache中不连续的dreq，向着正确的方向前进吧！！
read hit：第一周期，给出

d_wait的影响：fetch阶段，什么叫d_wait是
d_wait,若指进入m阶段开始到dreap。dataok，
什么时候需要等待，就是在没有hit的时候creq的要求，将creq替换作为dwait
将所有原本的关系保留在m1阶段。
开始！一条普通无相关的load指令进入m1，dreq给到dcache，
dresp直接assign到dataM done

对于hit的东西，都是
关于转发，对于前一条指令是