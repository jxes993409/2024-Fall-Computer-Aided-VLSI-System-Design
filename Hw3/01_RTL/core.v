`define FUNC_AUTOMATIC automatic
module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// ---------------------------------------------------------------------------
// Local Parameters
// ---------------------------------------------------------------------------

localparam   	  LOAD_DATA = 6'd0;
localparam 		RIGHT_SHIFT = 6'd1;
localparam 		 LEFT_SHIFT = 6'd2;
localparam 		   UP_SHIFT = 6'd3;
localparam 		 DOWN_SHIFT = 6'd4;
localparam   REDUCE_CHANNEL = 6'd5;
localparam INCREASE_CHANNEL = 6'd6;
localparam    DISPLAY_PIXEL = 6'd7;
localparam    CONVOLUTION_0 = 6'd8;
localparam    CONVOLUTION_1 = 6'd14;
localparam    CONVOLUTION_2 = 6'd15;
localparam    CONVOLUTION_3 = 6'd16;
localparam    CONVOLUTION_4 = 6'd17;
localparam 	   FEATURE_LOAD = 6'd9;
localparam SOBEL_GRADIENT_0 = 6'd10;
localparam SOBEL_GRADIENT_1 = 6'd18;
localparam SOBEL_GRADIENT_2 = 6'd19;
localparam SOBEL_GRADIENT_3 = 6'd20;
localparam SOBEL_GRADIENT_4 = 6'd21;
localparam    MEDIAN_FILTER = 6'd22;

localparam 			   IDLE = 6'd11;
localparam 			   INIT = 6'd12;
localparam 			 GET_OP = 6'd13;


// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //


reg o_op_ready_w;

reg o_out_valid_w;
reg o_out_valid_r;

reg [13 : 0] o_out_data_w;
reg [13 : 0] o_out_data_r;

reg [3 : 0] i_op_mode_w;
reg [3 : 0] i_op_mode_r;

reg [5 : 0] current_state;
reg [5 : 0] next_state;

reg [10 : 0] data_addr_w;
reg [10 : 0] data_addr_r;

reg [3 : 0] CEN;
reg [3 : 0] WEN;

wire [7 : 0] data_out [3 : 0];

reg [5 : 0] point_w;
reg [5 : 0] point_r;

reg [5 : 0] point_index_w;
reg [5 : 0] point_index_r;

reg [4 : 0] depth_w;
reg [4 : 0] depth_r;

reg [4 : 0] current_depth_w;
reg [4 : 0] current_depth_r;

reg is_start_writing_w;
reg is_start_writing_r;

reg is_need_padding_w;
reg is_need_padding_r;

reg is_not_bound;

reg [12 : 0] buffer_w [15 : 0];
reg [12 : 0] buffer_r [15 : 0];

reg [16 : 0] accumulate_w;
reg [16 : 0] accumulate_r;
reg [16 : 0] accumulate_temp;

reg [5 : 0] array_index;
reg [5 : 0] loop_array_index [15 : 0];
reg [3 : 0] loop_integer [15 : 0];
reg [5 : 0] point_w_offset;
reg [8 : 0] depth_offset;

reg [12 : 0] feature_map_w [63 : 0];
reg [12 : 0] feature_map_r [63 : 0];

wire [7 : 0] sort_array [8 : 0];
wire [7 : 0] sort_median;
wire sort_enable;
wire sort_out_valid;

reg [7 : 0] sort_array_w [8 : 0];
reg sort_enable_w;

reg signed [10 : 0] gradient_x_w;
reg signed [10 : 0] gradient_x_r;
reg signed [10 : 0] gradient_x_temp;
reg signed [10 : 0] gradient_y_temp;
reg signed [10 : 0] gradient_y_w;
reg signed [10 : 0] gradient_y_r;

reg [10 : 0] gradient_w [3 : 0];
reg [10 : 0] gradient_r [3 : 0];

reg [1 : 0] direction_w [3 : 0];
reg [1 : 0] direction_r [3 : 0];

reg int_part;

wire [9 : 0] dividend;
wire [9 : 0] divisor;
wire [16 : 0] quotient;
wire div_enable;
wire div_out_valid;

reg div_enable_w;

integer i;
genvar i_g;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

assign o_in_ready = 1;
assign o_out_valid = o_out_valid_r;
assign o_op_ready = o_op_ready_w;
assign o_out_data = o_out_data_r;

assign sort_enable = sort_enable_w;
assign div_enable = div_enable_w;

assign dividend = (current_state == SOBEL_GRADIENT_3) ? func_abs(gradient_y_r) : 0;
assign  divisor = (current_state == SOBEL_GRADIENT_3) ? func_abs(gradient_x_r) : 0;

generate
	for (i_g = 0; i_g < 9; i_g = i_g + 1)
	begin
		assign sort_array[i_g] = (!sort_enable_w) ? sort_array_w[i_g] : 0;
	end
endgenerate

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @ (*)
begin
	is_start_writing_w = i_in_valid;
end


always @ (*)
begin
	o_op_ready_w = 0;

	o_out_valid_w = 0;
	o_out_data_w = 0;

	i_op_mode_w = i_op_mode_r;
	
	data_addr_w = data_addr_r;
	point_index_w = point_index_r;
	current_depth_w = current_depth_r;
	depth_w = depth_r;
	point_w = point_r;

	is_not_bound = 0;

	is_need_padding_w = 0;
	point_w_offset = 0;
	depth_offset = 0;
	array_index = 0;

	accumulate_w = accumulate_r;
	accumulate_temp = 0;

	for (i = 0; i < 16; i = i + 1)
	begin
		loop_integer[i] = 0;
		loop_array_index[i] = 0;
	end

	// sort 
	for (i = 0; i < 9; i = i + 1)
	begin
		sort_array_w[i] = 0;
	end
	sort_enable_w = 1;

	gradient_x_w = gradient_x_r;
	gradient_y_w = gradient_y_r;

	gradient_x_temp = 0;
	gradient_y_temp = 0;

	int_part = 0;

	// div
	div_enable_w = 1;

	CEN = 4'b1111;
	WEN = 4'b1111;

	for (i = 0; i < 16; i = i + 1)
	begin
		buffer_w[i] = buffer_r[i];
	end

	for (i = 0; i < 64; i = i + 1)
	begin
		feature_map_w[i] = feature_map_r[i];
	end

	for (i = 0; i < 4; i = i + 1)
	begin
		gradient_w[i] = gradient_r[i];
	end

	for (i = 0; i < 4; i = i + 1)
	begin
		direction_w[i] = direction_r[i];
	end
	case (current_state)
		IDLE:
		begin
			o_op_ready_w = 1;
			i_op_mode_w = 0;
			point_index_w = 0;
			current_depth_w = 0;
			data_addr_w = 0;

			accumulate_w = 0;

			gradient_x_w = 0;
			gradient_y_w = 0;

			for (i = 0; i < 16; i = i + 1)
			begin
				buffer_w[i] = 0;
			end

			for (i = 0; i < 4; i = i + 1)
			begin
				gradient_w[i] = 0;
			end

			for (i = 0; i < 4; i = i + 1)
			begin
				direction_w[i] = 0;
			end
		end
		GET_OP:
		begin
			i_op_mode_w = i_op_mode;
		end
		LOAD_DATA:
		begin
			data_addr_w = data_addr_r + is_start_writing_r;
			CEN = decoder_2_to_4(data_addr_w[10 : 9]);
			WEN = decoder_2_to_4(data_addr_w[10 : 9]);
			array_index = data_addr_w[5 : 0];
			feature_map_w[array_index] = {5'b0, i_in_data} + feature_map_r[array_index];
		end
		RIGHT_SHIFT:
		begin
			is_not_bound = (point_w[2 : 0] != 3'b110);
			if (is_not_bound)
			begin
				point_w = point_r + 1;
			end
		end
		LEFT_SHIFT:
		begin
			// point_w = point_r;
			is_not_bound = (|point_w[2 : 0]);
			if (is_not_bound)
			begin
				point_w = point_r - 1;
			end
		end
		UP_SHIFT:
		begin
			// point_w = point_r;
			is_not_bound = (|point_w[5 : 3]);
			if (is_not_bound)
			begin
				point_w = point_r - 8;
			end
		end
		DOWN_SHIFT:
		begin
			// point_w = point_r;
			is_not_bound = (point_w[5 : 3] != 3'b110);
			if (is_not_bound)
			begin
				point_w = point_r + 8;
			end
		end
		REDUCE_CHANNEL:
		begin
			if (depth_w != 7)
			begin
				// depth_w = depth_r >> 1;
				depth_w = {1'b0, depth_r[4 : 1]};
			end
		end
		INCREASE_CHANNEL:
		begin
			if (depth_w != 31)
			begin
				// depth_w = (depth_r << 1) + 1;
				depth_w = {depth_r[3 : 0], 1'b1};
			end
		end
		DISPLAY_PIXEL:
		begin
			CEN = decoder_2_to_4(current_depth_w[4 : 3]);
			// 64 * 4 + 64 * 2 + 64 * 1
			depth_offset = {current_depth_w[2 : 0]} << 6;
			data_addr_w = {point_index_w[1], 2'b0, point_index_w[0]} + depth_offset + point_w;
			
			if (point_index_r != 6'b0 || current_depth_r[2 : 0] != 3'b0)
			begin
				o_out_valid_w = 1;
				o_out_data_w = {6'b0, data_out[current_depth_w[4 : 3]]};
			end

			// when depth = 7, 15, 23, have to wait a cycle for change sdram
			// hence, point_index_w = point_index_r + 1 for stall a cycle
			if (point_index_w < 6'd3 || (current_depth_r[2 : 0] == 3'b111 && point_index_w == 6'd3))
			begin
				point_index_w = point_index_r + 1;
			end
			else
			begin
				point_index_w = 0;
				current_depth_w = current_depth_r + 1;
			end

		end
		CONVOLUTION_0:
		begin
			depth_offset = {current_depth_w[2 : 0]} << 6;
			point_w_offset = (point_w - 9) + ({point_index_w[3 : 2]} << 2) + point_index_w[3 : 0];

			is_need_padding_w = is_need_padding(point_index_w[3 : 2], point_w[5 : 3], point_w_offset[5 : 3]);
			data_addr_w = depth_offset + point_w_offset;

			if (!is_need_padding_w)
			begin
				case (depth_w[3])
					1'b0: // depth = 8
					begin
						CEN = 4'b1110;
					end
					1'b1: // depth = 16
					begin
						CEN = 4'b1100;
					end
				endcase
			end

			if (!is_need_padding_r && point_index_w != 6'd0)
			begin
				array_index = point_index_w - 6'd1;
				case (depth_w[3])
					1'b0: // depth = 8
					begin
						buffer_w[array_index[3 : 0]] = data_out[0] + buffer_r[array_index[3 : 0]];
					end
					1'b1: // depth = 16
					begin
						buffer_w[array_index[3 : 0]] = data_out[0] + data_out[1] + buffer_r[array_index[3 : 0]];
					end
				endcase
			end

			// point_index_w == 16
			if (point_index_w[4])
			begin
				point_index_w = 0;
				current_depth_w = current_depth_r + 1;
			end
			else
			begin
				point_index_w = point_index_r + 1;
			end
		end
		CONVOLUTION_1:
		begin
			// o_out_data_w = {1'b0, rounding(accumulate)};
			case (point_index_w[1 : 0])
				2'b00: accumulate_temp = conv_accumulate_1('{buffer_w[ 0], buffer_w[ 1], buffer_w[ 2]});
				2'b01: accumulate_temp = conv_accumulate_1('{buffer_w[ 1], buffer_w[ 2], buffer_w[ 3]});
				2'b10: accumulate_temp = conv_accumulate_1('{buffer_w[ 4], buffer_w[ 5], buffer_w[ 6]});
				2'b11: accumulate_temp = conv_accumulate_1('{buffer_w[ 5], buffer_w[ 6], buffer_w[ 7]});
			endcase

			accumulate_w = accumulate_temp;
		end
		CONVOLUTION_2:
		begin
			case (point_index_w[1 : 0])
				2'b00: accumulate_temp = conv_accumulate_2('{buffer_w[ 4], buffer_w[ 5], buffer_w[ 6]});
				2'b01: accumulate_temp = conv_accumulate_2('{buffer_w[ 5], buffer_w[ 6], buffer_w[ 7]});
				2'b10: accumulate_temp = conv_accumulate_2('{buffer_w[ 8], buffer_w[ 9], buffer_w[10]});
				2'b11: accumulate_temp = conv_accumulate_2('{buffer_w[ 9], buffer_w[10], buffer_w[11]});
			endcase
			accumulate_w = accumulate_temp + accumulate_r;
		end
		CONVOLUTION_3:
		begin
			case (point_index_w[1 : 0])
				2'b00: accumulate_temp = conv_accumulate_1('{buffer_w[ 8], buffer_w[ 9], buffer_w[10]});
				2'b01: accumulate_temp = conv_accumulate_1('{buffer_w[ 9], buffer_w[10], buffer_w[11]});
				2'b10: accumulate_temp = conv_accumulate_1('{buffer_w[12], buffer_w[13], buffer_w[14]});
				2'b11: accumulate_temp = conv_accumulate_1('{buffer_w[13], buffer_w[14], buffer_w[15]});
			endcase
			accumulate_w = accumulate_temp + accumulate_r;
			o_out_data_w = {1'b0, rounding(accumulate_w)};
			o_out_valid_w = 1;

			point_index_w = point_index_r + 1;
		end
		CONVOLUTION_4:
		begin
			for (i = 0; i < 16; i = i + 1)
			begin
				loop_integer[i] = i;
				loop_array_index[i] = (point_w - 9) + ({loop_integer[i][3 : 2]} << 2) + loop_integer[i];
				if (is_need_padding(loop_integer[i][3 : 2], point_w[5 : 3], loop_array_index[i][5 : 3]))
				begin
					buffer_w[i] = 0;
				end
				else
				begin
					buffer_w[i] = feature_map_w[loop_array_index[i]];
				end
			end
		end
		FEATURE_LOAD:
		begin
			depth_offset = {current_depth_w[2 : 0]} << 6;
			point_w_offset = (point_w - 9) + ({point_index_w[3 : 2]} << 2) + point_index_w[3 : 0];

			is_need_padding_w = is_need_padding(point_index_w[3 : 2], point_w[5 : 3], point_w_offset[5 : 3]);
			data_addr_w = depth_offset + point_w_offset;
			
			if (!is_need_padding_w)
			begin
				CEN = 4'b1110;
			end

			if (!is_need_padding_r && point_index_w != 6'd0)
			begin
				array_index = point_index_w - 6'd1;
				buffer_w[array_index[3 : 0]] = {6'b0, data_out[0]};
			end

			// point_index_w == 16
			if (point_index_w[4])
			begin
				point_index_w = 0;
			end
			else
			begin
				point_index_w = point_index_r + 1;
			end
		end
		MEDIAN_FILTER:
		begin
			case (point_index_w[1 : 0])
				2'b00:
				begin
					sort_array_w =
					'{
						buffer_w[ 0][7 : 0], buffer_w[ 1][7 : 0], buffer_w[ 2][7 : 0],
						buffer_w[ 4][7 : 0], buffer_w[ 5][7 : 0], buffer_w[ 6][7 : 0],
						buffer_w[ 8][7 : 0], buffer_w[ 9][7 : 0], buffer_w[10][7 : 0]
					};
				end
				2'b01:
				begin
					sort_array_w =
					'{
						buffer_w[ 1][7 : 0], buffer_w[ 2][7 : 0], buffer_w[ 3][7 : 0],
						buffer_w[ 5][7 : 0], buffer_w[ 6][7 : 0], buffer_w[ 7][7 : 0],
						buffer_w[ 9][7 : 0], buffer_w[10][7 : 0], buffer_w[11][7 : 0]
					};
				end
				2'b10:
				begin
					sort_array_w =
					'{
						buffer_w[ 4][7 : 0], buffer_w[ 5][7 : 0], buffer_w[ 6][7 : 0],
						buffer_w[ 8][7 : 0], buffer_w[ 9][7 : 0], buffer_w[10][7 : 0],
						buffer_w[12][7 : 0], buffer_w[13][7 : 0], buffer_w[14][7 : 0]
					};
				end
				2'b11:
				begin
					sort_array_w =
					'{
						buffer_w[ 5][7 : 0], buffer_w[ 6][7 : 0], buffer_w[ 7][7 : 0],
						buffer_w[ 9][7 : 0], buffer_w[10][7 : 0], buffer_w[11][7 : 0],
						buffer_w[13][7 : 0], buffer_w[14][7 : 0], buffer_w[15][7 : 0]
					};
				end
			endcase
			sort_enable_w = 0;
			if (sort_out_valid)
			begin
				if (point_index_w[1 : 0] == 2'd3)
				begin
					point_index_w = 0;
					current_depth_w = current_depth_r + 1;
				end
				else
				begin
					point_index_w = point_index_r + 1;
				end
				o_out_valid_w = 1;
				o_out_data_w = {6'b0, sort_median};
			end
		end
		SOBEL_GRADIENT_0:
		begin
			case (point_index_w[1 : 0])
				2'b00:
				begin
					gradient_x_temp =
						// (~buffer_w[0][7 : 0] + 1) + (~{buffer_w[4][7 : 0], 1'b0} + 1) +	(~buffer_w[8][7 : 0] + 1);
						(~(buffer_w[0][7 : 0] + buffer_w[8][7 : 0]) + 1);
						// ({buffer_w[6][7 : 0], 1'b0} - {buffer_w[4][7 : 0], 1'b0});
					gradient_y_temp =
						// (~buffer_w[0][7 : 0] + 1) + (~{buffer_w[1][7 : 0], 1'b0} + 1) + (~buffer_w[2][7 : 0] + 1);
						(~(buffer_w[0][7 : 0] + buffer_w[2][7 : 0]) + 1);
						// ({buffer_w[9][7 : 0], 1'b0} - {buffer_w[1][7 : 0], 1'b0});
				end
				2'b01:
				begin
					gradient_x_temp =
						// (~buffer_w[1][7 : 0] + 1) +	(~{buffer_w[5][7 : 0], 1'b0} + 1) +	(~buffer_w[9][7 : 0] + 1);
						(~(buffer_w[1][7 : 0] + buffer_w[9][7 : 0]) + 1);
						// ({buffer_w[7][7 : 0], 1'b0} - {buffer_w[5][7 : 0], 1'b0});
					gradient_y_temp =
						// (~buffer_w[1][7 : 0] + 1) + (~{buffer_w[2][7 : 0], 1'b0} + 1) + (~buffer_w[3][7 : 0] + 1);
						(~(buffer_w[1][7 : 0] + buffer_w[3][7 : 0]) + 1);
						// ({buffer_w[10][7 : 0], 1'b0} - {buffer_w[2][7 : 0], 1'b0});
				end
				2'b10:
				begin
					gradient_x_temp =
						// (~buffer_w[4][7 : 0] + 1) + (~{buffer_w[8][7 : 0], 1'b0} + 1) + (~buffer_w[12][7 : 0] + 1);
						(~(buffer_w[4][7 : 0] + buffer_w[12][7 : 0]) + 1);
						// ({buffer_w[10][7 : 0], 1'b0} - {buffer_w[8][7 : 0], 1'b0});
					gradient_y_temp =
						// (~buffer_w[4][7 : 0] + 1) + (~{buffer_w[5][7 : 0], 1'b0} + 1) + (~buffer_w[6][7 : 0] + 1);
						(~(buffer_w[4][7 : 0] + buffer_w[6][7 : 0]) + 1);
						// ({buffer_w[13][7 : 0], 1'b0} - {buffer_w[5][7 : 0], 1'b0});
				end
				2'b11:
				begin
					gradient_x_temp =
						// (~buffer_w[5][7 : 0] + 1) +	(~{buffer_w[9][7 : 0], 1'b0} + 1) +	(~buffer_w[13][7 : 0] + 1);
						(~(buffer_w[5][7 : 0] + buffer_w[13][7 : 0]) + 1);
						// ({buffer_w[11][7 : 0], 1'b0} - {buffer_w[9][7 : 0], 1'b0});
					gradient_y_temp =
						// (~buffer_w[5][7 : 0] + 1) + (~{buffer_w[6][7 : 0], 1'b0} + 1) + (~buffer_w[7][7 : 0] + 1);
						(~(buffer_w[5][7 : 0] + buffer_w[7][7 : 0]) + 1);
						// ({buffer_w[14][7 : 0], 1'b0} - {buffer_w[6][7 : 0], 1'b0});
				end
			endcase

			gradient_x_w = gradient_x_temp;
			gradient_y_w = gradient_y_temp;
		end
		SOBEL_GRADIENT_1:
		begin
			case (point_index_w[1 : 0])
				2'b00:
				begin
					gradient_x_temp =
						// (~buffer_w[0][7 : 0] + 1) + (~{buffer_w[4][7 : 0], 1'b0} + 1) +	(~buffer_w[8][7 : 0] + 1);
						(buffer_w[6][7 : 0] - buffer_w[4][7 : 0]) << 1;
					gradient_y_temp =
						// (~buffer_w[0][7 : 0] + 1) + (~{buffer_w[1][7 : 0], 1'b0} + 1) + (~buffer_w[2][7 : 0] + 1);
						(buffer_w[9][7 : 0] - buffer_w[1][7 : 0]) << 1;
				end
				2'b01:
				begin
					gradient_x_temp =
						// (~buffer_w[1][7 : 0] + 1) +	(~{buffer_w[5][7 : 0], 1'b0} + 1) +	(~buffer_w[9][7 : 0] + 1);
						(buffer_w[7][7 : 0] - buffer_w[5][7 : 0]) << 1;
					gradient_y_temp =
						// (~buffer_w[1][7 : 0] + 1) + (~{buffer_w[2][7 : 0], 1'b0} + 1) + (~buffer_w[3][7 : 0] + 1);
						(buffer_w[10][7 : 0] - buffer_w[2][7 : 0]) << 1;
				end
				2'b10:
				begin
					gradient_x_temp =
						// (~buffer_w[4][7 : 0] + 1) + (~{buffer_w[8][7 : 0], 1'b0} + 1) + (~buffer_w[12][7 : 0] + 1);
						(buffer_w[10][7 : 0] - buffer_w[8][7 : 0]) << 1;
					gradient_y_temp =
						// (~buffer_w[4][7 : 0] + 1) + (~{buffer_w[5][7 : 0], 1'b0} + 1) + (~buffer_w[6][7 : 0] + 1);
						(buffer_w[13][7 : 0] - buffer_w[5][7 : 0]) << 1;
				end
				2'b11:
				begin
					gradient_x_temp =
						// (~buffer_w[5][7 : 0] + 1) +	(~{buffer_w[9][7 : 0], 1'b0} + 1) +	(~buffer_w[13][7 : 0] + 1);
						(buffer_w[11][7 : 0] - buffer_w[9][7 : 0]) << 1;
					gradient_y_temp =
						// (~buffer_w[5][7 : 0] + 1) + (~{buffer_w[6][7 : 0], 1'b0} + 1) + (~buffer_w[7][7 : 0] + 1);
						(buffer_w[14][7 : 0] - buffer_w[6][7 : 0]) << 1;
				end
			endcase

			gradient_x_w = gradient_x_temp + gradient_x_r;
			gradient_y_w = gradient_y_temp + gradient_y_r;
		end
		SOBEL_GRADIENT_2:
		begin
			case (point_index_w[1 : 0])
				2'b00:
				begin
					gradient_x_temp =
						// buffer_w[2][7 : 0] + {buffer_w[6][7 : 0], 1'b0} + buffer_w[10][7 : 0];
						buffer_w[2][7 : 0] + buffer_w[10][7 : 0];
					gradient_y_temp =
						// buffer_w[8][7 : 0] + {buffer_w[9][7 : 0], 1'b0} + buffer_w[10][7 : 0];
						buffer_w[8][7 : 0] + buffer_w[10][7 : 0];
				end
				2'b01:
				begin
					gradient_x_temp =
						// buffer_w[3][7 : 0] + {buffer_w[7][7 : 0], 1'b0} + buffer_w[11][7 : 0];
						buffer_w[3][7 : 0] + buffer_w[11][7 : 0];
					gradient_y_temp =
						// buffer_w[9][7 : 0] + {buffer_w[10][7 : 0], 1'b0} + buffer_w[11][7 : 0];
						buffer_w[9][7 : 0] + buffer_w[11][7 : 0];
				end
				2'b10:
				begin
					gradient_x_temp =
						// buffer_w[6][7 : 0] + {buffer_w[10][7 : 0], 1'b0} + buffer_w[14][7 : 0];
						buffer_w[6][7 : 0] + buffer_w[14][7 : 0];
					gradient_y_temp =
						// buffer_w[12][7 : 0] + {buffer_w[13][7 : 0], 1'b0} + buffer_w[14][7 : 0];
						buffer_w[12][7 : 0] + buffer_w[14][7 : 0];
				end
				2'b11:
				begin
					gradient_x_temp =
						// buffer_w[7][7 : 0] + {buffer_w[11][7 : 0], 1'b0} + buffer_w[15][7 : 0];
						buffer_w[7][7 : 0] + buffer_w[15][7 : 0];
					gradient_y_temp =
						// buffer_w[13][7 : 0] + {buffer_w[14][7 : 0], 1'b0} + buffer_w[15][7 : 0];
						buffer_w[13][7 : 0] + buffer_w[15][7 : 0];
				end
			endcase

			gradient_x_w = gradient_x_r + gradient_x_temp;
			gradient_y_w = gradient_y_r + gradient_y_temp;
			gradient_w[point_index_w[1 : 0]] = func_abs(gradient_x_w) + func_abs(gradient_y_w);
		end
		SOBEL_GRADIENT_3:
		begin
			case ({gradient_x_w[9 : 0] == 10'b0, gradient_y_w[9 : 0] == 10'b0})
				2'b00:
				begin
					div_enable_w = 0;
					if (div_out_valid)
					begin

						int_part = |quotient[16 : 7];
						if (gradient_x_w[10] ^ gradient_y_w[10])
						begin
							// 90 ~ 135
							if (int_part)
							begin
								if (quotient >= 17'b10_0110101)
								begin
									direction_w[point_index_w[1 : 0]] = 2;
								end
								else
								begin
									direction_w[point_index_w[1 : 0]] = 3;
								end
							end
							// 135 ~ 180
							else
							begin
								if (quotient[6 : 0] >= 7'b0110101)
								begin
									direction_w[point_index_w[1 : 0]] = 3;
								end
								else
								begin
									direction_w[point_index_w[1 : 0]] = 0;
								end
							end
						end
						else
						begin
							// 45 ~ 90
							if (int_part)
							begin
								if (quotient <= 17'b10_0110101)
								begin
									direction_w[point_index_w[1 : 0]] = 1;
								end
								else
								begin
									direction_w[point_index_w[1 : 0]] = 2;
								end
							end
							// 0 ~ 45
							else
							begin
								if (quotient[6 : 0] >= 7'b0110101)
								begin
									direction_w[point_index_w[1 : 0]] = 1;
								end
								else
								begin
									direction_w[point_index_w[1 : 0]] = 0;
								end
							end
						end
					end
				end
				2'b01, 2'b11:
				begin
					direction_w[point_index_w[1 : 0]] = 0;
				end
				2'b10:
				begin
					direction_w[point_index_w[1 : 0]] = 2;
				end
			endcase

			if ((gradient_x_w[9 : 0] == 10'b0 || gradient_y_w[9 : 0] == 10'b0) || div_out_valid)
			begin
				if (point_index_w[1 : 0] == 2'd3)
				begin
					point_index_w = 0;
				end
				else
				begin
					point_index_w = point_index_r + 1;
				end
			end
		end
		SOBEL_GRADIENT_4:
		begin
			o_out_data_w = {3'b0, gradient_w[point_index_w[1 : 0]]};

			if (gradient_w[point_index_w[1 : 0]] > 11'b0)
			begin
				case (point_index_w[1 : 0])
					2'b00:
					begin
						case (direction_w[0])
							2'b00:
							begin
								if (gradient_w[0] < gradient_w[1])
								begin
									o_out_data_w = 0;
								end
							end
							2'b01:
							begin
								if (gradient_w[0] < gradient_w[3])
								begin
									o_out_data_w = 0;
								end
							end
							2'b10:
							begin
								if (gradient_w[0] < gradient_w[2])
								begin
									o_out_data_w = 0;
								end
							end
						endcase
					end
					2'b01:
					begin
						case (direction_w[1])
							2'b00:
							begin
								if (gradient_w[1] < gradient_w[0])
								begin
									o_out_data_w = 0;
								end
							end
							2'b10:
							begin
								if (gradient_w[1] < gradient_w[3])
								begin
									o_out_data_w = 0;
								end
							end
							2'b11:
							begin
								if (gradient_w[1] < gradient_w[2])
								begin
									o_out_data_w = 0;
								end
							end
						endcase
					end
					2'b10:
					begin
						case (direction_w[2])
							2'b00:
							begin
								if (gradient_w[2] < gradient_w[3])
								begin
									o_out_data_w = 0;
								end
							end
							2'b10:
							begin
								if (gradient_w[2] < gradient_w[0])
								begin
									o_out_data_w = 0;
								end
							end
							2'b11:
							begin
								if (gradient_w[2] < gradient_w[1])
								begin
									o_out_data_w = 0;
								end
							end
						endcase
					end
					2'b11:
					begin
						case (direction_w[3])
							2'b00:
							begin
								if (gradient_w[3] < gradient_w[2])
								begin
									o_out_data_w = 0;
								end
							end
							2'b01:
							begin
								if (gradient_w[3] < gradient_w[0])
								begin
									o_out_data_w = 0;
								end
							end
							2'b10:
							begin
								if (gradient_w[3] < gradient_w[1])
								begin
									o_out_data_w = 0;
								end
							end
						endcase
					end
				endcase
			end

			o_out_valid_w = 1;

			if (point_index_w[1 : 0] == 2'd3)
			begin
				point_index_w = 0;
				current_depth_w = current_depth_r + 1;
			end
			else
			begin
				point_index_w = point_index_r + 1;
			end
		end
	endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

// is_start_writing
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		is_start_writing_r <= 0;
	end
	else
	begin
		is_start_writing_r <= is_start_writing_w;
	end
end

// is_need_padding
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		is_need_padding_r <= 0;
	end
	else
	begin
		is_need_padding_r <= is_need_padding_w;
	end
end

// i_op_mode
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		i_op_mode_r <= 0;
	end
	else
	begin
		i_op_mode_r <= i_op_mode_w;
	end
end

// o_out_data
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		o_out_data_r <= 0;
	end
	else
	begin
		o_out_data_r <= o_out_data_w;
	end
end

// o_out_valid
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		o_out_valid_r <= 0;
	end
	else
	begin
		o_out_valid_r <= o_out_valid_w;
	end
end

// data_addr
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		data_addr_r <= 0;
	end
	else
	begin
		data_addr_r <= data_addr_w;
	end
end

// point
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		point_r <= 0;
	end
	else
	begin
		point_r <= point_w;
	end
end

// feature_map
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		for (i = 0; i < 64; i = i + 1)
		begin
			feature_map_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 64; i = i + 1)
		begin
			feature_map_r[i] <= feature_map_w[i];
		end
	end
end

// buffer
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		for (i = 0; i < 16; i = i + 1)
		begin
			buffer_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 16; i = i + 1)
		begin
			buffer_r[i] <= buffer_w[i];
		end
	end
end

// point_index
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		point_index_r <= 0;
	end
	else
	begin
		point_index_r <= point_index_w;
	end
end

// depth
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		depth_r <= 31;
	end
	else
	begin
		depth_r <= depth_w;
	end
end

// current_depth
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		current_depth_r <= 0;
	end
	else
	begin
		current_depth_r <= current_depth_w;
	end
end

// accumulate
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		accumulate_r <= 0;
	end
	else
	begin
		accumulate_r <= accumulate_w;
	end
end

// gradient_x, gradient_y
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		gradient_x_r <= 0;
		gradient_y_r <= 0;
	end
	else
	begin
		gradient_x_r <= gradient_x_w;
		gradient_y_r <= gradient_y_w;
	end
end

// gradient
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		for (i = 0; i < 4; i = i + 1)
		begin
			gradient_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 4; i = i + 1)
		begin
			gradient_r[i] <= gradient_w[i];
		end
	end
end

// direction
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		for (i = 0; i < 4; i = i + 1)
		begin
			direction_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 4; i = i + 1)
		begin
			direction_r[i] <= direction_w[i];
		end
	end
end

// FSM
// CS
always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		current_state <= INIT;
	end
	else
	begin
		current_state <= next_state;
	end
end

// NS
always @ (*)
begin
	case (current_state)
		INIT: next_state = IDLE;
		IDLE: next_state = GET_OP;
		GET_OP:
		begin
			if (i_op_valid)
			begin
				case (i_op_mode)
					4'd8:
					begin
						if (depth_r[4])
						begin
							next_state = CONVOLUTION_4;
						end
						else
						begin
							next_state = CONVOLUTION_0;
						end
					end
					4'd10:
					begin
						next_state = FEATURE_LOAD;
					end
					default:
					begin
						next_state = i_op_mode;
					end
				endcase
			end
			else
			begin
				next_state = GET_OP;
			end
		end
		LOAD_DATA:
		begin
			if (data_addr_r < 11'd2046)
			begin
				next_state = LOAD_DATA;
			end
			else
			begin
				next_state = INIT;
			end
		end
		DISPLAY_PIXEL:
		begin
			if (current_depth_r < depth_r)
			begin
				next_state = DISPLAY_PIXEL;
			end
			else if (current_depth_r == depth_r && point_index_r < 6'd4)
			begin
				next_state = DISPLAY_PIXEL;
			end
			else
			begin
				next_state = INIT;
			end
		end
		CONVOLUTION_0:
		begin

			if (current_depth_r[2 : 0] < 3'd7)
			begin
				next_state = CONVOLUTION_0;
			end
			// current_depth_r == 7 && point_index_r < 16
			else if (current_depth_r[2 : 0] == 3'd7 && !point_index_r[4])
			begin
				next_state = CONVOLUTION_0;
			end
			else
			begin
				next_state = CONVOLUTION_1;
			end
		end
		CONVOLUTION_1: next_state = CONVOLUTION_2;
		CONVOLUTION_2: next_state = CONVOLUTION_3;
		CONVOLUTION_3:
		begin
			if (point_index_r[1 : 0] < 2'd3)
			begin
				next_state = CONVOLUTION_1;
			end
			else
			begin
				next_state = INIT;
			end
		end
		CONVOLUTION_4: next_state = CONVOLUTION_1;
		FEATURE_LOAD:
		begin
			// point_index_r < 16
			if (!point_index_r[4])
			begin
				next_state = FEATURE_LOAD;
			end
			// point_index_r == 16 && current_depth_r < 4
			else
			begin
				// i_op_mode_r == 9
				if (i_op_mode_r[0])
				begin
					next_state = MEDIAN_FILTER;
				end
				else
				begin
					next_state = SOBEL_GRADIENT_0;
				end
			end
		end
		MEDIAN_FILTER:
		begin
			if (point_index_r[1 : 0] == 2'd3 && o_out_valid_w)
			begin
				if (current_depth_r[1 : 0] == 2'd3)
				begin
					next_state = INIT;
				end
				else
				begin
					next_state = FEATURE_LOAD;
				end
			end
			else
			begin
				next_state = MEDIAN_FILTER;
			end
		end
		SOBEL_GRADIENT_0: next_state = SOBEL_GRADIENT_1;
		SOBEL_GRADIENT_1: next_state = SOBEL_GRADIENT_2;
		SOBEL_GRADIENT_2: next_state = SOBEL_GRADIENT_3;
		SOBEL_GRADIENT_3:
		begin
			if (!div_out_valid && (gradient_x_r[9 : 0] != 10'b0 && gradient_y_r[9 : 0] != 10'b0))
			begin
				next_state = SOBEL_GRADIENT_3;
			end
			else
			begin
				if (point_index_r[1 : 0] == 2'd3)
				begin
					next_state = SOBEL_GRADIENT_4;
				end
				else
				begin
					next_state = SOBEL_GRADIENT_0;
				end
			end
		end
		SOBEL_GRADIENT_4:
		begin
			if (point_index_r[1 : 0] == 2'd3)
			begin
				if (current_depth_r[1 : 0] == 2'd3)
				begin
					next_state = INIT;
				end
				else
				begin
					next_state = FEATURE_LOAD;
				end
			end
			else
			begin
				next_state = SOBEL_GRADIENT_4;
			end
		end
		default: next_state = IDLE;
	endcase
end

function automatic [3 : 0] decoder_2_to_4;
	input [1 : 0] input_signal;
	begin
		decoder_2_to_4 =
		{
			(!input_signal[0] || !input_signal[1]),
			( input_signal[0] || !input_signal[1]),
			(!input_signal[0] ||  input_signal[1]),
			( input_signal[0] ||  input_signal[1])
		};
	end
endfunction

function automatic [16 : 0] conv_accumulate_1;
	input [12 : 0] buffer_map [2 : 0];
	begin
		conv_accumulate_1 =
			{4'b0, buffer_map[0]} + {3'b0, buffer_map[1], 1'b0} + {4'b0, buffer_map[2]};
	end
endfunction

function automatic [16 : 0] conv_accumulate_2;
	input [12 : 0] buffer_map [2 : 0];
	begin
		conv_accumulate_2 =
			{3'b0, buffer_map[0], 1'b0} + {2'b0, buffer_map[1], 2'b0} + {3'b0, buffer_map[2], 1'b0};
	end
endfunction

function automatic [12 : 0] rounding;
	input [16 : 0] accumulate_0;
	reg [16 : 0] accumulate_1;
	begin
		accumulate_1 = (accumulate_0[3]) ? (accumulate_0 + 17'b1000) : accumulate_0;
		rounding = accumulate_1[16 : 4];
	end
endfunction

function automatic [9 : 0] func_abs;
	input [10 : 0] gradient;
	begin
		func_abs = (gradient[10]) ? (~gradient[9 : 0] + 1) : gradient[9 : 0];
	end
endfunction

function automatic is_need_padding;
	input [1 : 0] point_index;
	input [2 : 0] point;
	input [2 : 0] point_offset;
	begin
		// point_offset = (point - 9) + ({point_index[3], 3'b0} + {point_index[2], 2'b0}) + point_index[3 : 0];
		is_need_padding = 0;
		case (point_index)
			2'b00: // 0 - 3
			begin
				if
				(
					point_offset >= point ||
					point_offset == (point - 3'd2)
				)
				begin
					is_need_padding = 1;
				end
			end
			2'b01: // 4 - 8
			begin
				if
				(
					point_offset > point ||
					point_offset == (point - 3'd1)
				)
				begin
					is_need_padding = 1;
				end
			end
			2'b10: // 8 - 11
			begin
				if
				(
					point_offset == (point + 3'd2) ||
					point_offset == point
				)
				begin
					is_need_padding = 1;
				end
			end
			2'b11: // 12 - 15
			begin
				if
				(
					point_offset == (point + 3'd3) ||
					point_offset == (point + 3'd1) ||
					point_offset < point
				)
				begin
					is_need_padding = 1;
				end
			end
		endcase
	end
endfunction

sram_512x8 u_sram_0
(
	.Q   (data_out[0]),
	.CLK (i_clk),
	.CEN (CEN[0]),
	.WEN (WEN[0]),
	.A   (data_addr_w[8 : 0]),
	.D   (i_in_data[7 : 0])
);

sram_512x8 u_sram_1
(
	.Q   (data_out[1]),
	.CLK (i_clk),
	.CEN (CEN[1]),
	.WEN (WEN[1]),
	.A   (data_addr_w[8 : 0]),
	.D   (i_in_data[7 : 0])
);

sram_512x8 u_sram_2
(
	.Q   (data_out[2]),
	.CLK (i_clk),
	.CEN (CEN[2]),
	.WEN (WEN[2]),
	.A   (data_addr_w[8 : 0]),
	.D   (i_in_data[7 : 0])
);

sram_512x8 u_sram_3
(
	.Q   (data_out[3]),
	.CLK (i_clk),
	.CEN (CEN[3]),
	.WEN (WEN[3]),
	.A   (data_addr_w[8 : 0]),
	.D   (i_in_data[7 : 0])
);

odd_even_sort u_odd_even_sort
(
	.i_clk       (i_clk),
	.i_rst_n     (i_rst_n),
	.enable      (sort_enable),
	.o_out_valid (sort_out_valid),
	.array_i     (sort_array),
	.median      (sort_median)
);

divider u_divider
(
	.i_clk       (i_clk),
	.i_rst_n     (i_rst_n),
	.enable      (div_enable),
	.o_out_valid (div_out_valid),
	.dividend    (dividend),
	.divisor     (divisor),
	.quotient    (quotient)
);

endmodule
