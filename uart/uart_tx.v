// 这是一个uart的发送模块
/*
    UART异步串口通信协议
    握手： 接受一个valid脉冲，ready拉低，拉低期间表示正在发送，不能发送其他
    提前一个周期拉高ready：在接受到最后一位之前（包括停止位和奇偶校验位的全部发送数据）就拉高ready，也就是ready变高时，正在发送最后一位
    
*/
module uart_tx#(
    parameter                           P_SYSTEM_CLK      = 50_000_000  ,   //输入时钟频率
    parameter                           P_UART_BUADRATE   = 9600        ,   //波特率
    parameter                           P_UART_DATA_WIDTH = 8           ,   //数据宽度
    parameter                           P_UART_STOP_WIDTH = 1           ,   //1或者2
    parameter                           P_UART_CHECK      = 0               //None=0 Odd-1 Even-2
)(                  
    input                               i_clk                           ,
    input                               i_rst                           ,

    output                              o_uart_tx                       ,

    input  [P_UART_DATA_WIDTH - 1 : 0]  i_user_tx_data                  ,
    input                               i_user_tx_valid                 ,
    output                              o_user_tx_ready                 
);

// 一些辅助
reg                                                 r_tx_check                                                  ;
reg     [15:0]                                      cnt                                                         ;
reg     [P_UART_DATA_WIDTH - 1:0]                   r_shift_data                                                ;   // 移位寄存器

// 基本操作：对输出做一个寄存器之后连线
reg                                                 ro_uart_tx                                                  ;
reg                                                 ro_user_tx_ready                                            ;

assign                                              o_uart_tx           =   ro_uart_tx                          ;
assign                                              o_user_tx_ready     =   ro_user_tx_ready                    ;

// 握手                 
assign                                              w_tx_active         =   i_user_tx_valid & o_user_tx_ready   ;

// 考虑ready的时序
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_tx_ready <= 'd1;

    // 这里考虑两个复位的问题：有无校验位 以及 提前一个周期
    else if (cnt == P_UART_STOP_WIDTH + P_UART_DATA_WIDTH - 1 && P_UART_CHECK == 0)         // 没有校验位
        ro_user_tx_ready <= 'd1;
    else if (cnt == P_UART_STOP_WIDTH + P_UART_DATA_WIDTH && P_UART_CHECK > 0)          // 存在校验位
        ro_user_tx_ready <= 'd1;

    else if (w_tx_active)
        ro_user_tx_ready <= 'd0;
    else
        ro_user_tx_ready <= ro_user_tx_ready;
end

// 考虑计数器
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        cnt <= 'd0;

    // 这里考虑一个复位的问题：有无校验位
    else if (cnt == P_UART_STOP_WIDTH + P_UART_DATA_WIDTH && P_UART_CHECK == 0)
        cnt <= 'd0;
    else if (cnt == P_UART_STOP_WIDTH + P_UART_DATA_WIDTH + 1 && P_UART_CHECK > 0)
        cnt <= 'd0;

    else if (!ro_user_tx_ready)
        cnt <= cnt + 1; 
    else
        cnt <= cnt;
end

// 考虑ro_uart_tx
// 首先要考虑 从低位发到高位 需要移位寄存器
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_shift_data <= 'd0;
    else if (w_tx_active)
        r_shift_data <= i_user_tx_data;
    else if (ro_user_tx_ready == 0)                     // !!!!!
        r_shift_data <= i_user_tx_data >> 1;
    else
        r_shift_data <= r_shift_data;

end

always@(posedge i_clk or posedge i_rst)                 // !!!!!
begin
    if (i_rst)
        ro_uart_tx <= 'd1;

    // 起始位
    else if (w_tx_active)
        ro_uart_tx <= 'd0;                
    // 校验位
    else if (cnt == P_UART_DATA_WIDTH && P_UART_CHECK > 0)
        ro_uart_tx <= P_UART_CHECK==1? ~r_tx_check : r_tx_check ;    
    // 停止位
    else if (cnt >= P_UART_DATA_WIDTH && cnt < P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        ro_uart_tx <= 'd1; 
    else if (cnt >= P_UART_DATA_WIDTH + 1 && cnt < P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK > 0)
        ro_uart_tx <= 'd1; 

    // 数据位
    else if (!ro_user_tx_ready)
        ro_uart_tx <= r_shift_data[0];    
    else 
        ro_uart_tx <= 'd1;                  // !!!!!
end

// 考虑校验位
// 奇校验：有奇数个1 输出0 反之 1           P_UART_CHECK = 1
// 偶校验：有偶数个1 输出0 反之 1           P_UART_CHECK = 2
always@(posedge i_clk or posedge i_rst)                     // !!!!!
begin
    if (i_rst)
        r_tx_check <= 'd0;
    else if (cnt == P_UART_DATA_WIDTH)      // 奇偶校验位输出后复位
        r_tx_check <= 'd0;
    else
        r_tx_check <= r_tx_check ^ r_shift_data[0];
end

endmodule

// 这里主要注意 在握手后 立刻就会有发送起始位 同时 也有移位寄存器赋值为输入 同时 这时cnt = 0 下一周期为1
// 是一个很重要的时序
// 也就是cnt 移位寄存器 和输出寄存器同步 同时下一周期校验位就异或了

