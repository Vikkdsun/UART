module uart_tx#(
    parameter               P_SYSTEM_CLK             =        50_000_000         ,   //杈撳叆鏃堕挓棰戠巼
    parameter               P_UART_BAUND_RATE        =        9600            ,   //娉㈢壒鐜?
    parameter               P_UART_DATA_WIDTH        =        8 ,   //鏁版嵁瀹藉害
    parameter               P_UART_STOP_WIDTH        =       1  ,   //1鎴栬??2
    parameter               P_UART_CHECK             =        0        //None=0 Odd-1 Even-2
)
(                  
    input                               i_clk            ,
    input                               i_rst            ,

    output                              o_uart_tx        ,

    input [P_UART_DATA_WIDTH-1:0]       i_user_tx_data   ,
    input                               i_user_tx_valid  ,
    output                              o_user_tx_ready  
);

/*
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)

    else if ()

    else

end
*/

// 鎻℃墜
wire                                    w_uart_tx_active                                            ;
assign                                  w_uart_tx_active = i_user_tx_valid & o_user_tx_ready         ;

// // 閿佸瓨
// reg [P_UART_DATA_WIDTH-1:0]             ri_user_tx_data                                             ;
// always@(posedge i_clk or posedge i_rst)
// begin
//     if (i_rst)
//         ri_user_tx_data <= 'd0;
//     else if (w_uart_tx_active)
//         ri_user_tx_data <= i_user_tx_data;
//     else
//         ri_user_tx_data <= ri_user_tx_data;
// end

// 璁℃暟鍣ㄨ涓?涓嬩紶浜嗗灏?
reg [15:0]                              r_tx_cnt                                                    ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_tx_cnt <= 'd0;
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH && P_UART_CHECK > 0)
        r_tx_cnt <= 'd0;
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        r_tx_cnt <= 'd0;
    else if (w_uart_tx_active || r_tx_cnt > 0)
        r_tx_cnt <= r_tx_cnt + 1;
    else
        r_tx_cnt <= r_tx_cnt;
end

// 鍋氫竴涓Щ浣嶅瘎瀛樺櫒
reg [P_UART_DATA_WIDTH-1:0]             r_shift_data                                                ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_shift_data <= 'd0;
    else if (r_tx_cnt > 0)
        r_shift_data <= r_shift_data >> 1;
    else if (w_uart_tx_active)
        r_shift_data <= i_user_tx_data;
    else
        r_shift_data <= 'd0;
end

// 鎺у埗o_uart_tx
reg                                     ro_uart_tx                                                  ;
assign                                  o_uart_tx = ro_uart_tx                                      ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_uart_tx <= 'd1;
    else if (w_uart_tx_active)
        ro_uart_tx <= 'd0;
    else if (r_tx_cnt > 0 && r_tx_cnt < 1 + P_UART_DATA_WIDTH)
        ro_uart_tx <= r_shift_data[0];
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH && P_UART_CHECK == 2)
        ro_uart_tx <= !r_check;
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH && P_UART_CHECK == 1)
        ro_uart_tx <= r_check;
    else if (r_tx_cnt > 1 + P_UART_DATA_WIDTH && r_tx_cnt < 1 + P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH && P_UART_CHECK > 0)
        ro_uart_tx <= 'd1;
    else if (r_tx_cnt > 1 + P_UART_DATA_WIDTH && r_tx_cnt < 1 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        ro_uart_tx <= 'd1;
    else 
        ro_uart_tx <= 'd1;
end

// 鎺у埗鏍￠獙 P_UART_CHECK Odd-1 Even-2 寮傛垨
// 鍋舵牎楠? 寮傛垨鍙栧弽
reg                                     r_check                                                     ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_check <= 'd1;
    else if (r_tx_cnt > 0 && r_tx_cnt < 1 + P_UART_DATA_WIDTH)
        r_check <= r_check ^ r_shift_data[0];
    // else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH && P_UART_CHECK == Even)
    //     r_check <= !r_check;
    // else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH && P_UART_CHECK == Odd)
    //     r_check <= r_check;
    else 
        r_check <= 'd1;
end

// ready
reg                                     ro_user_tx_ready                                            ;
assign                                  o_user_tx_ready = ro_user_tx_ready                          ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_tx_ready <= 'd1;
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH && P_UART_CHECK > 0)
        ro_user_tx_ready <= 'd1;
    else if (r_tx_cnt == 1 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        ro_user_tx_ready <= 'd1;
    else if (w_uart_tx_active)
        ro_user_tx_ready <= 'd0;
    else
        ro_user_tx_ready <= ro_user_tx_ready;
end


endmodule
