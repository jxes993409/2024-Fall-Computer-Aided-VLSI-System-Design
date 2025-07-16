module multiplier
#(
	parameter I_WIDTH = 130,
	parameter O_WIDTH = 260
)
(
	input i_clk,
	input i_rst,

	input [I_WIDTH - 1 : 0] a0,
	input [I_WIDTH - 1 : 0] b0,
	input [I_WIDTH - 1 : 0] a1,
	input [I_WIDTH - 1 : 0] b1,
	input [I_WIDTH - 1 : 0] a2,
	input [I_WIDTH - 1 : 0] b2,

	output [O_WIDTH - 1 : 0] H,
	output [O_WIDTH - 1 : 0] M,
	output [O_WIDTH - 1 : 0] L
);

wire [O_WIDTH - 1 : 0] H_w, M_w, L_w;
reg  [O_WIDTH - 1 : 0] H_r, M_r, L_r;

assign H_w = a1 * b1;
assign M_w = a2 * b2;
assign L_w = a0 * b0;

assign H = H_r;
assign M = M_r;
assign L = L_r;

always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		H_r <= 0;
		M_r <= 0;
		L_r <= 0;
	end
	else
	begin
		H_r <= H_w;
		M_r <= M_w;
		L_r <= L_w;
	end
end

endmodule