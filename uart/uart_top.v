// 这是UART的顶层文件 包括pll、drive和fifo

/*
    fifo有空信号和满信号，满不能写，空不能读

*/

module UART_TOP(
    input               i_clk               ,           // 注意 最顶层文件是不存在rst的

    input               i_uart_rx           ,      
    output              o_uart_tx                 
);

wire                                            w_clk_50mhz                             ;
wire                                            w_system_pll_locked                     ;

wire                                            w_clk_rst   =   ~w_system_pll_locked    ;

wire                                            w_user_clk                              ;
wire                                            w_user_rst                              ;

wire    [7:0]                                   w_user_rx_data                          ;
wire                                            w_user_rx_valid                         ;
wire    [7:0]                                   w_user_tx_data                          ;
wire                                            w_user_tx_ready                         ;
wire                                            w_user_tx_valid                         ;

wire                                            w_fifo_empty                            ;


reg                                             r_fifo_rden                             ;
reg                                             r_fifo_rden_lock                        ;
reg                                             r_tx_valid                              ;
reg                                             r_tx_ready                              ;

// 例化fifo
system_pll system_pll_u0
(
    .clk_in1            (i_clk                  ),
    .clk_out1           (w_clk_50Mhz            ),   
    .locked             (w_system_pll_locked    )           // 为1时信号生效 所以想让他做rst的话需要取反
);

// 例化drive
uart_drive#(
    .P_SYSTEM_CLK               (50_000_000 ) ,   //输入时钟频率
    .P_UART_BUADRATE            (9600       ) ,   //波特率
    .P_UART_DATA_WIDTH          (8          ) ,   //数据宽度
    .P_UART_STOP_WIDTH          (1          ) ,   //1或者2
    .P_UART_CHECK               (0          )     //None=0 Odd-1 Even-2
)
uart_drive_u0
(                  
    .i_clk                  (w_clk_50Mhz        )                ,
    .i_rst                  (w_clk_rst          )                ,  

    .i_uart_rx              (i_uart_rx          )                ,
    .o_uart_tx              (o_uart_tx          )                ,

    .i_user_tx_data         (w_user_tx_data     )                ,
    .i_user_tx_valid        (r_tx_valid         )                ,
    .o_user_tx_ready        (w_user_tx_ready    )                ,

    .o_user_rx_data         (w_user_rx_data     )                ,
    .o_user_rx_valid        (w_user_rx_valid    )                ,

    .o_user_clk             (w_user_clk         )                ,
    .o_user_rst             (w_user_rst         )
);

// 例化fifo fifo内部非空 则可以tx 
UART_FIFO UART_FIFO_U0 (
  .clk                  (w_user_clk             ),      // input wire clk
  .srst                 (w_user_rst             ),    // input wire srst
  .din                  (w_user_rx_data         ),      // input wire [7 : 0] din
  .wr_en                (w_user_rx_valid        ),  // input wire wr_en
  .rd_en                (r_fifo_rden            ),  // input wire rd_en
  .dout                 (w_user_tx_data         ),    // output wire [7 : 0] dout
  .full                 (),    // output wire full
  .empty                (w_fifo_empty           )  // output wire empty
);

// 主要的问题在于这里的rd_en
always@(posedge w_user_clk or posedge w_clk_rst)
begin
    if (w_clk_rst)
        r_fifo_rden <= 'd0;
    else if (!w_fifo_empty && w_user_tx_ready && !r_fifo_rden_lock)
        r_fifo_rden <= 'd1;
    else
        r_fifo_rden <= 'd0;
end

// 这里给valid打一拍不太理解！！！！！！（难道是 可以读之后 才给valid?）
always@(posedge w_user_clk or posedge w_user_rst)               // !!!!!!!!
begin
    if (w_user_rst)
        r_tx_valid <= 'd0;
    else
        r_tx_valid <= r_fifo_rden;
end

// 这样的话 rden开启了不止一个周期 而是连续两个周期 所以 需要个锁 控制rden只拉高一个周期        
always@(posedge w_user_clk or posedge w_user_rst)               // !!!!!!!!
begin
    if (w_user_rst)
        r_fifo_rden_lock <= 'd0;
    else if (w_user_tx_ready && !r_tx_ready)
        r_fifo_rden_lock <= 'd0;
    else if (~w_fifo_empty && w_user_tx_ready)
        r_fifo_rden_lock <= 'd1;
    else
        r_fifo_rden_lock <= r_fifo_rden_lock;
end

always@(posedge w_user_clk or posedge w_user_rst)               // !!!!!!
begin
    if (w_user_rst)
        r_tx_ready <= 'd0;
    else
        r_tx_ready <= w_user_tx_ready;
end

endmodule

// 重要的就是这里的fifo 
// 只有fifo非空 这样才能有输入的并行数据 才能从tx发出串行，
// fifo非空还不行 还要tx是ready的 
// 但是为什么要给valid也打一拍没太理解
// 此外 rden 延迟 ready; valid 延迟 rden 这样的话 握手后 rden有两周期的拉高 所以加了一个锁
// 很简单的锁 ready拉高的第一个周期就开锁 但是之后就锁上不允许rden拉高
