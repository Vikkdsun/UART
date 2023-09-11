// 这是一个UART驱动
/*
    集成了分频、rst_gen、tx、rx四个模块
*/
/*
    如果考虑时钟偏移导致的累计误差，需要通过高频时钟采样rx收到信号的下降沿（这意味着接收到起始位）
    可以使用移位寄存器实现 采样到下降沿时表明可以产生波特率下的时钟，然后使时钟和数据中值对齐

    这样得到的输入进去的数据是对应于上面所述的“需要时才产生的波特率时钟”的，为了使输出的并行数据对齐，还要再用波特率时钟再同步一下(打两拍)

*/

module uart_drive#(
    parameter                           P_SYSTEM_CLK      = 50_000_000  ,   //输入时钟频率
    parameter                           P_UART_BUADRATE   = 9600        ,   //波特率
    parameter                           P_UART_DATA_WIDTH = 8           ,   //数据宽度
    parameter                           P_UART_STOP_WIDTH = 1           ,   //1或者2
    parameter                           P_UART_CHECK      = 0               //None=0 Odd-1 Even-2
)(                  
    input                               i_clk                           ,
    input                               i_rst                           ,  

    input                               i_uart_rx                       ,
    output                              o_uart_tx                       ,

    input  [P_UART_DATA_WIDTH - 1 : 0]  i_user_tx_data                  ,
    input                               i_user_tx_valid                 ,
    output                              o_user_tx_ready                 ,

    output  [P_UART_DATA_WIDTH - 1 : 0] o_user_rx_data                  ,
    output                              o_user_rx_valid                 ,

    output                              o_user_clk                      ,
    output                              o_user_rst      
);

// 因为rx输出后还要同步 所以这里创建几个同步前的wire
wire                                                    w_rx_valid              ;
wire    [P_UART_DATA_WIDTH - 1 : 0]                     w_rx_data               ;

// 对时钟设置一个wire接收分频后的时钟信号 还有产生的rst信号
wire                                                    w_tx_buadclk            ;
wire                                                    w_rx_buadclk            ;
wire                                                    w_tx_rst                ;
reg                                                     r_rx_rst                ;               // 用于接收的rst，检测到初始位时产生时钟

// 产生r_rx_rst的信号
reg     [2:0]                                           r_overvalue             ;
reg                                                     r_overvalue_lock        ;
reg                                                     r_overvalue_1d          ;

// 一些打拍reg
reg                                                     r_rx_valid              ;               // 用来检测是不是接收好了一个信号 接收好了的话 就可以高频采样接下来的数据了
reg      [P_UART_DATA_WIDTH - 1 : 0]                    r_rx_data_1d            ;
reg      [P_UART_DATA_WIDTH - 1 : 0]                    r_rx_data_2d            ;
reg                                                     r_rx_valid_1d           ,
                                                        r_rx_valid_2d           ;



// 本模块的输入时钟是系统时钟，需要经过一次pll
clk_div_module
#(
    .P_CLK_DIV_CNT   (P_CLK_DIV_NUMBER  )
)
clk_div_module_tx
(
    .i_clk           (i_clk             ),
    .i_rst           (i_rst             ),
    .o_clk_div       (w_tx_buadclk      )   
);

clk_div_module
#(
    .P_CLK_DIV_CNT   (P_CLK_DIV_NUMBER  )
)
clk_div_module_rx
(
    .i_clk           (i_clk             ),
    .i_rst           (r_rx_rst          ),
    .o_clk_div       (w_rx_buadclk      )   
);

// 输出模块的rst生成 用的分频后的时钟 产生tx需要的rst
rst_gen_module#(
    .P_RST_CYCLE                        (1                  )
)
rst_gen_module_u0
(
    .i_clk                              (w_tx_buadclk       ),
    .o_rst                              (w_tx_rst           )
);

// 产生r_rx_rst的逻辑
always@(posedge i_clk or posedge i_rst)                 // ！！！！！
begin
    if (i_rst)
        r_overvalue <= 'd0;
    else if (!r_overvalue_lock)
        r_overvalue <= {r_overvalue[1:0], i_uart_rx};           // 当数据起始位结束 不进行移位
    else
        r_overvalue <= 3'b111;
end

always@(posedge i_clk or posedge i_rst)             // 打拍rx_valid
begin   
    if (i_rst)
        r_rx_valid <= 'd0;
    else
        r_rx_valid <= o_user_rx_valid;
end

always@(posedge i_clk or posedge i_rst)             // 打拍锁
begin
    if (i_rst)
        r_overvalue_1d <= 'd0;
    else 
        r_overvalue_1d <= r_overvalue;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_overvalue_lock <= 'd0;
    else if (!w_rx_valid && r_rx_valid)             // 当前0 之前1 表示valid过了
        r_overvalue_lock <= 'd0;
    else if (r_overvalue == 3'b000 && r_overvalue_1d != 3'b000)         // 之前存在不是0 现在全是0 表示采到输入数据下降沿 起始位
        r_overvalue_lock <= 'd1;                                        // 已经采到了 就不用再移位了
    else 
        r_overvalue_lock <= r_overvalue_lock;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_rx_rst <= 'd0;
    else if (w_user_rx_valid == 0 && r_user_rx_valid != 0)              // !!!!!
        r_rx_rst <= 'd1;
    else if (r_overvalue == 3'b000 && r_overvalue_1d != 3'b000)
        r_rx_rst <= 'd0;
    else
        r_rx_rst <= r_rx_rst;
end

// 对rx tx例化
uart_tx#(
    .P_SYSTEM_CLK      (P_SYSTEM_CLK     ),   //输入时钟频率
    .P_UART_BUADRATE   (P_UART_BUADRATE  ),   //波特率
    .P_UART_DATA_WIDTH (P_UART_DATA_WIDTH),   //数据宽度
    .P_UART_STOP_WIDTH (P_UART_STOP_WIDTH),   //1或者2
    .P_UART_CHECK      (P_UART_CHECK     )    //None=0 Odd-1 Even-2
)
uart_tx_u0
(                  
    .i_clk                  (w_tx_buadclk   )         ,
    .i_rst                  (w_tx_rst       )         ,

    .o_uart_tx              (o_uart_tx      )         ,

    .i_user_tx_data         (i_user_tx_data )         ,
    .i_user_tx_valid        (i_user_tx_valid)         ,
    .o_user_tx_ready        (o_user_tx_ready)         
);

uart_rx#(
    .P_SYSTEM_CLK      (P_SYSTEM_CLK     )  ,   //输入时钟频率
    .P_UART_BUADRATE   (P_UART_BUADRATE  )  ,   //波特率
    .P_UART_DATA_WIDTH (P_UART_DATA_WIDTH)  ,   //数据宽度
    .P_UART_STOP_WIDTH (P_UART_STOP_WIDTH)  ,   //1或者2
    .P_UART_CHECK      (P_UART_CHECK     )      //None=0 Odd-1 Even-2
)
uart_rx_u0
(                  
    .i_clk              (w_rx_buadclk   )                 ,
    .i_rst              (r_rx_rst       )                 ,

    .i_uart_rx          (i_uart_rx      )                 ,   //uart的接收数据线，异步。

    .o_user_rx_data     (w_rx_data      )                 ,
    .o_user_rx_valid    (w_rx_valid     )
);

// rx的输出数据(w_rx_data、 w_rx_valid)需要打两拍同步
always@(posedge w_tx_buadclk or posedge w_tx_rst)               // 注意这里的敏感列表
begin
    if (r_rx_rst)
    begin
        r_rx_data_1d    <= 'd0;
        r_rx_data_2d    <= 'd0;
        r_rx_valid_1d   <= 'd0;
        r_rx_valid_2d   <= 'd0;
    end
    else
    begin
        r_rx_data_1d    <= w_rx_data;
        r_rx_data_2d    <= r_rx_data_1d;
        r_rx_valid_1d   <= w_rx_valid;
        r_rx_valid_2d   <= r_rx_valid_1d;
    end
end

endmodule


// 难点在于overvalue和overlock的逻辑 包括什么时候锁 什么时候不锁
// 以及生成rst的逻辑 包括什么时候复位
