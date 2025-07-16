module point
(
	input i_clk,
	input i_rst,

	input i_enable,

	input   [2 : 0] counter,
	input [255 : 0] scalar_m,
	input [255 : 0] number_x,
	input [255 : 0] number_y,
	input  i_out_ready,
	output o_out_valid,
	output [63 : 0] o_out_data
);

localparam    IDLE = 3'd0;
localparam P_DOU_1 = 3'd1; // doubling
localparam P_DOU_2 = 3'd2; // doubling
localparam P_DOU_3 = 3'd3; // doubling
localparam   P_ADD = 3'd4; // addition
localparam P_RDU_1 = 3'd5; // reduction
localparam P_RDU_2 = 3'd6;
localparam   D_OUT = 3'd7;


wire [255 : 0] q;
wire [255 : 0] d;

wire bit_is_1;
wire bit_is_1_2;


reg [2 : 0] c_state;
reg [2 : 0] n_state;

reg [7 : 0] index_w;
reg [7 : 0] index_r;

reg [3 : 0] stage_counter_w;
reg [3 : 0] stage_counter_r;

reg [255 : 0] number_x_w;
reg [255 : 0] number_x_r;
reg [255 : 0] number_y_w;
reg [255 : 0] number_y_r;
reg [255 : 0] number_z_w;
reg [255 : 0] number_z_r;

reg [63 : 0] o_out_data_w;

reg [255 : 0] r1_w, r2_w, r3_w, r4_w;
reg [255 : 0] r1_r, r2_r, r3_r, r4_r;

reg [255 : 0] tmp;

reg  [255 : 0] a, b;
wire [255 : 0] mul_out;

reg o_out_valid_w;

// wire dou_enable;
// wire add_enable;
// wire mul_enable;

// permute state
reg [2:0] permute_stage_r, permute_stage_w;
// reg permute_rst;
// reg [255:0] dbl_x_r, dbl_y_r, dbl_z_r;
// reg [255:0] dbl_x_w, dbl_y_w, dbl_z_w;
reg [255:0] P_3_x_r, P_3_y_r, P_3_z_r;
reg [255:0] P_3_x_w, P_3_y_w, P_3_z_w;
reg [255:0] P_5_x_r, P_5_y_r, P_5_z_r;
reg [255:0] P_5_x_w, P_5_y_w, P_5_z_w;
reg [255:0] P_7_x_r, P_7_y_r, P_7_z_r;
reg [255:0] P_7_x_w, P_7_y_w, P_7_z_w;

// sliding window
reg [2:0] win_w, win_r;
reg [255:0] add_x, add_y, add_z;

assign bit_is_1 = scalar_m[index_r];
assign bit_is_1_2 = !(index_r == 2 || index_r == 4);

// assign dou_enable = !(c_state == P_DOU_1 || c_state == P_DOU_2 || c_state == P_DOU_3);
// assign add_enable = !(c_state == P_ADD);
// assign mul_enable = !((c_state == P_DOU_1) || (c_state == P_DOU_2) || (c_state == P_DOU_3) || (c_state == P_ADD) || (c_state == P_RDU_1) || (c_state == P_RDU_2));
assign o_out_valid = o_out_valid_w;
assign o_out_data = o_out_data_w;
assign q = 256'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
assign d = 256'h52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3;

// o_out_data_w
always @ (*)
begin
	if (counter > 3)
	begin
		o_out_data_w = number_x_r[255 - (64 * counter[1 : 0]) -: 64];
	end
	else
	begin
		o_out_data_w = number_y_r[255 - (64 * counter[1 : 0]) -: 64];
	end
end

// stage_counter_w
always @ (*)
begin
	stage_counter_w = stage_counter_r;
	case (c_state)
		P_DOU_1, 
		P_DOU_2, 
		P_DOU_3:
		begin
			if (stage_counter_r == 8)
			begin
				stage_counter_w = 0;
			end
			else
			begin
				stage_counter_w = stage_counter_r + 1;
			end
		end
		P_ADD:
		begin
			if (stage_counter_r == 13)
			begin
				stage_counter_w = 0;
			end
			else
			begin
				stage_counter_w = stage_counter_r + 1;
			end
		end
		P_RDU_1:
		begin
			if (bit_is_1_2)
			begin
				if (stage_counter_r == 4)
				begin
					stage_counter_w = 0;
				end
				else
				begin
					stage_counter_w = stage_counter_r + 1;
				end
			end
			else
			begin
				if (stage_counter_r == 2)
				begin
					stage_counter_w = 0;
				end
				else
				begin
					stage_counter_w = stage_counter_r + 1;
				end
			end
		end
		P_RDU_2:
		begin
			if (stage_counter_r == 3)
				begin
					stage_counter_w = 0;
				end
				else
				begin
					stage_counter_w = stage_counter_r + 1;
				end
			end
		default:
		begin
			stage_counter_w = 0;
		end
	endcase
end

// index_w
always @ (*) begin
	index_w = index_r;
	win_w = win_r;

	case (c_state)
		P_DOU_1:
		begin
			if (permute_stage_r >= 3) begin
				win_w = scalar_m[index_r -:3];
				if (index_r == 1) begin
					win_w = {1'b0, scalar_m[index_r -:2]};
				end
				else if (index_r == 0) begin
					win_w = {2'b00, scalar_m[index_r]};
				end
			end
			
			// i-th bit of M is 0 -> index + 1
			if (!bit_is_1) begin
				// clear index for P_RDU_1
				if (index_r == 0 && stage_counter_r == 8) begin
					index_w = 254;
				end
				else begin
					if (stage_counter_r == 8) begin
						index_w = index_r - 1;
					end
				end
			end

		end
		P_DOU_2: begin
			// clear index for P_RDU_1
			if (index_r == 1 && scalar_m[index_r -:2] == 2'b10 && stage_counter_r == 8) begin
				index_w = 254;
			end

		end
		P_DOU_3: begin
			// clear index for P_RDU_1
			if ((win_r == 3'b100 || win_r == 3'b110) && stage_counter_r == 8) begin
				if (index_r == 2) begin
					index_w = 254;
				end 
				else begin
					index_w = index_r - 3;
				end
			end 
		end
		P_ADD:
		begin
			// clear index for P_RDU_1
			if (permute_stage_r == 2 && stage_counter_r == 13) begin
				index_w = 254;
			end
			else if (index_r == 0 && win_r == 3'b001 && stage_counter_r == 13) begin
				index_w = 254;
			end
			else if (index_r == 1 && win_r == 3'b011 && stage_counter_r == 13) begin
				index_w = 254;
			end
			else if ((win_r == 3'b101 || win_r == 3'b111) && stage_counter_r == 13) begin
				if (index_r == 2) begin
					index_w = 254;
				end 
				else begin
					index_w = index_r - 3;
				end
			end
		end
		P_RDU_1:
		begin
			if (bit_is_1_2)
			begin
				if (stage_counter_r == 4)
				begin
					index_w = index_r - 1;
				end
			end
			else
			begin
				if (stage_counter_r == 2)
				begin
					index_w = index_r - 1;
				end
			end
		end
	endcase
end

// state output 更新原本的point(x,y,z)
always @ (*)
begin
	number_x_w = number_x_r;
	number_y_w = number_y_r;
	number_z_w = number_z_r;
	permute_stage_w = permute_stage_r;
	// permute_rst = 0;
	P_3_x_w = P_3_x_r;
	P_3_y_w = P_3_y_r;
	P_3_z_w = P_3_z_r;
	P_5_x_w = P_5_x_r;
	P_5_y_w = P_5_y_r;
	P_5_z_w = P_5_z_r;
	P_7_x_w = P_7_x_r;
	P_7_y_w = P_7_y_r;
	P_7_z_w = P_7_z_r;

	case (c_state)
		P_DOU_1, 
		P_DOU_2,
		P_DOU_3:
		begin
			if (stage_counter_r == 8)
			begin
				number_x_w = mul_out;
				number_y_w = r2_r;
				number_z_w = r3_r;
			end
			
		end
		P_ADD:
		begin
			if (stage_counter_r == 13)
			begin
				if (permute_stage_r == 0) begin
					P_3_x_w = r1_r;
					P_3_y_w = r2_r;
					P_3_z_w = mul_out;
					permute_stage_w = permute_stage_r + 1;
				end
				else if (permute_stage_r == 1) begin
					P_5_x_w = r1_r;
					P_5_y_w = r2_r;
					P_5_z_w = mul_out;
					permute_stage_w = permute_stage_r + 1;
				end
				else if (permute_stage_r == 2) begin
					P_7_x_w = r1_r;
					P_7_y_w = r2_r;
					P_7_z_w = mul_out;
					permute_stage_w = permute_stage_r + 1;
					number_x_w = 0;
					number_y_w = 1;
					number_z_w = 1;
					// permute_rst = 1;
				end
				else begin
					number_x_w = r1_r;
					number_y_w = r2_r;
					number_z_w = mul_out;
				end
			end
			
		end
		P_RDU_1:
		begin
			if (index_r == 0 && stage_counter_r == 4)
			begin
				number_z_w = mul_out;
			end
		end
		P_RDU_2:
		begin
			if (stage_counter_r == 2)
			begin
				number_x_w = (mul_out[0]) ? q - mul_out : mul_out;
			end
			else if (stage_counter_r == 3)
			begin
				number_y_w = (mul_out[0]) ? q - mul_out : mul_out;
			end
		end
		D_OUT:
		begin
			
		end
	endcase
end

// r1_w, r2_w, r3_w, r4_w, r5_w
// calculate
reg [255:0] number_add_x;
reg [255:0] number_add_y;

always @ (*) begin
	tmp = 0;
	r1_w = r1_r;
	r2_w = r2_r;
	r3_w = r3_r;
	r4_w = r4_r;
	// r5_w = r5_r;
	number_add_x = 0;
	number_add_y = 0;

	// doubling
	case (c_state)
		P_DOU_1,
		P_DOU_2,
		P_DOU_3 : begin
		case (stage_counter_r)
			2:
			begin
				if (permute_stage_r == 0) begin
					number_add_x = number_x;
					number_add_y = number_y;
				end
				else if (permute_stage_r == 1) begin
					number_add_x = number_x_r;
					number_add_y = number_y_r;
				end
				else if (permute_stage_r == 2) begin
					number_add_x = P_3_x_r;
					number_add_y = P_3_y_r;
				end
				else begin
					number_add_x = number_x_r;
					number_add_y = number_y_r;
				end
				r1_w = number_add(number_add_x, number_add_y);
				r2_w = number_sub(255'b0, mul_out); // E
			end
			3:
			begin
				// r1 = X + Y
				// r2 = E
				r3_w = number_sub(r2_r, mul_out); // (E - D)
				r4_w = number_add(r2_r, mul_out); // F
			end
			4:
			begin
				// r2 = E
				// r3 = (E - D)
				// r4 = F
				tmp = number_add(mul_out, mul_out); // (H + H)
				r1_w = number_sub(r4_r, tmp); // F - (H + H), J
			end
			5:
			begin
				// r1 = J
				// r3 = (E - D)
				// r4 = F
				r2_w = number_add(mul_out, r3_r); // B - C - D
			end
			6:
			begin
				r2_w = mul_out;
			end
			7:
			begin
				r3_w = mul_out;
				r4_w = 1;
			end
		endcase
		end
		P_ADD: begin
		case (stage_counter_r)
			0:
			begin
				r1_w = number_add(number_x_r, number_y_r);
			end
			1:
			begin
				// r1 = X1 + Y1
				r2_w = number_add(add_x, add_y);
			end
			2:
			begin
				// r1 = X1 + Y1
				// r2 = X2 + Y2
				r3_w = mul_out; // X1 * X2
			end
			3:
			begin
				// r2 = X2 + Y2
				// r3 = X1 * X2
				r1_w = number_add(r3_r, mul_out); // I
				r4_w = mul_out; // Y1 * Y2
			end
			4:
			begin
				// r1 = I
				// r3 = X1 * X2
				// r4 = Y1 * Y2
				r2_w = mul_out; // Z1 * Z2
			end
			5:
			begin
				// r1 = I
				// r2 = Z1 * Z2
				// r4 = Y1 * Y2
				r3_w = number_sub(mul_out, r1_r); // H
			end
			7:
			begin
				// r1 = I
				// r2 = Z1 * Z2
				// r4 = Y1 * Y2
				r3_w = mul_out; // (Z1 * Z2) * (Z1 * Z2)
			end
			8:
			begin
				// r3 = (Z1 * Z2) * (Z1 * Z2)
				// r4 = Y1 * Y2
				r1_w = mul_out; // d * (X1 * X2) * (Y1 * Y2)
				r2_w = number_sub(r3_r, mul_out); // F
			end
			9:
			begin
				// r1 = d * (X1 * X2) * (Y1 * Y2)
				// r2 = F
				// r3 = (Z1 * Z2) * (Z1 * Z2)
				r4_w = number_add(r3_r, r1_r); // G
			end
			11:
			begin
				r1_w = mul_out; // X3
			end
			12:
			begin
				r2_w = mul_out; // Y3
				r4_w = 1;
			end
		endcase
		end
		P_RDU_1:
		begin
			case (stage_counter_r)
				2: r4_w = mul_out;
				4: r4_w = mul_out;
			endcase
		end
		default:
		begin
			r1_w = 0;
			r2_w = 0;
			r3_w = 0;
			r4_w = 0;
			// r5_w = 0;
		end
	endcase
end

// input
always @ (*)
begin
	a = 0;
	b = 0;
	add_x = 0;
	add_y = 0;
	add_z = 0;
	// doubling
	case (c_state)
		P_DOU_1, 
		P_DOU_2,
		P_DOU_3 : begin
			if (permute_stage_r == 0) begin
				case (stage_counter_r)
					0: {a, b} = {number_x, number_x};
					1: {a, b} = {number_y, number_y};
					2: {a, b} = {256'b1, 256'b1};
					3: {a, b} = {r1_r, r1_r};
					4: {a, b} = {r3_r, r4_r};
					5: {a, b} = {r1_r, r4_r};
					6: {a, b} = {r1_r, r2_r};
				endcase
			end
			else if (permute_stage_r == 1) begin
				case (stage_counter_r)
					0: {a, b} = {number_x_r, number_x_r};
					1: {a, b} = {number_y_r, number_y_r};
					2: {a, b} = {number_z_r, number_z_r};
					3: {a, b} = {r1_r, r1_r};
					4: {a, b} = {r3_r, r4_r};
					5: {a, b} = {r1_r, r4_r};
					6: {a, b} = {r1_r, r2_r};
				endcase
			end
			else if (permute_stage_r == 2) begin
				case (stage_counter_r)
					0: {a, b} = {P_3_x_r, P_3_x_r};
					1: {a, b} = {P_3_y_r, P_3_y_r};
					2: {a, b} = {P_3_z_r, P_3_z_r};
					3: {a, b} = {r1_r, r1_r};
					4: {a, b} = {r3_r, r4_r};
					5: {a, b} = {r1_r, r4_r};
					6: {a, b} = {r1_r, r2_r};
				endcase
			end
			else begin
				case (stage_counter_r)
					0: {a, b} = {number_x_r, number_x_r}; // X * X
					1: {a, b} = {number_y_r, number_y_r}; // Y * Y
					2: {a, b} = {number_z_r, number_z_r}; // Z * Z
					3: {a, b} = {r1_r, r1_r};
					4: {a, b} = {r3_r, r4_r};
					5: {a, b} = {r1_r, r4_r};
					6: {a, b} = {r1_r, r2_r};
				endcase
			end
		end

		// add
		P_ADD: begin
			add_x = number_x;
			add_y = number_y;
			add_z = 256'b1;

			case (win_r)
				3'b100: {add_x, add_y, add_z} = {number_x, number_y, 256'b1};
				3'b101: {add_x, add_y, add_z} = {P_5_x_r, P_5_y_r, P_5_z_r};
				3'b110: {add_x, add_y, add_z} = {P_3_x_r, P_3_y_r, P_3_z_r};
				3'b111: {add_x, add_y, add_z} = {P_7_x_r, P_7_y_r, P_7_z_r};
			endcase
			
			if (index_r == 1) begin
				case (win_r)
					3'b010: {add_x, add_y, add_z} = {number_x, number_y, 256'b1};
					3'b011: {add_x, add_y, add_z} = {P_3_x_r, P_3_y_r, P_3_z_r};
				endcase
			end
			else if (index_r == 0) begin
				case (win_r)
					3'b001: {add_x, add_y, add_z} = {number_x, number_y, 256'b1};
				endcase
			end
			
			case (stage_counter_r)
				0:  {a, b} = {number_x_r, add_x};	// X1 * X2
				1:  {a, b} = {number_y_r, add_y};	// Y1 * Y2
				2:  {a, b} = {number_z_r, add_z};	// Z1 * Z2
				3:  {a, b} = {r1_r, r2_r}; 			// (X1 + X2) * (Y1 + Y2), E
				4:  {a, b} = {d, r3_r};				// d * (X1 * X2)
				5:  {a, b} = {r2_r, r2_r};			// (Z1 * Z2) * (Z1 * Z2)
				6:  {a, b} = {mul_out, r4_r};		// (d * (X1 * X2) * (Y1 * Y2)
				7:  {a, b} = {r2_r, r3_r};			// (Z1 * Z2) * H
				8:  {a, b} = {r2_r, r1_r};			// (Z1 * Z2) * I
				9:  {a, b} = {mul_out, r2_r};		// (Z1 * Z2) * H * F
				10: {a, b} = {mul_out, r4_r};		// (Z1 * Z2) * I * G
				11: {a, b} = {r2_r, r4_r};			// F * G
			endcase
		end
		P_RDU_1:
		begin
			case (stage_counter_r)
				0: {a, b} = {r4_r, r4_r};
				2: {a, b} = {mul_out, number_z_r};
			endcase
		end
		P_RDU_2:
		begin
			case (stage_counter_r)
				0: {a, b} = {number_x_r, number_z_r};
				1: {a, b} = {number_y_r, number_z_r};
			endcase
		end
	endcase
end

// stage_counter_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		stage_counter_r <= 0;
	end
	else
	begin
		stage_counter_r <= stage_counter_w;
	end
end

always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		permute_stage_r <= 0;
	end
	else
	begin
		permute_stage_r <= permute_stage_w;
	end
end

// index_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		index_r <= 254;
	end
	else
	begin
		index_r <= index_w;
	end
end

// point_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		number_x_r <= 0;
		number_y_r <= 1;
		number_z_r <= 1;
	end
	else
	begin
		number_x_r <= number_x_w;
		number_y_r <= number_y_w;
		number_z_r <= number_z_w;
	end
end

// r1_r, r2_r, r3_r, r4_r, r5_r
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		r1_r <= 0;
		r2_r <= 0;
		r3_r <= 0;
		r4_r <= 0;
		// r5_r <= 0;
	end
	else
	begin
		r1_r <= r1_w;
		r2_r <= r2_w;
		r3_r <= r3_w;
		r4_r <= r4_w;
		// r5_r <= r5_w;
	end
end

// Permute table
always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		P_3_x_r <= 0;
		P_3_y_r <= 0;
		P_3_z_r <= 0;
		P_5_x_r <= 0;
		P_5_y_r <= 0;
		P_5_z_r <= 0;
		P_7_x_r <= 0;
		P_7_y_r <= 0;
		P_7_z_r <= 0;
	end
	else
	begin
		P_3_x_r <= P_3_x_w;
		P_3_y_r <= P_3_y_w;
		P_3_z_r <= P_3_z_w;
		P_5_x_r <= P_5_x_w;
		P_5_y_r <= P_5_y_w;
		P_5_z_r <= P_5_z_w;
		P_7_x_r <= P_7_x_w;
		P_7_y_r <= P_7_y_w;
		P_7_z_r <= P_7_z_w;
	end
end

always @ (posedge i_clk)
begin
	if (i_rst)
	begin
		win_r <= 0;
	end
	else
	begin
		win_r <= win_w;
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
			if (i_enable)
			begin
				n_state = IDLE;
			end
			else
			begin
				n_state = P_DOU_1;
			end
		end
		P_DOU_1: begin
			// if i-th bit of M is 1, then do point addition
			if (permute_stage_r < 3 && stage_counter_r == 8) begin
				n_state = P_ADD;
			end
			else if (bit_is_1) begin
				if (stage_counter_r == 8) begin
					case (win_r)
						3'b100: n_state = P_ADD;
						3'b101: n_state = P_DOU_2;
						3'b110: n_state = P_DOU_2;
						3'b111: n_state = P_DOU_2;
						3'b010: n_state = P_ADD;
						3'b011: n_state = P_DOU_2;
						3'b001: n_state = P_ADD;
					endcase
				end
				else
				begin
					n_state = P_DOU_1;
				end
			end
			else
			begin
				if (index_r == 0 && stage_counter_r == 8) begin
					n_state = P_RDU_1;
				end 
				else begin
					n_state = P_DOU_1;
				end
			end
		end
		P_DOU_2: begin
			if (stage_counter_r == 8) begin
				case (win_r)
					3'b100: n_state = P_DOU_3;
					3'b101: n_state = P_DOU_3;
					3'b110: n_state = P_ADD;
					3'b111: n_state = P_DOU_3;
					3'b010: n_state = P_RDU_1;
					3'b011: n_state = P_ADD;
				endcase
			end
			else begin
				n_state = P_DOU_2;
			end
			
		end

		P_DOU_3: begin
			if (stage_counter_r == 8) begin
				case (win_r)
					3'b100: n_state = (index_r == 2)? P_RDU_1: P_DOU_1;
					3'b101: n_state = P_ADD;
					3'b110: n_state = (index_r == 2)? P_RDU_1: P_DOU_1;
					3'b111: n_state = P_ADD;
				endcase
			end
			else begin
				n_state = P_DOU_3;
			end
		end
		P_ADD:
		begin
			if (permute_stage_r < 3 && stage_counter_r == 13) begin
				n_state = P_DOU_1;
			end
			else if (index_r == 0 && stage_counter_r == 13) begin
				n_state = P_RDU_1;
			end
			else begin
				if (stage_counter_r == 13) begin
					case (win_r)
						3'b100: n_state = P_DOU_2;
						3'b101: n_state = (index_r == 2)? P_RDU_1: P_DOU_1;
						3'b110: n_state = P_DOU_3;
						3'b111: n_state = (index_r == 2)? P_RDU_1: P_DOU_1;
						3'b010: n_state = P_DOU_2;
						3'b011: n_state = P_RDU_1;
						3'b001: n_state = P_RDU_1;
					endcase
				end
				else begin
					n_state = P_ADD;
				end
			end
		end
		P_RDU_1:
		begin
			if (index_r == 0 && stage_counter_r == 4)
			begin
				n_state = P_RDU_2;
			end
			else
			begin
				n_state = P_RDU_1;
			end
		end
		P_RDU_2:
		begin
			if (stage_counter_r == 3)
			begin
				n_state = D_OUT;
			end
			else
			begin
				n_state = P_RDU_2;
			end
		end
		D_OUT:
		begin
			if (counter == 3 && i_out_ready)
			begin
				n_state = IDLE;
			end
			else
			begin
				n_state = D_OUT;
			end
		end
	endcase
end

// output logic
always @ (*)
begin
	o_out_valid_w = 0;
	if (c_state == D_OUT)
	begin
		o_out_valid_w = 1;
	end
end

number_mul u_number_mul
(
    .i_clk (i_clk),
    .i_rst (i_rst),

    .a (a),
    .b (b),
	.q (q),
    .c (mul_out)
);

function automatic [255 : 0] number_add;
	input [255 : 0] a;
	input [255 : 0] b;
	reg [255 : 0] r;
	begin
		r = a + b;
		if (r >= q)
		begin
			number_add = r - q;
		end
		else
		begin
			number_add = r;
		end
	end
endfunction

function automatic [255 : 0] number_sub;
	input [255 : 0] a;
	input [255 : 0] b;
	reg [255 : 0] r;
	begin
		if (a >= b)
		begin
			number_sub = a - b;
		end
		else
		begin
			number_sub = q - (b - a);
		end
	end
endfunction

endmodule