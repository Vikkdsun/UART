# UART学习笔记
uart project by verilog

Create Date:2023/9/11 22:29

## UART串口
包括FIFO、PLL、uart_tx和uart_rx几个小模块组成

1、使用过采样方法减低误码率

2、使用fifo驱动tx

3、还有问题等待解决


### 绘制了tx的简单时序逻辑
rx没有绘制，比较简单。

项目中的难点还是在于一些基础时序等问题，比如rx中check的时序、tx中的各种时序、drive模块内的锁的时序以及top中的锁的时序。

此外，难点在于某个信号的控制条件的确定。

![tx_time](https://github.com/Vikkdsun/UART/assets/114153159/a46c533e-0a2f-44b4-90ea-cedf648f591f)

图中展示tx的时序。

### 更新记录：

2023/10/23 16:15  :  更新了项目的tb文件，修改了bug。

（完）
