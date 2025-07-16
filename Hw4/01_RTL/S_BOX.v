module S_BOX
(
	input enable,
    output valid,
	input  [47 : 0] i_data,
	output [31 : 0] o_data
);

wire [7 : 0] s_valid;

assign valid = s_valid[0] && s_valid[1] && s_valid[2] && s_valid[3] && s_valid[4] && s_valid[5] && s_valid[6] && s_valid[7];

S_BOX_1 u_S_BOX_1
(
	.enable (enable),
    .valid  (s_valid[0]),
	.i_data (i_data[47 : 42]),
	.o_data (o_data[31 : 28])
);

S_BOX_2 u_S_BOX_2
(
	.enable (enable),
    .valid  (s_valid[1]),
	.i_data (i_data[41 : 36]),
	.o_data (o_data[27 : 24])
);

S_BOX_3 u_S_BOX_3
(
	.enable (enable),
    .valid  (s_valid[2]),
	.i_data (i_data[35 : 30]),
	.o_data (o_data[23 : 20])
);

S_BOX_4 u_S_BOX_4
(
	.enable (enable),
    .valid  (s_valid[3]),
	.i_data (i_data[29 : 24]),
	.o_data (o_data[19 : 16])
);

S_BOX_5 u_S_BOX_5
(
	.enable (enable),
    .valid  (s_valid[4]),
	.i_data (i_data[23 : 18]),
	.o_data (o_data[15 : 12])
);

S_BOX_6 u_S_BOX_6
(
	.enable (enable),
    .valid  (s_valid[5]),
	.i_data (i_data[17 : 12]),
	.o_data (o_data[11 :  8])
);

S_BOX_7 u_S_BOX_7
(
	.enable (enable),
    .valid  (s_valid[6]),
	.i_data (i_data[11 :  6]),
	.o_data (o_data[ 7 :  4])
);

S_BOX_8 u_S_BOX_8
(
	.enable (enable),
    .valid  (s_valid[7]),
	.i_data (i_data[ 5 :  0]),
	.o_data (o_data[ 3 :  0])
);

endmodule

module S_BOX_8
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd2;
					4'd2: o_data_w = 4'd8;
					4'd3: o_data_w = 4'd4;
					4'd4: o_data_w = 4'd6;
					4'd5: o_data_w = 4'd15;
					4'd6: o_data_w = 4'd11;
					4'd7: o_data_w = 4'd1;
					4'd8: o_data_w = 4'd10;
					4'd9: o_data_w = 4'd9;
					4'd10: o_data_w = 4'd3;
					4'd11: o_data_w = 4'd14;
					4'd12: o_data_w = 4'd5;
					4'd13: o_data_w = 4'd0;
					4'd14: o_data_w = 4'd12;
					4'd15: o_data_w = 4'd7;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd1;
					4'd1: o_data_w = 4'd15;
					4'd2: o_data_w = 4'd13;
					4'd3: o_data_w = 4'd8;
					4'd4: o_data_w = 4'd10;
					4'd5: o_data_w = 4'd3;
					4'd6: o_data_w = 4'd7;
					4'd7: o_data_w = 4'd4;
					4'd8: o_data_w = 4'd12;
					4'd9: o_data_w = 4'd5;
					4'd10: o_data_w = 4'd6;
					4'd11: o_data_w = 4'd11;
					4'd12: o_data_w = 4'd0;
					4'd13: o_data_w = 4'd14;
					4'd14: o_data_w = 4'd9;
					4'd15: o_data_w = 4'd2;
				endcase
			end
			2'b10:
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd7;
					4'd1: o_data_w = 4'd11;
					4'd2: o_data_w = 4'd4;
					4'd3: o_data_w = 4'd1;
					4'd4: o_data_w = 4'd9;
					4'd5: o_data_w = 4'd12;
					4'd6: o_data_w = 4'd14;
					4'd7: o_data_w = 4'd2;
					4'd8: o_data_w = 4'd0;
					4'd9: o_data_w = 4'd6;
					4'd10: o_data_w = 4'd10;
					4'd11: o_data_w = 4'd13;
					4'd12: o_data_w = 4'd15;
					4'd13: o_data_w = 4'd3;
					4'd14: o_data_w = 4'd5;
					4'd15: o_data_w = 4'd8;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd2;
					4'd1: o_data_w = 4'd1;
					4'd2: o_data_w = 4'd14;
					4'd3: o_data_w = 4'd7;
					4'd4: o_data_w = 4'd4;
					4'd5: o_data_w = 4'd10;
					4'd6: o_data_w = 4'd8;
					4'd7: o_data_w = 4'd13;
					4'd8: o_data_w = 4'd15;
					4'd9: o_data_w = 4'd12;
					4'd10: o_data_w = 4'd9;
					4'd11: o_data_w = 4'd0;
					4'd12: o_data_w = 4'd3;
					4'd13: o_data_w = 4'd5;
					4'd14: o_data_w = 4'd6;
					4'd15: o_data_w = 4'd11;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_7
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd4;
					4'd1: o_data_w = 4'd11;
					4'd2: o_data_w = 4'd2;
					4'd3: o_data_w = 4'd14;
					4'd4: o_data_w = 4'd15;
					4'd5: o_data_w = 4'd0;
					4'd6: o_data_w = 4'd8;
					4'd7: o_data_w = 4'd13;
					4'd8: o_data_w = 4'd3;
					4'd9: o_data_w = 4'd12;
					4'd10: o_data_w = 4'd9;
					4'd11: o_data_w = 4'd7;
					4'd12: o_data_w = 4'd5;
					4'd13: o_data_w = 4'd10;
					4'd14: o_data_w = 4'd6;
					4'd15: o_data_w = 4'd1;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd0;
					4'd2: o_data_w = 4'd11;
					4'd3: o_data_w = 4'd7;
					4'd4: o_data_w = 4'd4;
					4'd5: o_data_w = 4'd9;
					4'd6: o_data_w = 4'd1;
					4'd7: o_data_w = 4'd10;
					4'd8: o_data_w = 4'd14;
					4'd9: o_data_w = 4'd3;
					4'd10: o_data_w = 4'd5;
					4'd11: o_data_w = 4'd12;
					4'd12: o_data_w = 4'd2;
					4'd13: o_data_w = 4'd15;
					4'd14: o_data_w = 4'd8;
					4'd15: o_data_w = 4'd6;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd1;
					4'd1: o_data_w = 4'd4;
					4'd2: o_data_w = 4'd11;
					4'd3: o_data_w = 4'd13;
					4'd4: o_data_w = 4'd12;
					4'd5: o_data_w = 4'd3;
					4'd6: o_data_w = 4'd7;
					4'd7: o_data_w = 4'd14;
					4'd8: o_data_w = 4'd10;
					4'd9: o_data_w = 4'd15;
					4'd10: o_data_w = 4'd6;
					4'd11: o_data_w = 4'd8;
					4'd12: o_data_w = 4'd0;
					4'd13: o_data_w = 4'd5;
					4'd14: o_data_w = 4'd9;
					4'd15: o_data_w = 4'd2;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd6;
					4'd1: o_data_w = 4'd11;
					4'd2: o_data_w = 4'd13;
					4'd3: o_data_w = 4'd8;
					4'd4: o_data_w = 4'd1;
					4'd5: o_data_w = 4'd4;
					4'd6: o_data_w = 4'd10;
					4'd7: o_data_w = 4'd7;
					4'd8: o_data_w = 4'd9;
					4'd9: o_data_w = 4'd5;
					4'd10: o_data_w = 4'd0;
					4'd11: o_data_w = 4'd15;
					4'd12: o_data_w = 4'd14;
					4'd13: o_data_w = 4'd2;
					4'd14: o_data_w = 4'd3;
					4'd15: o_data_w = 4'd12;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_6
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd12;
					4'd1: o_data_w = 4'd1;
					4'd2: o_data_w = 4'd10;
					4'd3: o_data_w = 4'd15;
					4'd4: o_data_w = 4'd9;
					4'd5: o_data_w = 4'd2;
					4'd6: o_data_w = 4'd6;
					4'd7: o_data_w = 4'd8;
					4'd8: o_data_w = 4'd0;
					4'd9: o_data_w = 4'd13;
					4'd10: o_data_w = 4'd3;
					4'd11: o_data_w = 4'd4;
					4'd12: o_data_w = 4'd14;
					4'd13: o_data_w = 4'd7;
					4'd14: o_data_w = 4'd5;
					4'd15: o_data_w = 4'd11;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd10;
					4'd1: o_data_w = 4'd15;
					4'd2: o_data_w = 4'd4;
					4'd3: o_data_w = 4'd2;
					4'd4: o_data_w = 4'd7;
					4'd5: o_data_w = 4'd12;
					4'd6: o_data_w = 4'd9;
					4'd7: o_data_w = 4'd5;
					4'd8: o_data_w = 4'd6;
					4'd9: o_data_w = 4'd1;
					4'd10: o_data_w = 4'd13;
					4'd11: o_data_w = 4'd14;
					4'd12: o_data_w = 4'd0;
					4'd13: o_data_w = 4'd11;
					4'd14: o_data_w = 4'd3;
					4'd15: o_data_w = 4'd8;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd9;
					4'd1: o_data_w = 4'd14;
					4'd2: o_data_w = 4'd15;
					4'd3: o_data_w = 4'd5;
					4'd4: o_data_w = 4'd2;
					4'd5: o_data_w = 4'd8;
					4'd6: o_data_w = 4'd12;
					4'd7: o_data_w = 4'd3;
					4'd8: o_data_w = 4'd7;
					4'd9: o_data_w = 4'd0;
					4'd10: o_data_w = 4'd4;
					4'd11: o_data_w = 4'd10;
					4'd12: o_data_w = 4'd1;
					4'd13: o_data_w = 4'd13;
					4'd14: o_data_w = 4'd11;
					4'd15: o_data_w = 4'd6;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd4;
					4'd1: o_data_w = 4'd3;
					4'd2: o_data_w = 4'd2;
					4'd3: o_data_w = 4'd12;
					4'd4: o_data_w = 4'd9;
					4'd5: o_data_w = 4'd5;
					4'd6: o_data_w = 4'd15;
					4'd7: o_data_w = 4'd10;
					4'd8: o_data_w = 4'd11;
					4'd9: o_data_w = 4'd14;
					4'd10: o_data_w = 4'd1;
					4'd11: o_data_w = 4'd7;
					4'd12: o_data_w = 4'd6;
					4'd13: o_data_w = 4'd0;
					4'd14: o_data_w = 4'd8;
					4'd15: o_data_w = 4'd13;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_5
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd2;
					4'd1: o_data_w = 4'd12;
					4'd2: o_data_w = 4'd4;
					4'd3: o_data_w = 4'd1;
					4'd4: o_data_w = 4'd7;
					4'd5: o_data_w = 4'd10;
					4'd6: o_data_w = 4'd11;
					4'd7: o_data_w = 4'd6;
					4'd8: o_data_w = 4'd8;
					4'd9: o_data_w = 4'd5;
					4'd10: o_data_w = 4'd3;
					4'd11: o_data_w = 4'd15;
					4'd12: o_data_w = 4'd13;
					4'd13: o_data_w = 4'd0;
					4'd14: o_data_w = 4'd14;
					4'd15: o_data_w = 4'd9;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd14;
					4'd1: o_data_w = 4'd11;
					4'd2: o_data_w = 4'd2;
					4'd3: o_data_w = 4'd12;
					4'd4: o_data_w = 4'd4;
					4'd5: o_data_w = 4'd7;
					4'd6: o_data_w = 4'd13;
					4'd7: o_data_w = 4'd1;
					4'd8: o_data_w = 4'd5;
					4'd9: o_data_w = 4'd0;
					4'd10: o_data_w = 4'd15;
					4'd11: o_data_w = 4'd10;
					4'd12: o_data_w = 4'd3;
					4'd13: o_data_w = 4'd9;
					4'd14: o_data_w = 4'd8;
					4'd15: o_data_w = 4'd6;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd4;
					4'd1: o_data_w = 4'd2;
					4'd2: o_data_w = 4'd1;
					4'd3: o_data_w = 4'd11;
					4'd4: o_data_w = 4'd10;
					4'd5: o_data_w = 4'd13;
					4'd6: o_data_w = 4'd7;
					4'd7: o_data_w = 4'd8;
					4'd8: o_data_w = 4'd15;
					4'd9: o_data_w = 4'd9;
					4'd10: o_data_w = 4'd12;
					4'd11: o_data_w = 4'd5;
					4'd12: o_data_w = 4'd6;
					4'd13: o_data_w = 4'd3;
					4'd14: o_data_w = 4'd0;
					4'd15: o_data_w = 4'd14;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd11;
					4'd1: o_data_w = 4'd8;
					4'd2: o_data_w = 4'd12;
					4'd3: o_data_w = 4'd7;
					4'd4: o_data_w = 4'd1;
					4'd5: o_data_w = 4'd14;
					4'd6: o_data_w = 4'd2;
					4'd7: o_data_w = 4'd13;
					4'd8: o_data_w = 4'd6;
					4'd9: o_data_w = 4'd15;
					4'd10: o_data_w = 4'd0;
					4'd11: o_data_w = 4'd9;
					4'd12: o_data_w = 4'd10;
					4'd13: o_data_w = 4'd4;
					4'd14: o_data_w = 4'd5;
					4'd15: o_data_w = 4'd3;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_4
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd7;
					4'd1: o_data_w = 4'd13;
					4'd2: o_data_w = 4'd14;
					4'd3: o_data_w = 4'd3;
					4'd4: o_data_w = 4'd0;
					4'd5: o_data_w = 4'd6;
					4'd6: o_data_w = 4'd9;
					4'd7: o_data_w = 4'd10;
					4'd8: o_data_w = 4'd1;
					4'd9: o_data_w = 4'd2;
					4'd10: o_data_w = 4'd8;
					4'd11: o_data_w = 4'd5;
					4'd12: o_data_w = 4'd11;
					4'd13: o_data_w = 4'd12;
					4'd14: o_data_w = 4'd4;
					4'd15: o_data_w = 4'd15;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd8;
					4'd2: o_data_w = 4'd11;
					4'd3: o_data_w = 4'd5;
					4'd4: o_data_w = 4'd6;
					4'd5: o_data_w = 4'd15;
					4'd6: o_data_w = 4'd0;
					4'd7: o_data_w = 4'd3;
					4'd8: o_data_w = 4'd4;
					4'd9: o_data_w = 4'd7;
					4'd10: o_data_w = 4'd2;
					4'd11: o_data_w = 4'd12;
					4'd12: o_data_w = 4'd1;
					4'd13: o_data_w = 4'd10;
					4'd14: o_data_w = 4'd14;
					4'd15: o_data_w = 4'd9;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd10;
					4'd1: o_data_w = 4'd6;
					4'd2: o_data_w = 4'd9;
					4'd3: o_data_w = 4'd0;
					4'd4: o_data_w = 4'd12;
					4'd5: o_data_w = 4'd11;
					4'd6: o_data_w = 4'd7;
					4'd7: o_data_w = 4'd13;
					4'd8: o_data_w = 4'd15;
					4'd9: o_data_w = 4'd1;
					4'd10: o_data_w = 4'd3;
					4'd11: o_data_w = 4'd14;
					4'd12: o_data_w = 4'd5;
					4'd13: o_data_w = 4'd2;
					4'd14: o_data_w = 4'd8;
					4'd15: o_data_w = 4'd4;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd3;
					4'd1: o_data_w = 4'd15;
					4'd2: o_data_w = 4'd0;
					4'd3: o_data_w = 4'd6;
					4'd4: o_data_w = 4'd10;
					4'd5: o_data_w = 4'd1;
					4'd6: o_data_w = 4'd13;
					4'd7: o_data_w = 4'd8;
					4'd8: o_data_w = 4'd9;
					4'd9: o_data_w = 4'd4;
					4'd10: o_data_w = 4'd5;
					4'd11: o_data_w = 4'd11;
					4'd12: o_data_w = 4'd12;
					4'd13: o_data_w = 4'd7;
					4'd14: o_data_w = 4'd2;
					4'd15: o_data_w = 4'd14;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_3
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd10;
					4'd1: o_data_w = 4'd0;
					4'd2: o_data_w = 4'd9;
					4'd3: o_data_w = 4'd14;
					4'd4: o_data_w = 4'd6;
					4'd5: o_data_w = 4'd3;
					4'd6: o_data_w = 4'd15;
					4'd7: o_data_w = 4'd5;
					4'd8: o_data_w = 4'd1;
					4'd9: o_data_w = 4'd13;
					4'd10: o_data_w = 4'd12;
					4'd11: o_data_w = 4'd7;
					4'd12: o_data_w = 4'd11;
					4'd13: o_data_w = 4'd4;
					4'd14: o_data_w = 4'd2;
					4'd15: o_data_w = 4'd8;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd7;
					4'd2: o_data_w = 4'd0;
					4'd3: o_data_w = 4'd9;
					4'd4: o_data_w = 4'd3;
					4'd5: o_data_w = 4'd4;
					4'd6: o_data_w = 4'd6;
					4'd7: o_data_w = 4'd10;
					4'd8: o_data_w = 4'd2;
					4'd9: o_data_w = 4'd8;
					4'd10: o_data_w = 4'd5;
					4'd11: o_data_w = 4'd14;
					4'd12: o_data_w = 4'd12;
					4'd13: o_data_w = 4'd11;
					4'd14: o_data_w = 4'd15;
					4'd15: o_data_w = 4'd1;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd6;
					4'd2: o_data_w = 4'd4;
					4'd3: o_data_w = 4'd9;
					4'd4: o_data_w = 4'd8;
					4'd5: o_data_w = 4'd15;
					4'd6: o_data_w = 4'd3;
					4'd7: o_data_w = 4'd0;
					4'd8: o_data_w = 4'd11;
					4'd9: o_data_w = 4'd1;
					4'd10: o_data_w = 4'd2;
					4'd11: o_data_w = 4'd12;
					4'd12: o_data_w = 4'd5;
					4'd13: o_data_w = 4'd10;
					4'd14: o_data_w = 4'd14;
					4'd15: o_data_w = 4'd7;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd1;
					4'd1: o_data_w = 4'd10;
					4'd2: o_data_w = 4'd13;
					4'd3: o_data_w = 4'd0;
					4'd4: o_data_w = 4'd6;
					4'd5: o_data_w = 4'd9;
					4'd6: o_data_w = 4'd8;
					4'd7: o_data_w = 4'd7;
					4'd8: o_data_w = 4'd4;
					4'd9: o_data_w = 4'd15;
					4'd10: o_data_w = 4'd14;
					4'd11: o_data_w = 4'd3;
					4'd12: o_data_w = 4'd11;
					4'd13: o_data_w = 4'd5;
					4'd14: o_data_w = 4'd2;
					4'd15: o_data_w = 4'd12;
				endcase
			end
		endcase
        valid_w = 1;	
    end
end

endmodule

module S_BOX_2
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd15;
					4'd1: o_data_w = 4'd1;
					4'd2: o_data_w = 4'd8;
					4'd3: o_data_w = 4'd14;
					4'd4: o_data_w = 4'd6;
					4'd5: o_data_w = 4'd11;
					4'd6: o_data_w = 4'd3;
					4'd7: o_data_w = 4'd4;
					4'd8: o_data_w = 4'd9;
					4'd9: o_data_w = 4'd7;
					4'd10: o_data_w = 4'd2;
					4'd11: o_data_w = 4'd13;
					4'd12: o_data_w = 4'd12;
					4'd13: o_data_w = 4'd0;
					4'd14: o_data_w = 4'd5;
					4'd15: o_data_w = 4'd10;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd3;
					4'd1: o_data_w = 4'd13;
					4'd2: o_data_w = 4'd4;
					4'd3: o_data_w = 4'd7;
					4'd4: o_data_w = 4'd15;
					4'd5: o_data_w = 4'd2;
					4'd6: o_data_w = 4'd8;
					4'd7: o_data_w = 4'd14;
					4'd8: o_data_w = 4'd12;
					4'd9: o_data_w = 4'd0;
					4'd10: o_data_w = 4'd1;
					4'd11: o_data_w = 4'd10;
					4'd12: o_data_w = 4'd6;
					4'd13: o_data_w = 4'd9;
					4'd14: o_data_w = 4'd11;
					4'd15: o_data_w = 4'd5;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd0;
					4'd1: o_data_w = 4'd14;
					4'd2: o_data_w = 4'd7;
					4'd3: o_data_w = 4'd11;
					4'd4: o_data_w = 4'd10;
					4'd5: o_data_w = 4'd4;
					4'd6: o_data_w = 4'd13;
					4'd7: o_data_w = 4'd1;
					4'd8: o_data_w = 4'd5;
					4'd9: o_data_w = 4'd8;
					4'd10: o_data_w = 4'd12;
					4'd11: o_data_w = 4'd6;
					4'd12: o_data_w = 4'd9;
					4'd13: o_data_w = 4'd3;
					4'd14: o_data_w = 4'd2;
					4'd15: o_data_w = 4'd15;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd13;
					4'd1: o_data_w = 4'd8;
					4'd2: o_data_w = 4'd10;
					4'd3: o_data_w = 4'd1;
					4'd4: o_data_w = 4'd3;
					4'd5: o_data_w = 4'd15;
					4'd6: o_data_w = 4'd4;
					4'd7: o_data_w = 4'd2;
					4'd8: o_data_w = 4'd11;
					4'd9: o_data_w = 4'd6;
					4'd10: o_data_w = 4'd7;
					4'd11: o_data_w = 4'd12;
					4'd12: o_data_w = 4'd0;
					4'd13: o_data_w = 4'd5;
					4'd14: o_data_w = 4'd14;
					4'd15: o_data_w = 4'd9;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule

module S_BOX_1
(
	input enable,
    output valid,
	input  [5 : 0] i_data,
	output [3 : 0] o_data
);

reg [3 : 0] o_data_w;
reg valid_w;



assign valid = valid_w;
assign o_data = o_data_w;

always @ (*)
begin
	o_data_w = 0;
    valid_w = 0;
	if (enable)
	begin
		case ({i_data[5], i_data[0]})
			2'b00: // 0yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd14;
					4'd1: o_data_w = 4'd4;
					4'd2: o_data_w = 4'd13;
					4'd3: o_data_w = 4'd1;
					4'd4: o_data_w = 4'd2;
					4'd5: o_data_w = 4'd15;
					4'd6: o_data_w = 4'd11;
					4'd7: o_data_w = 4'd8;
					4'd8: o_data_w = 4'd3;
					4'd9: o_data_w = 4'd10;
					4'd10: o_data_w = 4'd6;
					4'd11: o_data_w = 4'd12;
					4'd12: o_data_w = 4'd5;
					4'd13: o_data_w = 4'd9;
					4'd14: o_data_w = 4'd0;
					4'd15: o_data_w = 4'd7;
				endcase
			end
			2'b01: // 0yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd0;
					4'd1: o_data_w = 4'd15;
					4'd2: o_data_w = 4'd7;
					4'd3: o_data_w = 4'd4;
					4'd4: o_data_w = 4'd14;
					4'd5: o_data_w = 4'd2;
					4'd6: o_data_w = 4'd13;
					4'd7: o_data_w = 4'd1;
					4'd8: o_data_w = 4'd10;
					4'd9: o_data_w = 4'd6;
					4'd10: o_data_w = 4'd12;
					4'd11: o_data_w = 4'd11;
					4'd12: o_data_w = 4'd9;
					4'd13: o_data_w = 4'd5;
					4'd14: o_data_w = 4'd3;
					4'd15: o_data_w = 4'd8;
				endcase
			end
			2'b10: // 1yyyy0
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd4;
					4'd1: o_data_w = 4'd1;
					4'd2: o_data_w = 4'd14;
					4'd3: o_data_w = 4'd8;
					4'd4: o_data_w = 4'd13;
					4'd5: o_data_w = 4'd6;
					4'd6: o_data_w = 4'd2;
					4'd7: o_data_w = 4'd11;
					4'd8: o_data_w = 4'd15;
					4'd9: o_data_w = 4'd12;
					4'd10: o_data_w = 4'd9;
					4'd11: o_data_w = 4'd7;
					4'd12: o_data_w = 4'd3;
					4'd13: o_data_w = 4'd10;
					4'd14: o_data_w = 4'd5;
					4'd15: o_data_w = 4'd0;
				endcase
			end
			2'b11: // 1yyyy1
			begin
				case (i_data[4 : 1])
					4'd0: o_data_w = 4'd15;
					4'd1: o_data_w = 4'd12;
					4'd2: o_data_w = 4'd8;
					4'd3: o_data_w = 4'd2;
					4'd4: o_data_w = 4'd4;
					4'd5: o_data_w = 4'd9;
					4'd6: o_data_w = 4'd1;
					4'd7: o_data_w = 4'd7;
					4'd8: o_data_w = 4'd5;
					4'd9: o_data_w = 4'd11;
					4'd10: o_data_w = 4'd3;
					4'd11: o_data_w = 4'd14;
					4'd12: o_data_w = 4'd10;
					4'd13: o_data_w = 4'd0;
					4'd14: o_data_w = 4'd6;
					4'd15: o_data_w = 4'd13;
				endcase
			end
		endcase
        valid_w = 1;
	end
end

endmodule