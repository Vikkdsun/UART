/*
    专门产生分频后rst的模块
*/
module rst_gen_module
#(
    parameter           p_RST_CYCLE         =           1
)
(
    input               i_clk                               ,
    output              o_rst                               
);

reg                     ro_rst=1        ;
reg     [7:0]           r_cnt=0         ;

assign                  o_rst = ro_rst  ;

always@(posedge i_clk)
begin
    if (r_cnt == p_RST_CYCLE - 1    ||  p_RST_CYCLE == 0)
        r_cnt <= r_cnt;
    else
        r_cnt <= r_cnt + 1;
end

always@(posedge i_clk)
begin
    if (r_cnt == p_RST_CYCLE - 1    ||  p_RST_CYCLE == 0)
        ro_rst <= 'd0;
    else
        ro_rst <= 'd1;
end


endmodule