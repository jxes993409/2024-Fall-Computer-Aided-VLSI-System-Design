module divider(
	input i_clk,
	input i_rst_n,
	input enable,
	output o_out_valid,
	input [9 : 0] dividend,
	input [9 : 0] divisor,
	output [16 : 0] quotient
);

localparam IDLE = 1'd0;
localparam  DIV = 1'd1;

reg [4 : 0] bit_r;
reg [4 : 0] bit_w;

reg [27 : 0] dividend_r;
reg [27 : 0] dividend_w;

reg [27 : 0] dividend_temp;

reg [9 : 0] divisor_r;
reg [9 : 0] divisor_w;

reg [16 : 0] quotient_r;
reg [16 : 0] quotient_w;

reg current_state;
reg next_state;

reg [3 : 0] divisor_bits;
reg o_out_valid_w;

assign o_out_valid = o_out_valid_w;
assign quotient = (o_out_valid_w) ? quotient_w : 0;

always @ (*)
begin

	dividend_w = dividend_r;
	divisor_w = divisor_r;
	quotient_w = quotient_r;
	bit_w = bit_r;

	dividend_temp = 0;
	o_out_valid_w = 0;

	divisor_bits = 0;

	case (current_state)
		IDLE:
		begin
			if (!enable)
			begin
				divisor_bits = find_leading_one(divisor);
				dividend_w = (({dividend, 7'b0}) << (divisor_bits));
				divisor_w = divisor;
				quotient_w = 0;
				bit_w = 16 - divisor_bits;
			end
			else
			begin
				dividend_w = 0;
				divisor_w = 0;
				quotient_w = 0;
				bit_w = 0;
			end
		end
		DIV:
		begin
			quotient_w = quotient_r << 1;
			dividend_temp = dividend_r << 1;
			if (dividend_temp[27 : 17] >= {1'b0, divisor_w})
			begin
				dividend_w[27 : 17] = dividend_temp[27 : 17] - divisor_w;
				dividend_w[16 : 0] = dividend_temp[16 : 0];
				quotient_w[0] = 1;
			end
			else
			begin
				dividend_w = dividend_temp;
			end
			
			if (bit_r == 0)
			begin
				o_out_valid_w = 1;
			end
			else
			begin
				bit_w = bit_r - 1;
			end
		end
	endcase
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		dividend_r <= 0;
	end
	else
	begin
		dividend_r <= dividend_w;
	end
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		divisor_r <= 0;
	end
	else
	begin
		divisor_r <= divisor_w;
	end
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		bit_r <= 0;
	end
	else
	begin
		bit_r <= bit_w;
	end
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		quotient_r <= 0;
	end
	else
	begin
		quotient_r <= quotient_w;
	end
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		current_state <= IDLE;
	end
	else
	begin
		current_state <= next_state;
	end
end

always @ (*)
begin
	case (current_state)
		IDLE:
		begin
			if (!enable)
			begin
				next_state = DIV;
			end
			else
			begin
				next_state = IDLE;
			end
		end
		DIV:
		begin
			if (bit_r == 5'd0)
			begin
				next_state = IDLE;
			end
			else
			begin
				next_state = DIV;
			end
		end
	endcase
end

function automatic [3 : 0] find_leading_one;
	input [9 : 0] dividend;
	reg [3 : 0] leading_one;
	integer i;
	begin
		leading_one = 0;
		for (i = 0; i < 10; i = i + 1)
		begin
			if (dividend[i] && i > leading_one)
			begin
				leading_one = i;
			end
		end
		find_leading_one = leading_one;
	end
endfunction

endmodule
