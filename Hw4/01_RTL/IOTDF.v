`timescale 1ns/10ps
`define FUNC_AUTOMATIC automatic
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

localparam      INIT = 3'd0;
localparam      IDLE = 3'd1;
localparam READ_DATA = 3'd2;
localparam MOVE_DATA = 3'd3;
localparam  WAIT_OUT = 3'd4;

reg [2 : 0] current_state;
reg [2 : 0] next_state;

reg [5 : 0] data_index_w;
reg [5 : 0] data_index_r;

reg [5 : 0] valid_index_w;
reg [5 : 0] valid_index_r;

reg [3 : 0] data_byte_w;
reg [3 : 0] data_byte_r;

reg [7 : 0] iot_data_w [15 : 0];
reg [7 : 0] iot_data_r [15 : 0];

// reg [127 : 0] share_iot_data_w;
// reg [127 : 0] share_iot_data_r;

// reg [7 : 0] iot_in_w;
// reg [7 : 0] iot_in_r;

reg busy_w;
reg busy_r;

reg valid_w;
reg valid_r;

reg [127 : 0] iot_out_w;
reg [127 : 0] iot_out_r;

wire DES_valid;
wire [127 : 0] DES_iot_out;
wire DES_clk;
reg DES_enable;

wire MAXMIN_valid;
wire [127 : 0] MAXMIN_iot_out;
wire MAXMIN_clk;
reg MAXMIN_enable;
reg MAXMIN_new_data;

wire CRC_valid;
wire [2 : 0] CRC_iot_out;
reg CRC_enable;

reg [3 : 0] index;
integer i;

assign busy = busy_r;
assign valid = valid_w;
assign iot_out = iot_out_w;

// assign DES_clk = (clk && (fn_sel == 3'd1 || fn_sel == 3'd2));
// assign MAXMIN_clk = (clk && (fn_sel == 3'd4 || fn_sel == 3'd5));

always @ (*)
begin
	data_index_w = data_index_r;
	if (current_state == MOVE_DATA)
	begin
		if (data_index_r < 6'd63)
		begin
			data_index_w = data_index_r + 1;
		end
	end
end

// always @ (*)
// begin
// 	iot_in_w = 0;
// 	if (in_en)
// 	begin
// 		iot_in_w = iot_in;
// 	end
// end

always @ (*)
begin
	valid_index_w = valid_index_r;
	case (fn_sel)
		3'd1, 3'd2:
		begin
			if (DES_valid)
			begin
				valid_index_w = valid_index_r + 1;
			end
		end
		3'd3:
		begin
			if (CRC_valid)
			begin
				valid_index_w = valid_index_r + 1;
			end
		end
		3'd4, 3'd5:
		begin
			if (MAXMIN_valid)
			begin
				valid_index_w = valid_index_r + 1;
			end
		end
	endcase
end

always @ (*)
begin
	MAXMIN_enable = 0;
    MAXMIN_new_data = 0;

	if (fn_sel == 3'd4 || fn_sel == 3'd5)
	begin
		case (current_state)
            READ_DATA:
            begin
                if (data_index_r[2 : 0] != 3'd0)
                begin
                    MAXMIN_enable = 1;
                end
                else if (data_byte_r == 4'd15)
                begin
                    MAXMIN_enable = 1;
                end
            end
			MOVE_DATA:
			begin
                MAXMIN_enable = 1;
				MAXMIN_new_data = 1;
			end
		endcase
	end
end

always @ (*)
begin
	CRC_enable = 0;

	if (fn_sel == 3'd3)
	begin
		case (current_state)
			READ_DATA:
			begin
				// if (data_byte_r != 6'd0)
				// begin
				CRC_enable = in_en;
				// end
			end
		endcase
	end
end

always @ (*)
begin
	DES_enable = 0;

	if (fn_sel == 3'd1 || fn_sel == 3'd2)
	begin
		case (current_state)
			READ_DATA:
			begin
				if (data_index_r != 6'd0)
				begin
					DES_enable = 1;
				end
			end
			MOVE_DATA:
			begin
				DES_enable = 1;
			end
			WAIT_OUT:
			begin
				DES_enable = 1;
			end
		endcase
	end
end

// data_byte
always @ (*)
begin
	data_byte_w = data_byte_r;

	case (current_state)
		READ_DATA:
		begin
			if (in_en)
			begin
				data_byte_w = data_byte_r + 1;
			end
		end
		WAIT_OUT, MOVE_DATA:
		begin
			data_byte_w = 0;
		end
	endcase
end

// busy
always @ (*)
begin
	busy_w = 1;

	case (current_state)
		IDLE:
		begin
			busy_w = 0;
		end
		READ_DATA:
		begin
			if (data_byte_r > 5'd13)
			begin
				busy_w = 1;
			end
			else
			begin
				busy_w = 0;
			end
		end
		MOVE_DATA:
		begin
			busy_w = 0;
		end
		WAIT_OUT:
		begin
			if (fn_sel > 5'd2)
			begin
				busy_w = 0;
			end
		end
	endcase
end

always @ (*)
begin
	for (i = 0; i < 16; i = i + 1)
	begin
		iot_data_w[i] = iot_data_r[i];
	end
	index = 0;
	case (current_state)
		IDLE:
		begin
			for (i = 0; i < 16; i = i + 1)
			begin
				iot_data_w[i] = 0;
			end
		end
		READ_DATA:
		begin
			// index = (data_byte_r - 1);
			
			iot_data_w[data_byte_r] = iot_in;
			
		end
		MOVE_DATA:
		begin
			for (i = 0; i < 16; i = i + 1)
			begin
				iot_data_w[i] = 0;
			end
		end
	endcase
end

// iot_in
// always @ (posedge clk or posedge rst)
// begin
// 	if (rst)
// 	begin
// 		iot_in_r <= 0;
// 	end
// 	else
// 	begin
// 		iot_in_r <= iot_in_w;
// 	end
// end

// iot_data
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		for (i = 0; i < 16; i = i + 1)
		begin
			iot_data_r[i] <= 0;
		end
		// iot_data_r <= 0;
	end
	else
	begin
		for (i = 0; i < 16; i = i + 1)
		begin
			iot_data_r[i] <= iot_data_w[i];
		end
		// iot_data_r <= iot_data_w;
	end
end

// data_byte
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		data_byte_r <= 0;
	end
	else
	begin
		data_byte_r <= data_byte_w;
	end
end

// data_index
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		data_index_r <= 0;
	end
	else
	begin
		data_index_r <= data_index_w;
	end
end

// valid_index
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		valid_index_r <= 0;
	end
	else
	begin
		valid_index_r <= valid_index_w;
	end
end

// busy
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		busy_r <= 1;
	end
	else
	begin
		busy_r <= busy_w;
	end
end

// iot_out
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		iot_out_r <= 0;
	end
	else
	begin
		iot_out_r <= iot_out_w;
	end
end

// valid
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		valid_r <= 0;
	end
	else
	begin
		valid_r <= valid_w;
	end
end

// cs
always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		current_state <= INIT;
	end
	else
	begin
		current_state <= next_state;
	end
end

// ns
always @ (*)
begin
	case (current_state)
		INIT: next_state = IDLE;
		IDLE:
		begin
			if (data_index_r == 6'd63)
			begin
				next_state = IDLE;
			end
			else
			begin
				next_state = READ_DATA;
			end
		end
		READ_DATA:
		begin
			if (data_byte_r == 4'd15)
			begin
				case (fn_sel)
					3'd1, 3'd2:
					begin
						next_state = MOVE_DATA;
						// if (data_index_r == 6'd0)
						// begin
						// end
						// else
						// begin
						// 	next_state = WAIT_OUT;
						// end
					end
					3'd3:
					begin
						next_state = WAIT_OUT;
					end
					3'd4, 3'd5:
					begin
						next_state = MOVE_DATA;
					end
					default: next_state = INIT;
				endcase
			end
			else
			begin
				next_state = READ_DATA;
			end
		end
		MOVE_DATA:
		begin
			if (data_index_r == 6'd63)
			begin
				next_state = WAIT_OUT;
			end
			else
			begin
				next_state = READ_DATA;
			end
		end
		WAIT_OUT:
		begin
			if (valid_w)
			begin
				case (fn_sel)
					3'd1, 3'd2:
					begin
						if (valid_index_r == 6'd63)
						begin
							next_state = IDLE;
						end
						else
						begin
							next_state = MOVE_DATA;
						end
					end
					3'd3:
					begin
						if (valid_index_r == 6'd63)
						begin
							next_state = IDLE;
						end
						else
						begin
							next_state = READ_DATA;
						end
					end
					3'd4, 3'd5:
					begin
						if (!valid_index_r[0])
						begin
							next_state = WAIT_OUT;
						end
						else
						begin
							next_state = IDLE;
						end
					end
					default next_state = IDLE;
				endcase
			end
			else
			begin
				next_state = WAIT_OUT;
			end
		end
		default: next_state = INIT;
	endcase
end

// ol
always @ (*)
begin
	iot_out_w = 0;
	valid_w = 0;
	
	case (fn_sel)
		3'd1, 3'd2:
		begin
			iot_out_w = DES_iot_out;
			valid_w = DES_valid;
		end
		3'd3:
		begin
			iot_out_w = {{125{1'b0}}, CRC_iot_out};
			valid_w = CRC_valid;
		end
		3'd4, 3'd5:
		begin
			iot_out_w = MAXMIN_iot_out;
			valid_w = MAXMIN_valid;
		end
	endcase
end

DES u_DES
(
	.clk     (clk),
	.rst     (rst),
	.enable  (DES_enable),
	.mode    (fn_sel[0]),
	.valid   (DES_valid),
	// .iot_in  (DES_iot_in),
	.iot_out (DES_iot_out),
	.iot_in
	({
		iot_data_r[15], iot_data_r[14], iot_data_r[13], iot_data_r[12], iot_data_r[11], iot_data_r[10], iot_data_r[ 9], iot_data_r[ 8],
		iot_data_r[ 7], iot_data_r[ 6], iot_data_r[ 5], iot_data_r[ 4], iot_data_r[ 3], iot_data_r[ 2], iot_data_r[ 1], iot_data_r[ 0]
	})
);

MAXMIN u_MAXMIN
(
	.clk      (clk),
	.rst      (rst),
	.enable   (MAXMIN_enable),
    .new_data (MAXMIN_new_data),
	.mode     (fn_sel[0]),
	.valid    (MAXMIN_valid),
	.iot_out  (MAXMIN_iot_out),
	.iot_in
	({
		iot_data_r[15], iot_data_r[14], iot_data_r[13], iot_data_r[12], iot_data_r[11], iot_data_r[10], iot_data_r[ 9], iot_data_r[ 8],
		iot_data_r[ 7], iot_data_r[ 6], iot_data_r[ 5], iot_data_r[ 4], iot_data_r[ 3], iot_data_r[ 2], iot_data_r[ 1], iot_data_r[ 0]
	})
);

CRC u_CRC
(
	.clk     (clk),
	.rst     (rst),
	.enable  (CRC_enable),
	.iot_in  (iot_in),
	.valid   (CRC_valid),
	.iot_out (CRC_iot_out)
);
endmodule
