`define FUNC_AUTOMATIC automatic
module ed25519
(
	input i_clk,
	input i_rst,

	input i_in_valid,
	output o_in_ready,

	input  i_out_ready,
	output o_out_valid,

	input  [63 : 0] i_in_data,
	output [63 : 0] o_out_data
);

localparam   IDLE = 3'd0;
localparam READ_M = 3'd1;
localparam READ_X = 3'd2;
localparam READ_Y = 3'd3;
localparam WAIT_O = 3'd4;

// localparam q = 256'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

// reg o_out_valid_w;

// simulate the behavior of ed25519, wait 255 cycle for calculation
// reg [8 : 0] ed25519_counter;

reg [2 : 0] c_state;
reg [2 : 0] n_state;

reg [2 : 0] counter_w;
reg [2 : 0] counter_r;

reg [255 : 0] scalar_m_w;
reg [255 : 0] scalar_m_r;

reg [255 : 0] number_x_w;
reg [255 : 0] number_x_r;

reg [255 : 0] number_y_w;
reg [255 : 0] number_y_r;

reg  point_enable;
wire point_valid;
wire [63 : 0] point_data;

// ---------------------- Continuous Assignment ---------------------- //
assign o_in_ready = 1;
assign o_out_valid = point_valid;
assign o_out_data = point_data;

// ---------------------- Combinational Logic ---------------------- //
// scalar_m_w
always @ (*)
begin
	scalar_m_w = scalar_m_r;
	if (c_state == READ_M)
	begin
		if (i_in_valid)
		begin
			scalar_m_w[255 - (64 * counter_r) -: 64] = i_in_data;
		end
	end
end

// number_x_w
always @ (*)
begin
	number_x_w = number_x_r;
	if (c_state == READ_X)
	begin
		if (i_in_valid)
		begin
			number_x_w[255 - (64 * counter_r[1 : 0]) -: 64] = i_in_data;
		end
	end
end

// number_y_w
always @ (*)
begin
	number_y_w = number_y_r;
	if (c_state == READ_Y)
	begin
		if (i_in_valid)
		begin
			number_y_w[255 - (64 * counter_r[1 : 0]) -: 64] = i_in_data;
		end
	end
end

// counter_w
always @ (*)
begin
	counter_w = counter_r;
	case (c_state)
		READ_M, READ_X, READ_Y:
		begin
			if (i_in_valid)
			begin
				counter_w = counter_r + 1;
			end
		end
		WAIT_O:
		begin
			if (i_out_ready && point_valid)
			begin
				counter_w = counter_r + 1;
			end
		end
	endcase
end

// point_enable
always @ (*)
begin
	point_enable = 1;
	if (c_state == WAIT_O)
	begin
		point_enable = 0;
	end
end

// ---------------------- Sequential Logic ---------------------- //
// counter_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		counter_r <= 0;
	end
	else
	begin
		counter_r <= counter_w;
	end
end

// scalar_m_r, number_x_r, number_y_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		scalar_m_r <= 0;
		number_x_r  <= 0;
		number_y_r  <= 0;
	end
	else
	begin
		scalar_m_r <= scalar_m_w;
		number_x_r  <= number_x_w;
		number_y_r  <= number_y_w;
	end
end

// ---------------------- FSM ---------------------- //
// current state logic
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		c_state <= IDLE;
	end
	else
	begin
		c_state <= n_state;
	end
end

// next state logic
always @ (*)
begin
	n_state = IDLE;
	case (c_state)
		IDLE:
		begin
			// counter_r == 4
			if (counter_r[2])
			begin
				n_state = IDLE;
			end
			else
			begin
				n_state = READ_M;
			end
		end
		READ_M:
		begin
			if (counter_r[1 : 0] == 3)
			begin
				n_state = READ_X;
			end
			else
			begin
				n_state = READ_M;
			end
		end
		READ_X:
		begin
			if (counter_r[1 : 0] == 3)
			begin
				n_state = READ_Y;
			end
			else
			begin
				n_state = READ_X;
			end
		end
		READ_Y:
		begin
			if (counter_r[1 : 0] == 3)
			begin
				n_state = WAIT_O;
			end
			else
			begin
				n_state = READ_Y;
			end
		end
		WAIT_O:
		begin
			if (counter_r == 3 && i_out_ready)
			begin
				n_state = IDLE;
			end
			else
			begin
				n_state = WAIT_O;
			end
		end
	endcase
end

point u_point
(
	.i_clk (i_clk),
	.i_rst (i_rst),

	.i_enable    (point_enable),
	.i_out_ready (i_out_ready),

	.counter  (counter_r),
	.scalar_m (scalar_m_r),
	.number_x (number_x_r),
	.number_y (number_y_r),

	.o_out_valid (point_valid),
	.o_out_data  (point_data)
);

endmodule