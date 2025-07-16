`timescale 1ns/100ps
module CRC
(
	input clk,
	input rst,
	input enable,
	output valid,
	input  [7 : 0] iot_in,
	output [2 : 0] iot_out
);

// localparam   IDLE = 2'd0;
// localparam CRC_OP = 2'd1;
// localparam OUTPUT = 2'd2;

// reg [1 : 0] current_state;
// reg [1 : 0] next_state;

reg valid_w;
reg [2 : 0] iot_out_w;

reg [2 : 0] crc_w;
reg [2 : 0] crc_r;

reg [4 : 0] counter_w;
reg [4 : 0] counter_r;

integer i;

assign iot_out = iot_out_w;
assign valid = valid_w;

// 		parallel_out[1] =
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0];
// ;
// 		parallel_out[2] =
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^ 
// iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1] ^ 
// iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0] ^ 
// iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0] ^

always @ (*)
begin
	crc_w = crc_r;
	if (enable)
	begin
		case (counter_r)
			5'd0, 5'd3, 5'd6, 5'd09, 5'd12, 5'd15:
			begin
				crc_w[1] = crc_r[1] ^ iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0];
				crc_w[2] = crc_r[2] ^ iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0];
			end
			5'd1, 5'd4, 5'd7, 5'd10, 5'd13:
			begin
				crc_w[1] = crc_r[1] ^ iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1];
				crc_w[2] = crc_r[2] ^ iot_in[7] ^ iot_in[6] ^ iot_in[4] ^ iot_in[3] ^ iot_in[1] ^ iot_in[0];
			end
			5'd2, 5'd5, 5'd8, 5'd11, 5'd14:
			begin
				crc_w[1] = crc_r[1] ^ iot_in[6] ^ iot_in[5] ^ iot_in[3] ^ iot_in[2] ^ iot_in[0];
				crc_w[2] = crc_r[2] ^ iot_in[7] ^ iot_in[5] ^ iot_in[4] ^ iot_in[2] ^ iot_in[1];
			end
		endcase
	end
	else
	begin
		crc_w = 0;
	end
	// case (current_state)
	// 	CRC_OP:
	// 	begin
			
	// 	end
	// 	OUTPUT:
	// 	begin
	// 		crc_w = 0;
	// 	end
	// endcase
end

always @ (*)
begin
	counter_w = counter_r;
	if (enable)
	begin
		counter_w = counter_r + 1;
	end
	else
	begin
		counter_w = 0;
	end
	// case (current_state)
	// 	CRC_OP:
	// 	begin
	// 		if (enable)
	// 		begin
	// 			counter_w = counter_r + 1;
	// 		end
	// 	end
	// 	OUTPUT:
	// 	begin
	// 		counter_w = 0;
	// 	end
	// endcase
end

always @ (posedge clk or posedge rst)
begin
	if (rst)
	begin
		crc_r <= 0;
	end
	else
	begin
		crc_r <= crc_w;
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

// always @ (posedge clk or posedge rst)
// begin
// 	if (rst)
// 	begin
// 		current_state <= IDLE;
// 	end
// 	else
// 	begin
// 		current_state <= next_state;
// 	end
// end

// always @ (*)
// begin
// 	case (current_state)
// 		IDLE:
// 		begin
// 			if (enable)
// 			begin
// 				next_state = CRC_OP;
// 			end
// 			else
// 			begin
// 				next_state = IDLE;
// 			end
// 		end
// 		CRC_OP:
// 		begin
// 			if (counter_r == 4'd15)
// 			begin
// 				next_state = OUTPUT;
// 			end
// 			else
// 			begin
// 				next_state = CRC_OP;
// 			end
// 		end
// 		OUTPUT: next_state = IDLE;
// 		default: next_state = IDLE;
// 	endcase
// end

always @ (*)
begin
	iot_out_w = 0;
	valid_w = 0;
	if (counter_r == 5'd16)
	begin
		iot_out_w = crc_r;
		valid_w = 1;
	end
end

endmodule