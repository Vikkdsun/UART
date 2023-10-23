`timescale 1ns/1ps

module uart_rx_tb();

reg clk, rst;

initial begin
    rst = 1;
    #100;
    @(posedge clk) rst = 0;
end

always begin
    clk = 0 ;
    #10;
    clk = 1;
    #10;
end

wire                    w_uart_tx                   ;
wire                    w_ready                     ;

reg [7:0]               r_tx_data                   ;
reg                     r_tx_valid                  ;

wire [7:0]               w_rx_data                   ;
wire                     w_rx_valid                  ;

uart_tx#(
    .P_SYSTEM_CLK             ( 50_000_000    )    ,   //输入时钟频率
    .P_UART_BAUND_RATE        ( 9600          )     ,   //波特�?
    .P_UART_DATA_WIDTH        ( 8             )     ,   //数据宽度
    .P_UART_STOP_WIDTH        (2              )     ,   //1或�??2
    .P_UART_CHECK             ( 2             )      //None=0 Odd-1 Even-2
)
uart_tx_u0
(                  
    .i_clk            (clk),
    .i_rst            (rst),

    .o_uart_tx        (w_uart_tx),

    .i_user_tx_data   (r_tx_data ),
    .i_user_tx_valid  (r_tx_valid),
    .o_user_tx_ready  (w_ready)
);

uart_rx#(
    .P_SYSTEM_CLK             ( 50_000_000    )    ,   //输入时钟频率
    .P_UART_BAUND_RATE        ( 9600          )     ,   //波特�?
    .P_UART_DATA_WIDTH        ( 8             )     ,   //数据宽度
    .P_UART_STOP_WIDTH        (2              )     ,   //1或�??2
    .P_UART_CHECK             ( 2             )      //None=0 Odd-1 Even-2
)
uart_rx_u0
(                  
    .i_clk                          (clk),
    .i_rst                          (rst),

    .i_uart_rx                      (w_uart_tx),   //uart的接收数据线，异步�??

    .o_user_rx_data                 (w_rx_data ),
    .o_user_rx_valid                (w_rx_valid)   
);


always@(posedge clk or posedge rst)
begin
    if (rst) begin
        r_tx_data  <= 'd0;
        r_tx_valid <= 'd0;
    end else begin
        r_tx_data  <= 'd10;
        r_tx_valid <= 'd1;
    end
end

























endmodule
