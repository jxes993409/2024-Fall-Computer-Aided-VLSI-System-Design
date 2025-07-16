`define FUNC_AUTOMATIC automatic

module alu #(
	parameter INST_W = 4,
	parameter INT_W  = 6,
	parameter FRAC_W = 10,
	parameter DATA_W = INT_W + FRAC_W
)(
	input                      i_clk,
	input                      i_rst_n,

	input                      i_in_valid,
	output                     o_busy,
	input         [INST_W-1:0] i_inst,
	input  signed [DATA_W-1:0] i_data_a,
	input  signed [DATA_W-1:0] i_data_b,

	output                     o_out_valid,
	output        [DATA_W-1:0] o_data
);

	// Local Parameters
	localparam SIGN_ADD = 4'b0000;
	localparam SIGN_SUB = 4'b0001;
	localparam SIGN_MUL = 4'b0010;
	localparam SOFTPLUS = 4'b0100;
	localparam XOR      = 4'b0101;
	localparam ARS      = 4'b0110; // Arithmetic Right Shift
	localparam LEFT_ROT = 4'b0111;
	localparam CNT_L0   = 4'b1000; // Count Leading Zeros
	localparam REV_M4   = 4'b1001; // Reverse Match 4
	localparam INIT     = 4'b1010; // Initial State

	localparam SIGN_ACC_1 = 4'b0011;
	localparam SIGN_ACC_2 = 4'b1011;

	localparam VECT_W    = 20;
	localparam VECT_SIZE = 16;

	// Wires and Regs
	reg [INST_W - 1: 0] current_state;
	reg [INST_W - 1: 0] next_state;

	reg                        o_busy_r;
	reg                        o_out_valid_r;
	reg        [DATA_W - 1: 0] o_data_r;

	wire                       o_busy_w;
	reg                        o_out_valid_w;
	reg        [DATA_W - 1: 0] o_data_w;

	reg signed [VECT_W - 1: 0] data_acc_old [VECT_SIZE - 1: 0];
	reg signed [VECT_W - 1: 0] data_acc_new [VECT_SIZE - 1: 0];
	reg signed [VECT_W - 1: 0] data_acc_out;

	reg signed [DATA_W - 1: 0] i_data_a_r;
	reg signed [DATA_W - 1: 0] i_data_b_r;

	reg need_saturate;

	integer i;

	// Continuous Assignments
	assign o_busy       = o_busy_r;
	assign o_out_valid  = o_out_valid_r;
	assign o_data       = o_data_r;
	assign o_busy_w     = i_in_valid || current_state != INIT;

	// Combinationa Blocks
	always @ (*)
	begin
		begin
			case (current_state)
				SIGN_ADD:
				begin
					o_out_valid_w = 1;
					o_data_w      = add(i_data_a_r, i_data_b_r);
				end
				SIGN_SUB:
				begin
					o_out_valid_w = 1;
					o_data_w      = sub(i_data_a_r, i_data_b_r);
				end
				SIGN_MUL:
				begin
					o_out_valid_w = 1;
					o_data_w      = mul(i_data_a_r, i_data_b_r);
				end
				SIGN_ACC_1:
				begin
					o_out_valid_w = 0;
					o_data_w      = 0;
				end
				SIGN_ACC_2:
				begin
					data_acc_out = data_acc_new[i_data_a_r[$clog2(VECT_SIZE) - 1: 0]];
					// need_saturate = data_acc_out < -'sd32768 ||
					// 				   data_acc_out > 'sd32767;
					if (data_acc_out[VECT_W - 1])
					begin
						need_saturate = (data_acc_out[(VECT_W - 1) - 1-: (VECT_W - DATA_W)] != {{(VECT_W - DATA_W){1'b1}}});
					end
					else
					begin
						need_saturate = (data_acc_out[(VECT_W - 1) - 1-: (VECT_W - DATA_W)] != {{(VECT_W - DATA_W){1'b0}}});
					end
					o_out_valid_w = 1;
					o_data_w      = (need_saturate) ?
										sat(data_acc_out[VECT_W - 1]) :
										data_acc_out[DATA_W - 1: 0];
				end
				SOFTPLUS:
				begin
					o_out_valid_w = 1;
					o_data_w      = softplus(i_data_a_r);
				end
				XOR:
				begin
					o_out_valid_w = 1;
					o_data_w      = exor(i_data_a_r, i_data_b_r);
				end
				ARS:
				begin
					o_out_valid_w = 1;
					o_data_w      = ars(i_data_a_r, i_data_b_r);
				end
				LEFT_ROT:
				begin
					o_out_valid_w = 1;
					o_data_w      = left_rot(i_data_a_r, i_data_b_r);
				end
				CNT_L0:
				begin
					o_out_valid_w = 1;
					o_data_w      = cnt_l0(i_data_a_r);
				end
				REV_M4:
				begin
					o_out_valid_w = 1;
					o_data_w      = rev_m4(i_data_a_r, i_data_b_r);
				end
				default:
				begin
					o_out_valid_w = 0;
					o_data_w      = 0;
				end
			endcase
		end
	end

	// Sequential Blocks
	// i_data
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			i_data_a_r <= 0;
			i_data_b_r <= 0;
		end
		else
		begin
			if (i_in_valid)
			begin
				i_data_a_r <= i_data_a;
				i_data_b_r <= i_data_b;
			end
			else
			begin
				i_data_a_r <= i_data_a_r;
				i_data_b_r <= i_data_b_r;
			end
		end
	end
	// o_busy
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			o_busy_r <= 1;
		end
		else
		begin
			o_busy_r <= o_busy_w;
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
	// data_acc_new
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			for (i = 0; i < VECT_SIZE; i = i + 1)
			begin
				data_acc_new[i] <= 0;
			end
		end
		else
		begin
			for (i = 0; i < VECT_SIZE; i = i + 1)
			begin
				if (current_state == SIGN_ACC_1 && i == i_data_a_r)
				begin
					data_acc_new[i] <= data_acc_old[i] + i_data_b_r;
				end
				else
				begin
					data_acc_new[i] <= data_acc_new[i];
				end
			end
		end
	end
	// data_acc_old
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			for (i = 0; i < VECT_SIZE; i = i + 1)
			begin
				data_acc_old[i] <= 0;
			end
		end
		else if (current_state == SIGN_ACC_2)
		begin
			for (i = 0; i < VECT_SIZE; i = i + 1)
			begin
				data_acc_old[i] <= data_acc_new[i];
			end
		end
	end
	// Finite State Machine
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
	// NL
	always @ (*)
	begin
		case (current_state)
			INIT:
			begin
				if (i_in_valid)
				begin
					case (i_inst)
						SIGN_ADD:   next_state = SIGN_ADD;   // 4'b0000
						SIGN_SUB:   next_state = SIGN_SUB;   // 4'b0001
						SIGN_MUL:   next_state = SIGN_MUL;   // 4'b0010
						SIGN_ACC_1: next_state = SIGN_ACC_1; // 4'b0011
						SOFTPLUS:   next_state = SOFTPLUS;   // 4'b0100
						XOR:        next_state = XOR;        // 4'b0101
						ARS:        next_state = ARS;        // 4'b0110
						LEFT_ROT:   next_state = LEFT_ROT;   // 4'b0111
						CNT_L0:     next_state = CNT_L0;     // 4'b1000
						REV_M4:     next_state = REV_M4;     // 4'b1001
						default:    next_state = INIT;       // 4'b1010
					endcase
				end
				else
				begin
					next_state = INIT;
				end
			end
			SIGN_ACC_1:
			begin
				next_state = SIGN_ACC_2;
			end
			default:  next_state = INIT;
		endcase
	end
	// OL
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			o_data_r <= 0;
		end
		else
		begin
			o_data_r <= o_data_w;
		end
	end

	// Functions
	// ADD
	function automatic signed [DATA_W - 1: 0] add;
		input signed [DATA_W - 1: 0] a;
		input signed [DATA_W - 1: 0] b;
		reg signed [DATA_W - 1: 0] sum;
		reg                        is_overflow;
		begin
			sum = a + b;
			is_overflow = (a[DATA_W - 1] & b[DATA_W - 1] & ~sum[DATA_W - 1]) || (~a[DATA_W - 1] & ~b[DATA_W - 1] & sum[DATA_W - 1]);
			add = (is_overflow) ? sat(!sum[DATA_W - 1]) : sum;
		end
	endfunction
	// SUB
	function automatic signed [DATA_W - 1: 0] sub;
		input signed [DATA_W - 1: 0] a;
		input signed [DATA_W - 1: 0] b;
		reg signed [DATA_W - 1: 0] diff;
		reg                        is_overflow;
		begin
			diff = a - b;
			is_overflow = (a[DATA_W - 1] & ~b[DATA_W - 1] & ~diff[DATA_W - 1]) || (~a[DATA_W - 1] & b[DATA_W - 1] & diff[DATA_W - 1]);
			sub = (is_overflow) ? sat(!diff[DATA_W - 1]) : diff;
		end
	endfunction
	// MUL
	function automatic signed [DATA_W - 1: 0] mul;
		input signed [DATA_W - 1: 0] a;
		input signed [DATA_W - 1: 0] b;
		reg [2 * DATA_W: 0] prod;
		reg                 is_overflow;
		reg                 is_signed;
		begin
			prod = a * b;
			prod = rnd(prod, 9);
			is_signed = prod[2 * DATA_W];
			if (is_signed)
			begin
				is_overflow = (prod[(2 * DATA_W) - 1-: INT_W + 1] != {{(INT_W + 1){1'b1}}});
			end
			else
			begin
				is_overflow = (prod[(2 * DATA_W) - 1-: INT_W + 1] != {{(INT_W + 1){1'b0}}});
			end
			mul = prod[((2 * DATA_W) - INT_W - 1)-: DATA_W];
			mul = (is_overflow) ? sat(is_signed) : mul;
		end
	endfunction
	// SOFTPLUS
	function automatic signed [DATA_W - 1: 0] softplus;
		input signed [DATA_W - 1: 0] a;
		reg signed [2 * DATA_W: 0] frac;
		reg signed  [INT_W - 1: 0] a_int;
		begin
			a_int = a[(DATA_W - 1)-: INT_W];
			if (a_int >= 'sd2) // x >= 2
			begin
				softplus = a;
			end
			else if (a_int < 'sd2 && a_int >= 'sd0) // 0 <= x < 2
			begin
				// (2x + 2) / 3
				frac = a << 1;
				frac = frac + 12'b1000_0000_0000;
				frac = frac[DATA_W - 1: 0] * 16'hAAAB;
				frac = rnd(frac, 16);
				frac = frac >> 17;
				softplus = frac[DATA_W - 1: 0];
			end
			else if (a_int < 'sd0 && a_int >= -'sd1) // -1 <= x < 0
			begin
				// (x + 2) / 3
				frac = a + 12'b1000_0000_0000;
				frac = frac[DATA_W - 1: 0] * 16'hAAAB;
				frac = rnd(frac, 16);
				frac = frac >> 17;
				softplus = frac[DATA_W - 1: 0];
			end
			else if (a_int < -'sd1 && a_int >= -'sd2) // -2 <= x < -1
			begin
				// (2x + 5) / 9
				frac = a << 1;
				frac = frac[DATA_W - 1: 0] + 14'b01_0100_0000_0000;
				frac = frac[DATA_W - 1: 0] * 16'hE38F;
				frac = rnd(frac, 18);
				frac = frac >> 19;
				softplus = frac[DATA_W - 1: 0];
			end
			else if (a_int < -'sd2 && a_int >= -'sd3) // -3 <= x < -2
			begin
				// (x + 3) / 9
				frac = a + 12'b1100_0000_0000;
				frac = frac[DATA_W - 1: 0] * 16'hE38F;
				frac = rnd(frac, 18);
				frac = frac >> 19;
				softplus = frac[DATA_W - 1: 0];
			end
			else // x < -3
			begin
				softplus = 0;
			end
		end
	endfunction
	// XOR
	function automatic signed [DATA_W - 1: 0] exor;
		input signed [DATA_W - 1: 0] a;
		input signed [DATA_W - 1: 0] b;
		begin
			exor = a ^ b;
		end
	endfunction
	// ARITHMETIC RIGHT SHIFT
	function automatic signed [DATA_W - 1: 0] ars;
		input signed [DATA_W - 1: 0] a;
		input signed [DATA_W - 1: 0] b;
		begin
			ars = a >>> b;
		end
	endfunction
	// LEFT ROTATION
	function automatic [DATA_W - 1: 0] left_rot;
		input [DATA_W - 1: 0] a;
		input [DATA_W - 1: 0] b;
		begin
			left_rot = (a << b) | (a >> (DATA_W - b));
		end
	endfunction
	// COUNT LEADING ZEROS
	function automatic [DATA_W - 1: 0] cnt_l0;
		input [DATA_W - 1: 0] a;
		reg [$clog2(DATA_W): 0] leading_one;
		integer i;
		begin
			if (a == 0)
			begin
				cnt_l0 = DATA_W;
			end
			else
			begin
				leading_one = 0;
				for (i = DATA_W - 1; i > 0; i = i - 1)
				begin
					if (a[i] && i > leading_one)
					begin
						leading_one = i;
					end
				end
				cnt_l0 = DATA_W - 1 - leading_one;
			end
		end
	endfunction
	// REVERSE MATCH 4
	function automatic [DATA_W - 1: 0] rev_m4;
		input [DATA_W - 1: 0] a;
		input [DATA_W - 1: 0] b;
		integer i;
		begin
			for (i = 0; i < 13; i = i + 1)
			begin
				rev_m4[i] = (a[i+: 4] == b[(DATA_W - 1 - i)-: 4]);
			end
			rev_m4[DATA_W - 1-: 3] = 0;
		end
	endfunction
	// SATURATION
	function automatic signed [DATA_W - 1: 0] sat;
		input is_signed;
		begin
			sat = (is_signed) ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
		end
	endfunction
	// ROUNDING
	function automatic signed [2 * DATA_W: 0] rnd;
		input signed [2 * DATA_W: 0] a;
		input    [$clog2(DATA_W): 0] rounding_bit;
		begin
			rnd = (a[rounding_bit]) ? a + (1'b1 << rounding_bit) : a;
		end
	endfunction
endmodule
