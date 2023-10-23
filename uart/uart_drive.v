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

localparam                              P_CLK_DIV_NUMBER = P_SYSTEM_CLK / P_UART_BUADRATE;//因为这个信号在上电只计算一次。

wire                                    w_uart_buadclk                  ;
wire                                    w_uart_buadclk_rst              ;

wire                                    w_uart_rx_clk                   ;
reg                                     r_uart_rx_clk_rst               ;

wire [P_UART_DATA_WIDTH - 1 : 0]        w_user_rx_data                  ;
wire                                    w_user_rx_valid                 ;

uart_rx#(
    .P_SYSTEM_CLK                       (P_SYSTEM_CLK       ),   //输入时钟频率
    .P_UART_BUADRATE                    (P_UART_BUADRATE    ),   //波特率
    .P_UART_DATA_WIDTH                  (P_UART_DATA_WIDTH  ),   //数据宽度
    .P_UART_STOP_WIDTH                  (P_UART_STOP_WIDTH  ),   //1或者2
    .P_UART_CHECK                       (P_UART_CHECK       )
)
uart_rx_u0
(                  
    .i_clk                              (w_uart_rx_clk      ),
    .i_rst                              (w_uart_buadclk_rst ),

    .i_uart_rx                          (i_uart_rx          ),
    .o_user_rx_data                     (w_user_rx_data     ),
    .o_user_rx_valid                    (w_user_rx_valid    ) 
);
  

uart_tx#(
    .P_SYSTEM_CLK                       (P_SYSTEM_CLK       ),   //输入时钟频率
    .P_UART_BAUND_RATE                    (P_UART_BUADRATE    ),   //波特率
    .P_UART_DATA_WIDTH                  (P_UART_DATA_WIDTH  ),   //数据宽度
    .P_UART_STOP_WIDTH                  (P_UART_STOP_WIDTH  ),   //1或者2
    .P_UART_CHECK                       (P_UART_CHECK       )
)
uart_tx_u0
(                  
    .i_clk                              (w_uart_buadclk     ),
    .i_rst                              (w_uart_buadclk_rst ),

    .o_uart_tx                          (o_uart_tx          ),

    .i_user_tx_data                     (i_user_tx_data     ),
    .i_user_tx_valid                    (i_user_tx_valid    ),
    .o_user_tx_ready                    (o_user_tx_ready    )
);


CLK_DIV_module#(
    .P_CLK_DIV_CNT          (P_CLK_DIV_NUMBER )     //最大为65535
)
CLK_DIV_module_tx
(
    .i_clk                  (i_clk          ) ,//输入时钟
    .i_rst                  (i_rst          ) ,//high value
    .o_clk_div              (w_uart_buadclk )  //分频后的时钟
);

rst_gen_module#(
    .P_RST_CYCLE            (5)   
)
rst_gen_module_u0
(
    .i_clk                  (w_uart_buadclk     ),
    .o_rst                  (w_uart_buadclk_rst )
);

CLK_DIV_module#(
    .P_CLK_DIV_CNT          (P_CLK_DIV_NUMBER )     //最大为65535
)
CLK_DIV_module_rx
(
    .i_clk                  (i_clk          ) ,//输入时钟
    .i_rst                  (r_uart_rx_clk_rst  ) ,//high value
    .o_clk_div              (w_uart_rx_clk )  //分频后的时钟
);

reg [2:0]                           r_rx_overvalue                  ;
reg                                 r_rx_overlock                   ;
always@(posedge i_clk or posedge i_rst)                 // 使用高频时钟采样
begin
    if (i_rst)
        r_rx_overvalue <= 'd7;
    else if (!r_rx_overlock)
        r_rx_overvalue <= {r_rx_overvalue[1:0], i_uart_rx};
    else    
        r_rx_overvalue <= 'd7;
end

reg [2:0]                             r_rx_overvalue_1d               ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_rx_overvalue_1d <= 'd7;
    else 
        r_rx_overvalue_1d <= r_rx_overvalue;
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_rx_overlock <= 'd0;
    else if (!w_user_rx_valid && r_user_rx_valid)
        r_rx_overlock <= 'd0;
    else if (r_rx_overvalue == 3'b000 && r_rx_overvalue_1d != 3'b000)
        r_rx_overlock <= 'd1;
    else
        r_rx_overlock <= r_rx_overlock;
end

reg                                 r_user_rx_valid                     ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_user_rx_valid <= 'd0;
    else 
        r_user_rx_valid <= w_user_rx_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_uart_rx_clk_rst <= 'd1;
    else if(!w_user_rx_valid && r_user_rx_valid)
        r_uart_rx_clk_rst <= 'd1;
    else if(r_rx_overvalue == 3'b000 && r_rx_overvalue_1d != 3'b000)
        r_uart_rx_clk_rst <= 'd0;
    else 
        r_uart_rx_clk_rst <= r_uart_rx_clk_rst;
end

// 时钟同步
reg  [P_UART_DATA_WIDTH - 1 : 0]        r_user_rx_data_1                ;
reg  [P_UART_DATA_WIDTH - 1 : 0]        r_user_rx_data_2                ;  
reg                                     r_user_rx_valid_1,
                                        r_user_rx_valid_2               ;

assign o_user_clk       = w_uart_buadclk        ;
assign o_user_rst       = w_uart_buadclk_rst    ;
assign o_user_rx_data   = r_user_rx_data_2      ;
assign o_user_rx_valid  = r_user_rx_valid_2     ;
always@(posedge w_uart_buadclk,posedge w_uart_buadclk_rst)
begin
    if(w_uart_buadclk_rst) begin
        r_user_rx_data_1  <= 'd0;
        r_user_rx_data_2  <= 'd0;
        r_user_rx_valid_1 <= 'd0;
        r_user_rx_valid_2 <= 'd0;
    end else begin
        r_user_rx_data_1  <= w_user_rx_data;
        r_user_rx_data_2  <= r_user_rx_data_1;
        r_user_rx_valid_1 <= w_user_rx_valid;
        r_user_rx_valid_2 <= r_user_rx_valid_1;
    end
end


endmodule
