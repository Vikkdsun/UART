`timescale 1ns / 1ns   //鏃堕棿鍗曚綅/鏃堕棿绮惧害
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/13 22:44:24
// Design Name: 
// Module Name: SIM_uart_drive_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// `define CLK_PERIOD 10;//棰勭紪璇戝弬鏁� CLK cycle = 20ns


module SIM_uart_drive_TB();

/****浠跨湡璇硶銆佷骇鐢熸椂閽熶笌澶嶄綅****/

localparam CLK_PERIOD = 20 ;

reg clk,rst;

initial begin   //杩囩▼璇彞锛屽彧鍦ㄤ豢鐪熼噷鍙互浣跨敤锛屼笉鍙患鍚�
    rst = 1;    //涓婄數寮�濮嬪浣�
    #100;       //寤舵椂100ns
    @(posedge clk) rst = 0;    //涓婄數澶嶄綅閲婃斁
end

always begin//杩囩▼璇彞锛屽彧鍦ㄤ豢鐪熼噷鍙互浣跨敤锛屼笉鍙患鍚�
    clk = 0;
    #(CLK_PERIOD/2);
    clk = 1;
    #(CLK_PERIOD/2);
end

localparam P_USER_DATA_WIDTH = 8;

reg  [P_USER_DATA_WIDTH - 1 : 0]    r_user_tx_data  ;
reg                                 r_user_tx_valid ;
wire                                w_user_tx_ready ;     
wire [P_USER_DATA_WIDTH - 1 : 0]    w_user_rx_data  ;
wire                                w_user_rx_valid ;
wire                                w_user_active   ;
wire                                w_user_clk      ;
wire                                w_user_rst      ;
assign w_user_active = r_user_tx_valid & w_user_tx_ready;


uart_drive#(
    .P_SYSTEM_CLK       (50_000_000             ),   //杈撳叆鏃堕挓棰戠巼
    .P_UART_BUADRATE    (9600                   ),   //娉㈢壒鐜�
    .P_UART_DATA_WIDTH  (P_USER_DATA_WIDTH      ),   //鏁版嵁瀹藉害
    .P_UART_STOP_WIDTH  (1                      ),   //1鎴栬��2
    .P_UART_CHECK       (2                      )    //None=0 Odd-1 Even-2
)
uart_drive_u0
(                  
    .i_clk              (clk),
    .i_rst              (rst),  

    .i_uart_rx          (o_uart_tx              ),
    .o_uart_tx          (o_uart_tx              ),

    .i_user_tx_data     (r_user_tx_data         ),
    .i_user_tx_valid    (r_user_tx_valid        ),
    .o_user_tx_ready    (w_user_tx_ready        ),

    .o_user_rx_data     (w_user_rx_data         ),
    .o_user_rx_valid    (w_user_rx_valid        ),
    .o_user_clk         (w_user_clk             ) ,
    .o_user_rst         (w_user_rst             )                 
);

/****婵�鍔变俊鍙�****/
always@(posedge w_user_clk,posedge w_user_rst)
begin
    if(w_user_rst)
        r_user_tx_data <= 'd0;
    else if(w_user_active)
        r_user_tx_data <= r_user_tx_data + 1;
    else 
        r_user_tx_data <= r_user_tx_data;
end

always@(posedge w_user_clk,posedge w_user_rst)
begin
    if(w_user_rst)
        r_user_tx_valid <= 'd0;
    else if(w_user_active)
        r_user_tx_valid <= 'd0;
    else if(w_user_tx_ready)
        r_user_tx_valid <= 'd1;
    else 
        r_user_tx_valid <= r_user_tx_valid;
end

endmodule
