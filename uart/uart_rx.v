// 这是一个UART的接收模块
/*
    接收到的数据后要发送valid脉冲，表明接收到的数据是否是正确的：主要是1：接收完停止位 2：奇偶正确
    接收到的数据要打两拍来同步

*/
module uart_rx#(
    parameter                           P_SYSTEM_CLK      = 50_000_000  ,   //输入时钟频率
    parameter                           P_UART_BUADRATE   = 9600        ,   //波特率
    parameter                           P_UART_DATA_WIDTH = 8           ,   //数据宽度
    parameter                           P_UART_STOP_WIDTH = 1           ,   //1或者2
    parameter                           P_UART_CHECK      = 0               //None=0 Odd-1 Even-2
)(                  
    input                               i_clk                           ,
    input                               i_rst                           ,

    input                               i_uart_rx                       ,   //uart的接收数据线，异步。

    output [P_UART_DATA_WIDTH - 1 : 0]  o_user_rx_data                  ,
    output                              o_user_rx_valid
);

reg     [1:0]                               r_uart_rx                               ;       // 用来打拍
reg     [15:0]                              cnt                                     ;
reg                                         r_rx_check                              ;


// 常规操作 寄存输出并绑定
reg     [P_UART_DATA_WIDTH - 1 : 0]         ro_user_rx_data                         ;
reg                                         ro_user_rx_valid                        ;

assign                                      o_user_rx_data  =   ro_user_rx_data     ;
assign                                      o_user_rx_valid =   ro_user_rx_valid    ;


// 首先对输出打拍
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_uart_rx <= 'b11;
    else
        r_uart_rx <= {r_uart_rx[0], i_uart_rx};              // r_uart_rx[1]就是打两拍后的输入
end

// 这里也需要计数器判断现在是多少数据 只对数据做输出 校验码之类不要
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        cnt <= 'd0;
    else if (r_uart_rx == 2'd01 || cnt >0) 
        cnt <= cnt + 1;
    else if (cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH + 1 && P_UART_CHECK > 0)      // 存在校验位
        cnt <= 'd0;
    else if (cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        cnt <= 'd0;
    else
        cnt <= cnt;
end

// 考虑输出寄存器
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_rx_data <= 'd0;
    else if (cnt >= 'd1 && cnt <= P_UART_DATA_WIDTH) 
        ro_user_rx_data <= {ro_user_rx_data[6:0], r_uart_rx[1]};
    else
        ro_user_rx_data <= ro_user_rx_data;
end

// 考虑valid
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_rx_valid <= 'd0;
    else if (cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        ro_user_rx_valid <= 'd1;

    // 考虑在有奇偶校验时 是否对上了奇偶校验                !!!!!!
    else if (cnt == P_UART_DATA_WIDTH + 1 && P_UART_CHECK == 1 && r_uart_rx[1] == !r_rx_check)
        ro_user_rx_valid <= 'd1;
    else if (cnt == P_UART_DATA_WIDTH + 1 && P_UART_CHECK == 2 && r_uart_rx[1] == r_rx_check)
        ro_user_rx_valid <= 'd1;

    else
        ro_user_rx_valid <= 'd0;
end

// 计算奇偶
always@(posedge i_clk or posedge i_rst)             // !!!!!!
begin
    if (i_rst)
        r_rx_check <= 'd0;
    else if (cnt >= 1 && cnt <= P_UART_DATA_WIDTH)
        r_rx_check <= r_rx_check ^ r_uart_rx[1];
    else
        r_rx_check <= 'd0;
end

endmodule

// 这里要考虑好接收数据的奇偶自检验
// 比接收数据慢一拍 会在data_width+1处输出奇偶值
// 不同于tx tx在第八个数据就有了check 但是tx要输出check也在8+1处
