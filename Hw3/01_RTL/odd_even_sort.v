module odd_even_sort (
	input i_clk,
	input i_rst_n,
	input enable,
	output o_out_valid,
	input  [7 : 0] array_i [8 : 0],
	output [7 : 0] median
);

localparam IDLE = 2'd0;
localparam ODD_EVEN = 2'd1;
localparam EVEN_ODD = 2'd2;
// localparam OUTPUT = 2'd3;

reg [7 : 0] array_w [8 : 0];
reg [7 : 0] array_r [8 : 0];

reg [7 : 0] median_w;

reg [1 : 0] current_state;
reg [1 : 0] next_state;

reg [2 : 0] counter_w;
reg [2 : 0] counter_r;

reg o_out_valid_w;

integer i;

assign median = median_w;
assign o_out_valid = o_out_valid_w;

always @ (*)
begin
	for (i = 0; i < 9; i = i + 1)
	begin
		array_w[i] = array_r[i];
	end
	counter_w = counter_r;
	o_out_valid_w = 0;
	median_w = 0;

	case (current_state)
		IDLE:
		begin
			for (i = 0; i < 9; i = i + 1)
			begin
				if (!enable)
				begin
					array_w[i] = array_i[i];
				end
				else
				begin
					array_w[i] = 0;
				end
			end
			counter_w = 0;
		end
		ODD_EVEN:
		begin
			for (i = 1; i < 8; i = i + 2)
			begin
				if (array_r[i] > array_r[i + 1])
				begin
					{array_w[i], array_w[i + 1]} = {array_r[i + 1], array_r[i]};
				end
			end
			counter_w = counter_r + 1;
			if (counter_r == 3'd4)
			begin
				o_out_valid_w = 1;
				median_w = array_w[4];
			end
		end
		EVEN_ODD:
		begin
			for (i = 0; i < 8; i = i + 2)
			begin
				if (array_r[i] > array_r[i + 1])
				begin
					{array_w[i], array_w[i + 1]} = {array_r[i + 1], array_r[i]};
				end
			end
		end
		// OUTPUT:
		// begin
		// 	o_out_valid_w = 1;
		// 	median_w = array_w[4];
		// end
	endcase
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		for (i = 0; i < 9; i = i + 1)
		begin
			array_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 9; i = i + 1)
		begin
			array_r[i] <= array_w[i];
		end
	end
end

always @ (posedge i_clk or negedge i_rst_n)
begin
	if (!i_rst_n)
	begin
		counter_r <= 0;
	end
	else
	begin
		counter_r <= counter_w;
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
				next_state = ODD_EVEN;
			end
			else
			begin
				next_state = IDLE;
			end
		end
		ODD_EVEN:
		begin
			// counter_r < 3'd4
			if (!counter_r[2])
			begin
				next_state = EVEN_ODD;
			end
			else
			begin
				next_state = IDLE;
			end
		end
		EVEN_ODD: next_state = ODD_EVEN;
		// OUTPUT:   next_state = IDLE;
		default:  next_state = IDLE;
	endcase
end

endmodule