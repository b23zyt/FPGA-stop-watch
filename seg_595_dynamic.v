module seg_595_dynamic(
	input wire sys_clk,
	input wire sys_rst_n,
	input wire [19:0] data,
	input wire [5:0] point,
	input wire seg_en,
	input wire sign,
	
	output wire stcp,
	output wire shcp,
	output wire ds,
	output wire oe
);

wire [5:0] sel;
wire [7:0] seg;

seg_dynamic seg_dynamic_inst(
	.sys_clk(sys_clk),
	.sys_rst_n(sys_rst_n),
	.data(data),
	.point(point),
	.seg_en(seg_en),
	.sign(sign),
	.sel(sel),
	.seg(seg)
);



hc595_ctrl hc595_ctrl_inst(
	.sys_clk(sys_clk),
	.sys_rst_n(sys_rst_n),
	.sel(sel),
	.seg(seg),
	.stcp(stcp),
	.shcp(shcp),
	.ds(ds),
	.oe(oe)
);
endmodule