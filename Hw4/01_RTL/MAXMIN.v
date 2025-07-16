module MAXMIN
(
	input clk,
	input rst,
	input enable,
	input new_data,
	input mode,
	output valid,
	input  [127 : 0] iot_in,
	output [127 : 0] iot_out
);

localparam      IDLE = 3'd0;
localparam      CMP1 = 3'd1;
localparam      CMP2 = 3'd2;
localparam WAIT_DATA = 3'd3;
localparam    OUTPUT = 3'd4;

reg valid_w;
reg [127 : 0] iot_out_w;

reg [2 : 0] current_state;
reg [2 : 0] next_state;

reg [2 : 0] counter_w;
reg [2 : 0] counter_r;

reg [127 : 0] iot_data_w [1 : 0];
reg [127 : 0] iot_data_r [1 : 0];

reg [127 : 0] iot_in_w;
reg [127 : 0] iot_in_r;

reg is_need_CMP2;

integer i;

assign valid = valid_w;
assign iot_out = iot_out_w;

always @ (*)
begin
	for (i = 0; i < 2; i = i + 1)
	begin
		iot_data_w[i] = iot_data_r[i];
	end

	is_need_CMP2 = 1;

	case (current_state)
		IDLE:
		begin
			for (i = 0; i < 2; i = i + 1)
			begin
				iot_data_w[i] = {128{mode}};
			end
		end
		CMP1:
		begin
			if (mode)
			begin
				if (iot_in_r < iot_data_r[0])
				begin
					is_need_CMP2 = 0;
					iot_data_w = '{iot_data_r[0], iot_in_r};
				end
			end
			else
			begin
				if (iot_in_r > iot_data_r[0])
				begin
					is_need_CMP2 = 0;
					iot_data_w = '{iot_data_r[0], iot_in_r};
				end
			end
		end
		CMP2:
		begin
			if (mode)
			begin
				if (iot_in_r < iot_data_r[1])
				begin
					iot_data_w[1] = iot_in_r;
				end
			end
			else
			begin
				if (iot_in_r >  iot_data_r[1])
				begin
					iot_data_w[1] = iot_in_r;
				end
			end
		end
	endcase
end

always @ (*)
begin
	counter_w = counter_r;
	case (current_state)
		CMP1:
		begin
			if (!is_need_CMP2)
			begin
				counter_w = counter_r + 1;
			end
		end
		CMP2:
		begin
			counter_w = counter_r + 1;
		end
		OUTPUT:
		begin
			if (counter_r == 3'd1)
			begin
				counter_w = 0;
			end
			else
			begin
				counter_w = counter_r + 1;
			end
		end
	endcase
end

always @ (*)
begin
	iot_in_w = iot_in_r;

	if (current_state == WAIT_DATA)
	begin
		if (new_data)
		begin
			iot_in_w = iot_in;
		end
	end
end

always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		counter_r <= 0;
	end
	else
	begin
		counter_r <= counter_w;
	end
end

always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		for (i = 0; i < 2; i = i + 1)
		begin
			iot_data_r[i] <= 0;
		end
	end
	else
	begin
		for (i = 0; i < 2; i = i + 1)
		begin
			iot_data_r[i] <= iot_data_w[i];
		end
	end
end

always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		iot_in_r <= 0;
	end
	else
	begin
		iot_in_r <= iot_in_w;
	end
end

always @ (posedge clk or posedge rst)
begin
	if (rst)
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
			if (enable)
			begin
				next_state = WAIT_DATA;
			end
			else
			begin
				next_state = IDLE;
			end
		end
		WAIT_DATA:
		begin
			if (new_data)
			begin
				next_state = CMP1;
			end
			else
			begin
				next_state = WAIT_DATA;
			end
		end
		CMP1:
		begin
			if (is_need_CMP2)
			begin
				next_state = CMP2;
			end
			else
			begin
				if (counter_r == 3'd7)
				begin
					next_state = OUTPUT;
				end
				else
				begin
					next_state = WAIT_DATA;
				end
			end
		end
		CMP2:
		begin
			if (counter_r == 3'd7)
			begin
				next_state = OUTPUT;
			end
			else
			begin
				next_state = WAIT_DATA;
			end
		end
		OUTPUT:
		begin
			if (counter_r == 3'd1)
			begin
				next_state = IDLE;
			end
			else
			begin
				next_state = OUTPUT;
			end
		end
		default: next_state = IDLE;
	endcase
end

always @ (*)
begin
	valid_w = 0;
	iot_out_w = 0;
	if (current_state == OUTPUT)
	begin
		iot_out_w = iot_data_r[counter_r[0]];
		valid_w = 1;
	end
end
endmodule