module number_mul
(
	input i_clk,
	input i_rst,

	input [255 : 0] q,
	input [255 : 0] a,
	input [255 : 0] b,

	output [255 : 0] c
);

// localparam q = 256'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

wire [129 : 0] a0, b0, a1, b1, a2, b2;

assign a1 = {4'b0, a[255 : 129]};
assign a0 = {4'b0, a[128 : 0]};
assign b1 = {4'b0, b[255 : 129]};
assign b0 = {4'b0, b[128 : 0]};
// input of M
assign a2 = a1 + a0;
assign b2 = b1 + b0;


wire [259 : 0] H, M, L;

// modulo stage 1
reg [259 : 0] C_h_w;
// reg [259 : 0] C_h_r;

reg [389 : 0] C_l_w;
// reg [389 : 0] C_l_r;

reg [389 : 0] s1_T_w;
reg [389 : 0] s1_T_r;

always @ (*)
begin
	C_h_w  = H;
	C_l_w  = {(M - H - L), 129'b0} + L; // 260bit << 130bit
	s1_T_w = 152 * C_h_w + C_l_w;
end

// modulo stage 2
reg [255 : 0] s2_T_tmp, s2_T_w;
reg [255 : 0] s2_T_r;

assign c = s2_T_w;

always @ (*)
begin
	s2_T_tmp = 19 * s1_T_r[389 : 255] + s1_T_r[254 : 0];
	if (s2_T_tmp > q)
	begin
		s2_T_w = s2_T_tmp - q;
	end
	else
	begin
		s2_T_w = s2_T_tmp;
	end
end

always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		// C_h_r  <= 0;
		// C_l_r  <= 0;
		s1_T_r <= 0;
	end
	else
	begin
		// C_h_r  <= C_h_w;
		// C_l_r  <= C_l_w;
		s1_T_r <= s1_T_w;
	end
end

multiplier
#(
	.I_WIDTH (130),
	.O_WIDTH (260)
)
u_multiplier_1
(
	.i_clk (i_clk),
	.i_rst (i_rst),

	.a0 (a0),
	.b0 (b0),
	.a1 (a1),
	.b1 (b1),
	.a2 (a2),
	.b2 (b2),

	.H (H),
	.M (M),
	.L (L)
);
endmodule