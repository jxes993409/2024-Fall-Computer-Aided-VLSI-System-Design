module DES
(
	input clk,
	input rst,
	input enable,
	input mode,
	output valid,
	input  [127 : 0] iot_in,
	output [127 : 0] iot_out
);

localparam        IDLE = 2'd0;
localparam     ENCRYPT = 2'd1;
localparam     DECRYPT = 2'd2;
// localparam FINAL_PERMU = 2'd3;
localparam      OUTPUT = 2'd3;

reg [1 : 0] current_state;
reg [1 : 0] next_state;

reg [127 : 0] iot_data_w;
reg [127 : 0] iot_data_r;

reg [3 : 0] counter_w;
reg [3 : 0] counter_r;

reg [47 : 0] key;
reg [31 : 0] F_out;

reg valid_w;
reg [127 : 0] iot_out_w;

assign valid = valid_w;
assign iot_out = iot_out_w;

always @ (*)
begin
	counter_w = counter_r;
	// if (enable)
	// begin
	// 	if (counter_r == 5'd18)
	// 	begin
			
	// 	end
	// 	else
	// 	begin
	// 		counter_w = counter_r + 1;
	// 	end
	// end
	// else
	// begin
	// 	counter_w = 0;
	// end
	case (current_state)
		IDLE:
		begin
			if (mode)
			begin
				counter_w = 0;
			end
			else
			begin
				counter_w = 15;
			end
		end
		ENCRYPT:
		begin
			counter_w = counter_r + 1;
		end
		DECRYPT:
		begin
			counter_w = counter_r - 1;
		end
	endcase
end

always @ (*)
begin
	iot_data_w = iot_data_r;

	key = 0;
	F_out = 0;

	case (current_state)
		IDLE:
		begin
			if (enable)
			begin
				iot_data_w = {{iot_in[120], iot_in[112], iot_in[104], iot_in[96], iot_in[88], iot_in[80], iot_in[72], iot_in[64], init_mainkey(iot_in[127 : 64])}, init_plaintext(iot_in[63 : 0])};
			end
			else
			begin
				iot_data_w = 0;
			end
		end
		// INIT_PERMU:
		// begin
		// 	iot_data_w[63 : 0] = init_plaintext(iot_data_r[63 : 0]);
		// 	iot_data_w[127 : 64] = {iot_data_r[120], iot_data_r[112], iot_data_r[104], iot_data_r[96], iot_data_r[88], iot_data_r[80], iot_data_r[72], iot_data_r[64], init_mainkey(iot_data_r[127 : 64])};
		// end
		ENCRYPT:
		begin
			if (counter_r == 4'd0 || counter_r == 4'd1 || counter_r == 4'd8 || counter_r == 4'd15)
			begin
				iot_data_w[119 : 64] = {iot_data_r[118 : 92], iot_data_r[119], iot_data_r[90 : 64], iot_data_r[91]};
			end
			else
			begin
				iot_data_w[119 : 64] = {iot_data_r[117 : 92], iot_data_r[119 : 118], iot_data_r[89 : 64], iot_data_r[91 : 90]};
			end

			key = PC2(iot_data_w[119 : 64]);

			F_out = F(iot_data_r[31 : 0], key);

			if (counter_r == 4'd15)
			begin
				iot_data_w[31 :  0] = iot_data_r[31 : 0];
				iot_data_w[63 : 32] = F_out ^ iot_data_r[63 : 32];
			end
			else
			begin
				iot_data_w[31 :  0] = F_out ^ iot_data_r[63 : 32];
				iot_data_w[63 : 32] = iot_data_r[31 : 0];
			end
		end
		DECRYPT:
		begin
			if (counter_r == 4'd0 || counter_r == 4'd1 || counter_r == 4'd8 || counter_r == 4'd15)
			begin
				iot_data_w[119 : 64] = {iot_data_r[92], iot_data_r[119 : 93], iot_data_r[64], iot_data_r[91 : 65]};
			end
			else
			begin
				iot_data_w[119 : 64] = {iot_data_r[93 : 92], iot_data_r[119 : 94], iot_data_r[65 : 64], iot_data_r[91 : 66]};
			end
			key = PC2(iot_data_r[119 : 64]);

			F_out = F(iot_data_r[31 : 0], key);

			if (counter_r == 4'd0)
			begin
				iot_data_w[31 :  0] = iot_data_r[31 : 0];
				iot_data_w[63 : 32] = F_out ^ iot_data_r[63 : 32];
			end
			else
			begin
				iot_data_w[31 :  0] = F_out ^ iot_data_r[63 : 32];
				iot_data_w[63 : 32] = iot_data_r[31 : 0];
			end
		end
		// FINAL_PERMU:
		// begin
		// 	iot_data_w[63 : 0] = final_ciphertext(iot_data_r[63 : 0]);
		// 	iot_data_w[127 : 64] = inv_key(iot_data_r[127 : 64]);
		// end
	endcase
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
		iot_data_r <= 0;
	end
	else
	begin
		iot_data_r <= iot_data_w;
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
	next_state = IDLE;
	case (current_state)
		IDLE:
		begin
			if (enable)
			begin
				if (mode)
				begin
					next_state = ENCRYPT;
				end
				else
				begin
					next_state = DECRYPT;
				end
			end
		end
		// INIT_PERMU:
		// begin
		// end
		ENCRYPT:
		begin
			if (counter_r == 4'd15)
			begin
				next_state = OUTPUT;
			end
			else
			begin
				next_state = ENCRYPT;
			end
		end
		DECRYPT:
		begin
			if (counter_r == 4'd0)
			begin
				next_state = OUTPUT;
			end
			else
			begin
				next_state = DECRYPT;
			end
		end
		// FINAL_PERMU : next_state = OUTPUT;
		OUTPUT: next_state = IDLE;
	endcase
end

always @ (*)
begin
	iot_out_w = 0;
	valid_w = 0;
	if (current_state == OUTPUT)
	begin
		iot_out_w = {inv_key(iot_data_r[127 : 64]), final_ciphertext(iot_data_r[63 : 0])};
		valid_w = 1;
	end
end

function automatic [63 : 0] init_plaintext;
	input [63 : 0] plaintext;
	begin
		init_plaintext = 
		{
			plaintext[ 6], plaintext[14], plaintext[22], plaintext[30], plaintext[38], plaintext[46], plaintext[54], plaintext[62],
			plaintext[ 4], plaintext[12], plaintext[20], plaintext[28], plaintext[36], plaintext[44], plaintext[52], plaintext[60],
			plaintext[ 2], plaintext[10], plaintext[18], plaintext[26], plaintext[34], plaintext[42], plaintext[50], plaintext[58],
			plaintext[ 0], plaintext[ 8], plaintext[16], plaintext[24], plaintext[32], plaintext[40], plaintext[48], plaintext[56],
			plaintext[ 7], plaintext[15], plaintext[23], plaintext[31], plaintext[39], plaintext[47], plaintext[55], plaintext[63],
			plaintext[ 5], plaintext[13], plaintext[21], plaintext[29], plaintext[37], plaintext[45], plaintext[53], plaintext[61],
			plaintext[ 3], plaintext[11], plaintext[19], plaintext[27], plaintext[35], plaintext[43], plaintext[51], plaintext[59],
			plaintext[ 1], plaintext[ 9], plaintext[17], plaintext[25], plaintext[33], plaintext[41], plaintext[49], plaintext[57]
		};
	end
endfunction

function automatic [55 : 0] init_mainkey;
	input [63 : 0] mainkey;
	begin
		init_mainkey = 
		{
			mainkey[ 7], mainkey[15], mainkey[23], mainkey[31], mainkey[39], mainkey[47], mainkey[55],
			mainkey[63], mainkey[ 6], mainkey[14], mainkey[22], mainkey[30], mainkey[38], mainkey[46],
			mainkey[54], mainkey[62], mainkey[ 5], mainkey[13], mainkey[21], mainkey[29], mainkey[37],
			mainkey[45], mainkey[53], mainkey[61], mainkey[ 4], mainkey[12], mainkey[20], mainkey[28],
			mainkey[ 1], mainkey[ 9], mainkey[17], mainkey[25], mainkey[33], mainkey[41], mainkey[49],
			mainkey[57], mainkey[ 2], mainkey[10], mainkey[18], mainkey[26], mainkey[34], mainkey[42],
			mainkey[50], mainkey[58], mainkey[ 3], mainkey[11], mainkey[19], mainkey[27], mainkey[35],
			mainkey[43], mainkey[51], mainkey[59], mainkey[36], mainkey[44], mainkey[52], mainkey[60]
		};
	end
endfunction

function automatic [63 : 0] inv_key;
	input [63 : 0] cipher_key;
	begin
		inv_key = 
		{
			cipher_key[48], cipher_key[40], cipher_key[32], cipher_key[ 0], cipher_key[ 4], cipher_key[12], cipher_key[20], cipher_key[63],
			cipher_key[49], cipher_key[41], cipher_key[33], cipher_key[ 1], cipher_key[ 5], cipher_key[13], cipher_key[21], cipher_key[62],
			cipher_key[50], cipher_key[42], cipher_key[34], cipher_key[ 2], cipher_key[ 6], cipher_key[14], cipher_key[22], cipher_key[61],
			cipher_key[51], cipher_key[43], cipher_key[35], cipher_key[ 3], cipher_key[ 7], cipher_key[15], cipher_key[23], cipher_key[60],
			cipher_key[52], cipher_key[44], cipher_key[36], cipher_key[28], cipher_key[ 8], cipher_key[16], cipher_key[24], cipher_key[59],
			cipher_key[53], cipher_key[45], cipher_key[37], cipher_key[29], cipher_key[ 9], cipher_key[17], cipher_key[25], cipher_key[58],
			cipher_key[54], cipher_key[46], cipher_key[38], cipher_key[30], cipher_key[10], cipher_key[18], cipher_key[26], cipher_key[57],
			cipher_key[55], cipher_key[47], cipher_key[39], cipher_key[31], cipher_key[11], cipher_key[19], cipher_key[27], cipher_key[56]
		};
	end
endfunction

function automatic [63 : 0] final_ciphertext;
	input [63 : 0] ciphertext;
	begin
		final_ciphertext = 
		{
			ciphertext[24], ciphertext[56], ciphertext[16], ciphertext[48], ciphertext[ 8], ciphertext[40], ciphertext[ 0], ciphertext[32],
			ciphertext[25], ciphertext[57], ciphertext[17], ciphertext[49], ciphertext[ 9], ciphertext[41], ciphertext[ 1], ciphertext[33],
			ciphertext[26], ciphertext[58], ciphertext[18], ciphertext[50], ciphertext[10], ciphertext[42], ciphertext[ 2], ciphertext[34],
			ciphertext[27], ciphertext[59], ciphertext[19], ciphertext[51], ciphertext[11], ciphertext[43], ciphertext[ 3], ciphertext[35],
			ciphertext[28], ciphertext[60], ciphertext[20], ciphertext[52], ciphertext[12], ciphertext[44], ciphertext[ 4], ciphertext[36],
			ciphertext[29], ciphertext[61], ciphertext[21], ciphertext[53], ciphertext[13], ciphertext[45], ciphertext[ 5], ciphertext[37],
			ciphertext[30], ciphertext[62], ciphertext[22], ciphertext[54], ciphertext[14], ciphertext[46], ciphertext[ 6], ciphertext[38],
			ciphertext[31], ciphertext[63], ciphertext[23], ciphertext[55], ciphertext[15], ciphertext[47], ciphertext[ 7], ciphertext[39]
		};
	end
endfunction

function automatic [47 : 0] PC2;
	input [55 : 0] cipher_key;
	begin
		PC2 = 
		{
			cipher_key[42], cipher_key[39], cipher_key[45], cipher_key[32], cipher_key[55], cipher_key[51], cipher_key[53], cipher_key[28],
			cipher_key[41], cipher_key[50], cipher_key[35], cipher_key[46], cipher_key[33], cipher_key[37], cipher_key[44], cipher_key[52],
			cipher_key[30], cipher_key[48], cipher_key[40], cipher_key[49], cipher_key[29], cipher_key[36], cipher_key[43], cipher_key[54],
			cipher_key[15], cipher_key[ 4], cipher_key[25], cipher_key[19], cipher_key[ 9], cipher_key[ 1], cipher_key[26], cipher_key[16],
			cipher_key[ 5], cipher_key[11], cipher_key[23], cipher_key[ 8], cipher_key[12], cipher_key[ 7], cipher_key[17], cipher_key[ 0],
			cipher_key[22], cipher_key[ 3], cipher_key[10], cipher_key[14], cipher_key[ 6], cipher_key[20], cipher_key[27], cipher_key[24]
		};
	end
endfunction

function automatic [31 : 0] P;
	input [31 : 0] box_text;
	begin
		P =
		{
			box_text[16], box_text[25], box_text[12], box_text[11], box_text[ 3], box_text[20], box_text[ 4], box_text[15],
			box_text[31], box_text[17], box_text[ 9], box_text[ 6], box_text[27], box_text[14], box_text[ 1], box_text[22],
			box_text[30], box_text[24], box_text[ 8], box_text[18], box_text[ 0], box_text[ 5], box_text[29], box_text[23],
			box_text[13], box_text[19], box_text[ 2], box_text[26], box_text[10], box_text[21], box_text[28], box_text[ 7]
		};
	end
endfunction

function automatic [31 : 0] F;
	input [31 : 0] R;
	input [47 : 0] K;
	reg [47 : 0] F_0;
	begin
		F_0 = expansion(R) ^ K;
		F = P
		({
			S_BOX_1(F_0[47 : 42]), S_BOX_2(F_0[41 : 36]), S_BOX_3(F_0[35 : 30]), S_BOX_4(F_0[29 : 24]),
			S_BOX_5(F_0[23 : 18]), S_BOX_6(F_0[17 : 12]), S_BOX_7(F_0[11 :  6]) ,S_BOX_8(F_0[ 5 :  0])
		});
	end
endfunction

function automatic [47 : 0] expansion;
	input [31 : 0] text;
	begin
		expansion =
		{
			text[ 0], text[31], text[30], text[29], text[28], text[27], text[28], text[27],
			text[26], text[25], text[24], text[23], text[24], text[23], text[22], text[21],
			text[20], text[19], text[20], text[19], text[18], text[17], text[16], text[15],
			text[16], text[15], text[14], text[13], text[12], text[11], text[12], text[11],
			text[10], text[ 9], text[ 8], text[ 7], text[ 8], text[ 7], text[ 6], text[ 5],
			text[ 4], text[ 3], text[ 4], text[ 3], text[ 2], text[ 1], text[ 0], text[31]
		};
	end
endfunction

// function automatic [27 : 0] left_rot_1;
// 	input [27 : 0] cipher_key;
// 	begin
// 		left_rot_1 = {cipher_key[90 : 64], cipher_key[27]};
// 	end
// endfunction

// function automatic [27 : 0] left_rot_2;
// 	input [27 : 0] cipher_key;
// 	begin
// 		left_rot_2 = {cipher_key[25 : 0], cipher_key[27 : 26]};
// 	end
// endfunction

function automatic [3 : 0] S_BOX_8;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_8 = 4'd13;
					4'd1: S_BOX_8 = 4'd2;
					4'd2: S_BOX_8 = 4'd8;
					4'd3: S_BOX_8 = 4'd4;
					4'd4: S_BOX_8 = 4'd6;
					4'd5: S_BOX_8 = 4'd15;
					4'd6: S_BOX_8 = 4'd11;
					4'd7: S_BOX_8 = 4'd1;
					4'd8: S_BOX_8 = 4'd10;
					4'd9: S_BOX_8 = 4'd9;
					4'd10: S_BOX_8 = 4'd3;
					4'd11: S_BOX_8 = 4'd14;
					4'd12: S_BOX_8 = 4'd5;
					4'd13: S_BOX_8 = 4'd0;
					4'd14: S_BOX_8 = 4'd12;
					4'd15: S_BOX_8 = 4'd7;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_8 = 4'd1;
					4'd1: S_BOX_8 = 4'd15;
					4'd2: S_BOX_8 = 4'd13;
					4'd3: S_BOX_8 = 4'd8;
					4'd4: S_BOX_8 = 4'd10;
					4'd5: S_BOX_8 = 4'd3;
					4'd6: S_BOX_8 = 4'd7;
					4'd7: S_BOX_8 = 4'd4;
					4'd8: S_BOX_8 = 4'd12;
					4'd9: S_BOX_8 = 4'd5;
					4'd10: S_BOX_8 = 4'd6;
					4'd11: S_BOX_8 = 4'd11;
					4'd12: S_BOX_8 = 4'd0;
					4'd13: S_BOX_8 = 4'd14;
					4'd14: S_BOX_8 = 4'd9;
					4'd15: S_BOX_8 = 4'd2;
				endcase
			end
			2'b10:
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_8 = 4'd7;
					4'd1: S_BOX_8 = 4'd11;
					4'd2: S_BOX_8 = 4'd4;
					4'd3: S_BOX_8 = 4'd1;
					4'd4: S_BOX_8 = 4'd9;
					4'd5: S_BOX_8 = 4'd12;
					4'd6: S_BOX_8 = 4'd14;
					4'd7: S_BOX_8 = 4'd2;
					4'd8: S_BOX_8 = 4'd0;
					4'd9: S_BOX_8 = 4'd6;
					4'd10: S_BOX_8 = 4'd10;
					4'd11: S_BOX_8 = 4'd13;
					4'd12: S_BOX_8 = 4'd15;
					4'd13: S_BOX_8 = 4'd3;
					4'd14: S_BOX_8 = 4'd5;
					4'd15: S_BOX_8 = 4'd8;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_8 = 4'd2;
					4'd1: S_BOX_8 = 4'd1;
					4'd2: S_BOX_8 = 4'd14;
					4'd3: S_BOX_8 = 4'd7;
					4'd4: S_BOX_8 = 4'd4;
					4'd5: S_BOX_8 = 4'd10;
					4'd6: S_BOX_8 = 4'd8;
					4'd7: S_BOX_8 = 4'd13;
					4'd8: S_BOX_8 = 4'd15;
					4'd9: S_BOX_8 = 4'd12;
					4'd10: S_BOX_8 = 4'd9;
					4'd11: S_BOX_8 = 4'd0;
					4'd12: S_BOX_8 = 4'd3;
					4'd13: S_BOX_8 = 4'd5;
					4'd14: S_BOX_8 = 4'd6;
					4'd15: S_BOX_8 = 4'd11;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_7;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_7 = 4'd4;
					4'd1: S_BOX_7 = 4'd11;
					4'd2: S_BOX_7 = 4'd2;
					4'd3: S_BOX_7 = 4'd14;
					4'd4: S_BOX_7 = 4'd15;
					4'd5: S_BOX_7 = 4'd0;
					4'd6: S_BOX_7 = 4'd8;
					4'd7: S_BOX_7 = 4'd13;
					4'd8: S_BOX_7 = 4'd3;
					4'd9: S_BOX_7 = 4'd12;
					4'd10: S_BOX_7 = 4'd9;
					4'd11: S_BOX_7 = 4'd7;
					4'd12: S_BOX_7 = 4'd5;
					4'd13: S_BOX_7 = 4'd10;
					4'd14: S_BOX_7 = 4'd6;
					4'd15: S_BOX_7 = 4'd1;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_7 = 4'd13;
					4'd1: S_BOX_7 = 4'd0;
					4'd2: S_BOX_7 = 4'd11;
					4'd3: S_BOX_7 = 4'd7;
					4'd4: S_BOX_7 = 4'd4;
					4'd5: S_BOX_7 = 4'd9;
					4'd6: S_BOX_7 = 4'd1;
					4'd7: S_BOX_7 = 4'd10;
					4'd8: S_BOX_7 = 4'd14;
					4'd9: S_BOX_7 = 4'd3;
					4'd10: S_BOX_7 = 4'd5;
					4'd11: S_BOX_7 = 4'd12;
					4'd12: S_BOX_7 = 4'd2;
					4'd13: S_BOX_7 = 4'd15;
					4'd14: S_BOX_7 = 4'd8;
					4'd15: S_BOX_7 = 4'd6;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_7 = 4'd1;
					4'd1: S_BOX_7 = 4'd4;
					4'd2: S_BOX_7 = 4'd11;
					4'd3: S_BOX_7 = 4'd13;
					4'd4: S_BOX_7 = 4'd12;
					4'd5: S_BOX_7 = 4'd3;
					4'd6: S_BOX_7 = 4'd7;
					4'd7: S_BOX_7 = 4'd14;
					4'd8: S_BOX_7 = 4'd10;
					4'd9: S_BOX_7 = 4'd15;
					4'd10: S_BOX_7 = 4'd6;
					4'd11: S_BOX_7 = 4'd8;
					4'd12: S_BOX_7 = 4'd0;
					4'd13: S_BOX_7 = 4'd5;
					4'd14: S_BOX_7 = 4'd9;
					4'd15: S_BOX_7 = 4'd2;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_7 = 4'd6;
					4'd1: S_BOX_7 = 4'd11;
					4'd2: S_BOX_7 = 4'd13;
					4'd3: S_BOX_7 = 4'd8;
					4'd4: S_BOX_7 = 4'd1;
					4'd5: S_BOX_7 = 4'd4;
					4'd6: S_BOX_7 = 4'd10;
					4'd7: S_BOX_7 = 4'd7;
					4'd8: S_BOX_7 = 4'd9;
					4'd9: S_BOX_7 = 4'd5;
					4'd10: S_BOX_7 = 4'd0;
					4'd11: S_BOX_7 = 4'd15;
					4'd12: S_BOX_7 = 4'd14;
					4'd13: S_BOX_7 = 4'd2;
					4'd14: S_BOX_7 = 4'd3;
					4'd15: S_BOX_7 = 4'd12;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_6;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_6 = 4'd12;
					4'd1: S_BOX_6 = 4'd1;
					4'd2: S_BOX_6 = 4'd10;
					4'd3: S_BOX_6 = 4'd15;
					4'd4: S_BOX_6 = 4'd9;
					4'd5: S_BOX_6 = 4'd2;
					4'd6: S_BOX_6 = 4'd6;
					4'd7: S_BOX_6 = 4'd8;
					4'd8: S_BOX_6 = 4'd0;
					4'd9: S_BOX_6 = 4'd13;
					4'd10: S_BOX_6 = 4'd3;
					4'd11: S_BOX_6 = 4'd4;
					4'd12: S_BOX_6 = 4'd14;
					4'd13: S_BOX_6 = 4'd7;
					4'd14: S_BOX_6 = 4'd5;
					4'd15: S_BOX_6 = 4'd11;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_6 = 4'd10;
					4'd1: S_BOX_6 = 4'd15;
					4'd2: S_BOX_6 = 4'd4;
					4'd3: S_BOX_6 = 4'd2;
					4'd4: S_BOX_6 = 4'd7;
					4'd5: S_BOX_6 = 4'd12;
					4'd6: S_BOX_6 = 4'd9;
					4'd7: S_BOX_6 = 4'd5;
					4'd8: S_BOX_6 = 4'd6;
					4'd9: S_BOX_6 = 4'd1;
					4'd10: S_BOX_6 = 4'd13;
					4'd11: S_BOX_6 = 4'd14;
					4'd12: S_BOX_6 = 4'd0;
					4'd13: S_BOX_6 = 4'd11;
					4'd14: S_BOX_6 = 4'd3;
					4'd15: S_BOX_6 = 4'd8;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_6 = 4'd9;
					4'd1: S_BOX_6 = 4'd14;
					4'd2: S_BOX_6 = 4'd15;
					4'd3: S_BOX_6 = 4'd5;
					4'd4: S_BOX_6 = 4'd2;
					4'd5: S_BOX_6 = 4'd8;
					4'd6: S_BOX_6 = 4'd12;
					4'd7: S_BOX_6 = 4'd3;
					4'd8: S_BOX_6 = 4'd7;
					4'd9: S_BOX_6 = 4'd0;
					4'd10: S_BOX_6 = 4'd4;
					4'd11: S_BOX_6 = 4'd10;
					4'd12: S_BOX_6 = 4'd1;
					4'd13: S_BOX_6 = 4'd13;
					4'd14: S_BOX_6 = 4'd11;
					4'd15: S_BOX_6 = 4'd6;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_6 = 4'd4;
					4'd1: S_BOX_6 = 4'd3;
					4'd2: S_BOX_6 = 4'd2;
					4'd3: S_BOX_6 = 4'd12;
					4'd4: S_BOX_6 = 4'd9;
					4'd5: S_BOX_6 = 4'd5;
					4'd6: S_BOX_6 = 4'd15;
					4'd7: S_BOX_6 = 4'd10;
					4'd8: S_BOX_6 = 4'd11;
					4'd9: S_BOX_6 = 4'd14;
					4'd10: S_BOX_6 = 4'd1;
					4'd11: S_BOX_6 = 4'd7;
					4'd12: S_BOX_6 = 4'd6;
					4'd13: S_BOX_6 = 4'd0;
					4'd14: S_BOX_6 = 4'd8;
					4'd15: S_BOX_6 = 4'd13;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_5;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_5 = 4'd2;
					4'd1: S_BOX_5 = 4'd12;
					4'd2: S_BOX_5 = 4'd4;
					4'd3: S_BOX_5 = 4'd1;
					4'd4: S_BOX_5 = 4'd7;
					4'd5: S_BOX_5 = 4'd10;
					4'd6: S_BOX_5 = 4'd11;
					4'd7: S_BOX_5 = 4'd6;
					4'd8: S_BOX_5 = 4'd8;
					4'd9: S_BOX_5 = 4'd5;
					4'd10: S_BOX_5 = 4'd3;
					4'd11: S_BOX_5 = 4'd15;
					4'd12: S_BOX_5 = 4'd13;
					4'd13: S_BOX_5 = 4'd0;
					4'd14: S_BOX_5 = 4'd14;
					4'd15: S_BOX_5 = 4'd9;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_5 = 4'd14;
					4'd1: S_BOX_5 = 4'd11;
					4'd2: S_BOX_5 = 4'd2;
					4'd3: S_BOX_5 = 4'd12;
					4'd4: S_BOX_5 = 4'd4;
					4'd5: S_BOX_5 = 4'd7;
					4'd6: S_BOX_5 = 4'd13;
					4'd7: S_BOX_5 = 4'd1;
					4'd8: S_BOX_5 = 4'd5;
					4'd9: S_BOX_5 = 4'd0;
					4'd10: S_BOX_5 = 4'd15;
					4'd11: S_BOX_5 = 4'd10;
					4'd12: S_BOX_5 = 4'd3;
					4'd13: S_BOX_5 = 4'd9;
					4'd14: S_BOX_5 = 4'd8;
					4'd15: S_BOX_5 = 4'd6;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_5 = 4'd4;
					4'd1: S_BOX_5 = 4'd2;
					4'd2: S_BOX_5 = 4'd1;
					4'd3: S_BOX_5 = 4'd11;
					4'd4: S_BOX_5 = 4'd10;
					4'd5: S_BOX_5 = 4'd13;
					4'd6: S_BOX_5 = 4'd7;
					4'd7: S_BOX_5 = 4'd8;
					4'd8: S_BOX_5 = 4'd15;
					4'd9: S_BOX_5 = 4'd9;
					4'd10: S_BOX_5 = 4'd12;
					4'd11: S_BOX_5 = 4'd5;
					4'd12: S_BOX_5 = 4'd6;
					4'd13: S_BOX_5 = 4'd3;
					4'd14: S_BOX_5 = 4'd0;
					4'd15: S_BOX_5 = 4'd14;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_5 = 4'd11;
					4'd1: S_BOX_5 = 4'd8;
					4'd2: S_BOX_5 = 4'd12;
					4'd3: S_BOX_5 = 4'd7;
					4'd4: S_BOX_5 = 4'd1;
					4'd5: S_BOX_5 = 4'd14;
					4'd6: S_BOX_5 = 4'd2;
					4'd7: S_BOX_5 = 4'd13;
					4'd8: S_BOX_5 = 4'd6;
					4'd9: S_BOX_5 = 4'd15;
					4'd10: S_BOX_5 = 4'd0;
					4'd11: S_BOX_5 = 4'd9;
					4'd12: S_BOX_5 = 4'd10;
					4'd13: S_BOX_5 = 4'd4;
					4'd14: S_BOX_5 = 4'd5;
					4'd15: S_BOX_5 = 4'd3;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_4;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_4 = 4'd7;
					4'd1: S_BOX_4 = 4'd13;
					4'd2: S_BOX_4 = 4'd14;
					4'd3: S_BOX_4 = 4'd3;
					4'd4: S_BOX_4 = 4'd0;
					4'd5: S_BOX_4 = 4'd6;
					4'd6: S_BOX_4 = 4'd9;
					4'd7: S_BOX_4 = 4'd10;
					4'd8: S_BOX_4 = 4'd1;
					4'd9: S_BOX_4 = 4'd2;
					4'd10: S_BOX_4 = 4'd8;
					4'd11: S_BOX_4 = 4'd5;
					4'd12: S_BOX_4 = 4'd11;
					4'd13: S_BOX_4 = 4'd12;
					4'd14: S_BOX_4 = 4'd4;
					4'd15: S_BOX_4 = 4'd15;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_4 = 4'd13;
					4'd1: S_BOX_4 = 4'd8;
					4'd2: S_BOX_4 = 4'd11;
					4'd3: S_BOX_4 = 4'd5;
					4'd4: S_BOX_4 = 4'd6;
					4'd5: S_BOX_4 = 4'd15;
					4'd6: S_BOX_4 = 4'd0;
					4'd7: S_BOX_4 = 4'd3;
					4'd8: S_BOX_4 = 4'd4;
					4'd9: S_BOX_4 = 4'd7;
					4'd10: S_BOX_4 = 4'd2;
					4'd11: S_BOX_4 = 4'd12;
					4'd12: S_BOX_4 = 4'd1;
					4'd13: S_BOX_4 = 4'd10;
					4'd14: S_BOX_4 = 4'd14;
					4'd15: S_BOX_4 = 4'd9;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_4 = 4'd10;
					4'd1: S_BOX_4 = 4'd6;
					4'd2: S_BOX_4 = 4'd9;
					4'd3: S_BOX_4 = 4'd0;
					4'd4: S_BOX_4 = 4'd12;
					4'd5: S_BOX_4 = 4'd11;
					4'd6: S_BOX_4 = 4'd7;
					4'd7: S_BOX_4 = 4'd13;
					4'd8: S_BOX_4 = 4'd15;
					4'd9: S_BOX_4 = 4'd1;
					4'd10: S_BOX_4 = 4'd3;
					4'd11: S_BOX_4 = 4'd14;
					4'd12: S_BOX_4 = 4'd5;
					4'd13: S_BOX_4 = 4'd2;
					4'd14: S_BOX_4 = 4'd8;
					4'd15: S_BOX_4 = 4'd4;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_4 = 4'd3;
					4'd1: S_BOX_4 = 4'd15;
					4'd2: S_BOX_4 = 4'd0;
					4'd3: S_BOX_4 = 4'd6;
					4'd4: S_BOX_4 = 4'd10;
					4'd5: S_BOX_4 = 4'd1;
					4'd6: S_BOX_4 = 4'd13;
					4'd7: S_BOX_4 = 4'd8;
					4'd8: S_BOX_4 = 4'd9;
					4'd9: S_BOX_4 = 4'd4;
					4'd10: S_BOX_4 = 4'd5;
					4'd11: S_BOX_4 = 4'd11;
					4'd12: S_BOX_4 = 4'd12;
					4'd13: S_BOX_4 = 4'd7;
					4'd14: S_BOX_4 = 4'd2;
					4'd15: S_BOX_4 = 4'd14;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_3;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_3 = 4'd10;
					4'd1: S_BOX_3 = 4'd0;
					4'd2: S_BOX_3 = 4'd9;
					4'd3: S_BOX_3 = 4'd14;
					4'd4: S_BOX_3 = 4'd6;
					4'd5: S_BOX_3 = 4'd3;
					4'd6: S_BOX_3 = 4'd15;
					4'd7: S_BOX_3 = 4'd5;
					4'd8: S_BOX_3 = 4'd1;
					4'd9: S_BOX_3 = 4'd13;
					4'd10: S_BOX_3 = 4'd12;
					4'd11: S_BOX_3 = 4'd7;
					4'd12: S_BOX_3 = 4'd11;
					4'd13: S_BOX_3 = 4'd4;
					4'd14: S_BOX_3 = 4'd2;
					4'd15: S_BOX_3 = 4'd8;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_3 = 4'd13;
					4'd1: S_BOX_3 = 4'd7;
					4'd2: S_BOX_3 = 4'd0;
					4'd3: S_BOX_3 = 4'd9;
					4'd4: S_BOX_3 = 4'd3;
					4'd5: S_BOX_3 = 4'd4;
					4'd6: S_BOX_3 = 4'd6;
					4'd7: S_BOX_3 = 4'd10;
					4'd8: S_BOX_3 = 4'd2;
					4'd9: S_BOX_3 = 4'd8;
					4'd10: S_BOX_3 = 4'd5;
					4'd11: S_BOX_3 = 4'd14;
					4'd12: S_BOX_3 = 4'd12;
					4'd13: S_BOX_3 = 4'd11;
					4'd14: S_BOX_3 = 4'd15;
					4'd15: S_BOX_3 = 4'd1;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_3 = 4'd13;
					4'd1: S_BOX_3 = 4'd6;
					4'd2: S_BOX_3 = 4'd4;
					4'd3: S_BOX_3 = 4'd9;
					4'd4: S_BOX_3 = 4'd8;
					4'd5: S_BOX_3 = 4'd15;
					4'd6: S_BOX_3 = 4'd3;
					4'd7: S_BOX_3 = 4'd0;
					4'd8: S_BOX_3 = 4'd11;
					4'd9: S_BOX_3 = 4'd1;
					4'd10: S_BOX_3 = 4'd2;
					4'd11: S_BOX_3 = 4'd12;
					4'd12: S_BOX_3 = 4'd5;
					4'd13: S_BOX_3 = 4'd10;
					4'd14: S_BOX_3 = 4'd14;
					4'd15: S_BOX_3 = 4'd7;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_3 = 4'd1;
					4'd1: S_BOX_3 = 4'd10;
					4'd2: S_BOX_3 = 4'd13;
					4'd3: S_BOX_3 = 4'd0;
					4'd4: S_BOX_3 = 4'd6;
					4'd5: S_BOX_3 = 4'd9;
					4'd6: S_BOX_3 = 4'd8;
					4'd7: S_BOX_3 = 4'd7;
					4'd8: S_BOX_3 = 4'd4;
					4'd9: S_BOX_3 = 4'd15;
					4'd10: S_BOX_3 = 4'd14;
					4'd11: S_BOX_3 = 4'd3;
					4'd12: S_BOX_3 = 4'd11;
					4'd13: S_BOX_3 = 4'd5;
					4'd14: S_BOX_3 = 4'd2;
					4'd15: S_BOX_3 = 4'd12;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_2;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_2 = 4'd15;
					4'd1: S_BOX_2 = 4'd1;
					4'd2: S_BOX_2 = 4'd8;
					4'd3: S_BOX_2 = 4'd14;
					4'd4: S_BOX_2 = 4'd6;
					4'd5: S_BOX_2 = 4'd11;
					4'd6: S_BOX_2 = 4'd3;
					4'd7: S_BOX_2 = 4'd4;
					4'd8: S_BOX_2 = 4'd9;
					4'd9: S_BOX_2 = 4'd7;
					4'd10: S_BOX_2 = 4'd2;
					4'd11: S_BOX_2 = 4'd13;
					4'd12: S_BOX_2 = 4'd12;
					4'd13: S_BOX_2 = 4'd0;
					4'd14: S_BOX_2 = 4'd5;
					4'd15: S_BOX_2 = 4'd10;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_2 = 4'd3;
					4'd1: S_BOX_2 = 4'd13;
					4'd2: S_BOX_2 = 4'd4;
					4'd3: S_BOX_2 = 4'd7;
					4'd4: S_BOX_2 = 4'd15;
					4'd5: S_BOX_2 = 4'd2;
					4'd6: S_BOX_2 = 4'd8;
					4'd7: S_BOX_2 = 4'd14;
					4'd8: S_BOX_2 = 4'd12;
					4'd9: S_BOX_2 = 4'd0;
					4'd10: S_BOX_2 = 4'd1;
					4'd11: S_BOX_2 = 4'd10;
					4'd12: S_BOX_2 = 4'd6;
					4'd13: S_BOX_2 = 4'd9;
					4'd14: S_BOX_2 = 4'd11;
					4'd15: S_BOX_2 = 4'd5;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_2 = 4'd0;
					4'd1: S_BOX_2 = 4'd14;
					4'd2: S_BOX_2 = 4'd7;
					4'd3: S_BOX_2 = 4'd11;
					4'd4: S_BOX_2 = 4'd10;
					4'd5: S_BOX_2 = 4'd4;
					4'd6: S_BOX_2 = 4'd13;
					4'd7: S_BOX_2 = 4'd1;
					4'd8: S_BOX_2 = 4'd5;
					4'd9: S_BOX_2 = 4'd8;
					4'd10: S_BOX_2 = 4'd12;
					4'd11: S_BOX_2 = 4'd6;
					4'd12: S_BOX_2 = 4'd9;
					4'd13: S_BOX_2 = 4'd3;
					4'd14: S_BOX_2 = 4'd2;
					4'd15: S_BOX_2 = 4'd15;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_2 = 4'd13;
					4'd1: S_BOX_2 = 4'd8;
					4'd2: S_BOX_2 = 4'd10;
					4'd3: S_BOX_2 = 4'd1;
					4'd4: S_BOX_2 = 4'd3;
					4'd5: S_BOX_2 = 4'd15;
					4'd6: S_BOX_2 = 4'd4;
					4'd7: S_BOX_2 = 4'd2;
					4'd8: S_BOX_2 = 4'd11;
					4'd9: S_BOX_2 = 4'd6;
					4'd10: S_BOX_2 = 4'd7;
					4'd11: S_BOX_2 = 4'd12;
					4'd12: S_BOX_2 = 4'd0;
					4'd13: S_BOX_2 = 4'd5;
					4'd14: S_BOX_2 = 4'd14;
					4'd15: S_BOX_2 = 4'd9;
				endcase
			end
		endcase
	end
endfunction

function automatic [3 : 0] S_BOX_1;
	input [5 : 0] i_data;
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_1 = 4'd14;
					4'd1: S_BOX_1 = 4'd4;
					4'd2: S_BOX_1 = 4'd13;
					4'd3: S_BOX_1 = 4'd1;
					4'd4: S_BOX_1 = 4'd2;
					4'd5: S_BOX_1 = 4'd15;
					4'd6: S_BOX_1 = 4'd11;
					4'd7: S_BOX_1 = 4'd8;
					4'd8: S_BOX_1 = 4'd3;
					4'd9: S_BOX_1 = 4'd10;
					4'd10: S_BOX_1 = 4'd6;
					4'd11: S_BOX_1 = 4'd12;
					4'd12: S_BOX_1 = 4'd5;
					4'd13: S_BOX_1 = 4'd9;
					4'd14: S_BOX_1 = 4'd0;
					4'd15: S_BOX_1 = 4'd7;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_1 = 4'd0;
					4'd1: S_BOX_1 = 4'd15;
					4'd2: S_BOX_1 = 4'd7;
					4'd3: S_BOX_1 = 4'd4;
					4'd4: S_BOX_1 = 4'd14;
					4'd5: S_BOX_1 = 4'd2;
					4'd6: S_BOX_1 = 4'd13;
					4'd7: S_BOX_1 = 4'd1;
					4'd8: S_BOX_1 = 4'd10;
					4'd9: S_BOX_1 = 4'd6;
					4'd10: S_BOX_1 = 4'd12;
					4'd11: S_BOX_1 = 4'd11;
					4'd12: S_BOX_1 = 4'd9;
					4'd13: S_BOX_1 = 4'd5;
					4'd14: S_BOX_1 = 4'd3;
					4'd15: S_BOX_1 = 4'd8;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_1 = 4'd4;
					4'd1: S_BOX_1 = 4'd1;
					4'd2: S_BOX_1 = 4'd14;
					4'd3: S_BOX_1 = 4'd8;
					4'd4: S_BOX_1 = 4'd13;
					4'd5: S_BOX_1 = 4'd6;
					4'd6: S_BOX_1 = 4'd2;
					4'd7: S_BOX_1 = 4'd11;
					4'd8: S_BOX_1 = 4'd15;
					4'd9: S_BOX_1 = 4'd12;
					4'd10: S_BOX_1 = 4'd9;
					4'd11: S_BOX_1 = 4'd7;
					4'd12: S_BOX_1 = 4'd3;
					4'd13: S_BOX_1 = 4'd10;
					4'd14: S_BOX_1 = 4'd5;
					4'd15: S_BOX_1 = 4'd0;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: S_BOX_1 = 4'd15;
					4'd1: S_BOX_1 = 4'd12;
					4'd2: S_BOX_1 = 4'd8;
					4'd3: S_BOX_1 = 4'd2;
					4'd4: S_BOX_1 = 4'd4;
					4'd5: S_BOX_1 = 4'd9;
					4'd6: S_BOX_1 = 4'd1;
					4'd7: S_BOX_1 = 4'd7;
					4'd8: S_BOX_1 = 4'd5;
					4'd9: S_BOX_1 = 4'd11;
					4'd10: S_BOX_1 = 4'd3;
					4'd11: S_BOX_1 = 4'd14;
					4'd12: S_BOX_1 = 4'd10;
					4'd13: S_BOX_1 = 4'd0;
					4'd14: S_BOX_1 = 4'd6;
					4'd15: S_BOX_1 = 4'd13;
				endcase
			end
		endcase
	end
endfunction

endmodule