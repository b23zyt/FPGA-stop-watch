//key idea: use 1ms refresh time to let the six tubes in turn display, the 1ms lights up the first digital tube, 
//and 2ms the second, and so on. light up the six digital tubes in turn, 6ms in a cycle
//That is, each digital tube lights up 1ms for every 6ms. so that human eye can feel the digital cube has been bright
module seg_dynamic 
(
	input wire sys_clk,
	input wire sys_rst_n,
	input wire [19:0] data,
	input wire [5:0] point,
	input wire seg_en,
	input wire sign,
	
	output reg [5:0] sel,
	output reg [7:0] seg
);

parameter CNT_MAX = 16'd49_999;

wire [3:0] unit;
wire [3:0] ten;
wire [3:0] hun;
wire [3:0] tho;
wire [3:0] t_tho;
wire [3:0] h_hun;

reg [23:0] data_reg;
reg [15:0] cnt_1ms; //1ms counter, scan the data at every 1ms so that our eyes seem it as always shining
reg flag_1ms; //1ms flag_1ms
reg [2:0] cnt_sel; //every 6ms light every seg 1ms, needs to count up to 6
reg [5:0] sel_reg; //reg selector
reg [3:0] data_disp; //show negative when it = 10
reg dot_disp;

//data_reg：控制数码管显示数据
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		data_reg <= 24'b0;
//若显示的十进制数的十万位为非零数据或需显示小数点，则六个数码管全显示
	else if((h_hun) || (point[5]))
		data_reg <= {h_hun,t_tho,tho,hun,ten,unit};
//若显示的十进制数的万位为非零数据或需显示小数点，则值显示在 5 个数码管上
//打比方我们输入的十进制数据为 20’d12345，我们就让数码管显示 12345 而不是 012345
	else if(((t_tho) || (point[4])) && (sign == 1'b1))//显示负号
		data_reg <= {4'd10,t_tho,tho,hun,ten,unit};//4'd10 我们定义为显示负号
	else if(((t_tho) || (point[4])) && (sign == 1'b0))
		data_reg <= {4'd11,t_tho,tho,hun,ten,unit};//4'd11 我们定义为不显示
	//若显示的十进制数的千位为非零数据或需显示小数点，则值显示 4 个数码管
	else if(((tho) || (point[3])) && (sign == 1'b1))
		data_reg <= {4'd11,4'd10,tho,hun,ten,unit};
	else if(((tho) || (point[3])) && (sign == 1'b0))
		data_reg <= {4'd11,4'd11,tho,hun,ten,unit};
//若显示的十进制数的百位为非零数据或需显示小数点，则值显示 3 个数码管
	else if(((hun) || (point[2])) && (sign == 1'b1))
		data_reg <= {4'd11,4'd11,4'd10,hun,ten,unit};
	else if(((hun) || (point[2])) && (sign == 1'b0))
		data_reg <= {4'd11,4'd11,4'd11,hun,ten,unit};
//若显示的十进制数的十位为非零数据或需显示小数点，则值显示 2 个数码管
	else if(((ten) || (point[1])) && (sign == 1'b1))
		data_reg <= {4'd11,4'd11,4'd11,4'd10,ten,unit};
		else if(((ten) || (point[1])) && (sign == 1'b0))
		data_reg <= {4'd11,4'd11,4'd11,4'd11,ten,unit};
//若显示的十进制数的个位且需显示负号
	else if(((unit) || (point[0])) && (sign == 1'b1))
		data_reg <= {4'd11,4'd11,4'd11,4'd11,4'd10,unit};
 //若上面都不满足都只显示一位数码管
	else
		data_reg <= {4'd11,4'd11,4'd11,4'd11,4'd11,unit};

//cnt_1ms:1ms 循环计数
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_1ms <= 16'd0;
	else if(cnt_1ms == CNT_MAX)
		cnt_1ms <= 16'd0;
	else
	cnt_1ms <= cnt_1ms + 1'b1;

 //flag_1ms:1ms 标志信号
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		flag_1ms <= 1'b0;
	else if(cnt_1ms == CNT_MAX - 1'b1)
		flag_1ms <= 1'b1;
	else
		flag_1ms <= 1'b0;

//cnt_sel：从 0 到 5 循环数，用于选择当前显示的数码管
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_sel <= 3'd0;
	else if((cnt_sel == 3'd5) && (flag_1ms == 1'b1))
		cnt_sel <= 3'd0;
	else if(flag_1ms == 1'b1)
		cnt_sel <= cnt_sel + 1'b1;
	else
		cnt_sel <= cnt_sel;

//数码管位选信号寄存器
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		sel_reg <= 6'b000_000;
	else if((cnt_sel == 3'd0) && (flag_1ms == 1'b1))
		sel_reg <= 6'b000_001;
	else if(flag_1ms == 1'b1)
		sel_reg <= sel_reg << 1;
	else
		sel_reg <= sel_reg;

 //控制数码管的位选信号，使六个数码管轮流显示
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		data_disp <= 4'b0;
	else if((seg_en == 1'b1) && (flag_1ms == 1'b1))
		case(cnt_sel)
			3'd0: data_disp <= data_reg[3:0] ; //给第 1 个数码管赋个位值
			3'd1: data_disp <= data_reg[7:4] ; //给第 2 个数码管赋十位值
			3'd2: data_disp <= data_reg[11:8] ; //给第 3 个数码管赋百位值
			3'd3: data_disp <= data_reg[15:12]; //给第 4 个数码管赋千位值
			3'd4: data_disp <= data_reg[19:16]; //给第 5 个数码管赋万位值
			3'd5: data_disp <= data_reg[23:20]; //给第 6 个数码管赋十万位值
			default:data_disp <= 4'b0;
		endcase
	else
		data_disp <= data_disp;

//dot_disp：小数点低电平点亮，需对小数点有效信号取反
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		dot_disp <= 1'b1;
	else if(flag_1ms == 1'b1)
		dot_disp <= ~point[cnt_sel];
	else
		dot_disp <= dot_disp;

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		seg <= 8'b1111_1111;
	else 
		case(data_disp)
			4'd0 : seg <= {dot_disp,7'b100_0000}; //显示数字 0
			4'd1 : seg <= {dot_disp,7'b111_1001}; //显示数字 1
			4'd2 : seg <= {dot_disp,7'b010_0100}; //显示数字 2
			4'd3 : seg <= {dot_disp,7'b011_0000}; //显示数字 3
			4'd4 : seg <= {dot_disp,7'b001_1001}; //显示数字 4
			4'd5 : seg <= {dot_disp,7'b001_0010}; //显示数字 5
			4'd6 : seg <= {dot_disp,7'b000_0010}; //显示数字 6
			4'd7 : seg <= {dot_disp,7'b111_1000}; //显示数字 7
			4'd8 : seg <= {dot_disp,7'b000_0000}; //显示数字 8
			4'd9 : seg <= {dot_disp,7'b001_0000}; //显示数字 9
			4'd10 : seg <= 8'b1011_1111 ; //显示负号
			4'd11 : seg <= 8'b1111_1111 ; //不显示任何字符
			default:seg <= 8'b1100_0000;
		endcase

//sel:数码管位选信号赋值
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		sel <= 6'b000_000;
	else
		sel <= sel_reg;
		
//---------- bsd_8421_inst ----------
bcd_8421 bcd_8421_inst(
	.sys_clk (sys_clk ), //系统时钟，频率 50MHz
	.sys_rst_n (sys_rst_n), //复位信号，低电平有效
	.data (data ), //输入需要转换的数据
	.unit (unit ), //个位 BCD 码
	.ten (ten ), //十位 BCD 码
	.hun (hun ), //百位 BCD 码
	.tho (tho ), //千位 BCD 码
	.t_tho (t_tho ), //万位 BCD 码
	.h_hun (h_hun ) //十万位 BCD 码
);
endmodule