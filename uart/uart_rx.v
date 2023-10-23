module uart_rx#(
    parameter               P_SYSTEM_CLK             =        50_000_000         ,   //杈撳叆鏃堕挓棰戠巼
    parameter               P_UART_BAUND_RATE        =        9600            ,   //娉㈢壒锟??
    parameter               P_UART_DATA_WIDTH        =        8 ,   //鏁版嵁瀹藉害
    parameter               P_UART_STOP_WIDTH        =       1  ,   //1鎴栵拷??2
    parameter               P_UART_CHECK             =        0        //None=0 Odd-1 Even-2
)
(                  
    input                               i_clk                           ,
    input                               i_rst                           ,

    input                               i_uart_rx                       ,   //uart鐨勬帴鏀舵暟鎹嚎锛屽紓姝ャ??

    output [P_UART_DATA_WIDTH - 1 : 0]  o_user_rx_data                  ,
    output                              o_user_rx_valid
);
/*

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)

    else if ()

    else
    
end

*/

// 鎵撲袱鎷?
reg [1:0]                               ri_uart_rx                      ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_uart_rx <= 'd3;
    else
        ri_uart_rx <= {ri_uart_rx[0], i_uart_rx};
end

// 璁℃暟
reg [15:0]                              r_rx_cnt                        ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)      
        r_rx_cnt <= 'd0;
    else if (r_rx_cnt == 1 + P_UART_DATA_WIDTH)
        r_rx_cnt <= 'd0;
    else if (ri_uart_rx[1] == 'd0 && r_rx_cnt == 'd0 || r_rx_cnt>0)  
        r_rx_cnt <= r_rx_cnt + 1;
    else
        r_rx_cnt <= r_rx_cnt;
end

// o_user_rx_data
reg [P_UART_DATA_WIDTH - 1 : 0]         ro_user_rx_data                 ;
assign                                  o_user_rx_data = ro_user_rx_data;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_rx_data <= 'd0;
    else if (ri_uart_rx[1] == 'd0 && r_rx_cnt == 'd0 || r_rx_cnt > 0 && r_rx_cnt < P_UART_DATA_WIDTH+1)
        ro_user_rx_data <= { ri_uart_rx[1], ro_user_rx_data[P_UART_DATA_WIDTH - 1 : 1]};
    else
        ro_user_rx_data <= ro_user_rx_data;
end

// 鏍￠獙
reg                                     r_check                         ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_check <= 'd1;
    else if (r_rx_cnt > 0 && r_rx_cnt < P_UART_DATA_WIDTH+1)
        r_check <= r_check ^ ri_uart_rx[1];
    else
        r_check <= 'd1;
end

// valid
reg                                     ro_user_rx_valid                ;
assign                                  o_user_rx_valid = ro_user_rx_valid;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_rx_valid <= 'd0;
    else if (r_rx_cnt == P_UART_DATA_WIDTH && P_UART_CHECK == 0)
        ro_user_rx_valid <= 'd1;
    else if (r_rx_cnt == P_UART_DATA_WIDTH + 1 && P_UART_CHECK == 2 && r_check == !ri_uart_rx[1])
        ro_user_rx_valid <= 'd1;
    else if (r_rx_cnt == P_UART_DATA_WIDTH + 1 && P_UART_CHECK == 1 && r_check == ri_uart_rx[1])
        ro_user_rx_valid <= 'd1;
    else 
        ro_user_rx_valid <= 'd0;
end

endmodule
