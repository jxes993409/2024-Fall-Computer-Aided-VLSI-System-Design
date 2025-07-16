`define FUNC_AUTOMATIC automatic

module core #( // DO NOT MODIFY INTERFACE!!!
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32
) (
	input i_clk,
	input i_rst_n,

	// Testbench IOs
	output [2 : 0] o_status,
	output         o_status_valid,

	// Memory IOs
	output [ADDR_WIDTH - 1 : 0] o_addr,
	output [DATA_WIDTH - 1 : 0] o_wdata,
	output                      o_we,
	input  [DATA_WIDTH - 1 : 0] i_rdata
);
	// ---------------------------------------------------------------------------
	// Local Parameters
	// ---------------------------------------------------------------------------
	localparam        IDLE = 4'd0;
	localparam  INST_FETCH = 4'd1;
	localparam INST_DECODE = 4'd2;
	localparam         ALU = 4'd3;
	localparam  WRITE_BACK = 4'd4;
	localparam     NEXT_PC = 4'd5;
	localparam PROCESS_END = 4'd6;

	// ---------------------------------------------------------------------------
	// Wires and Registers
	// ---------------------------------------------------------------------------
	// ---- Add your own wires and registers here if needed ---- //
	reg [2 : 0] o_status_r;
	reg [2 : 0] o_status_w;

	reg [ADDR_WIDTH - 1 : 0] o_addr_w;
	reg [DATA_WIDTH - 1 : 0] o_wdata_w;
	reg                      o_we_w;

	reg [ADDR_WIDTH - 1 : 0] o_addr_r;
	reg [DATA_WIDTH - 1 : 0] o_wdata_r;
	reg                      o_we_r;

	reg [ADDR_WIDTH - 1 : 0] pc;

	reg [3 : 0] current_state;
	reg [3 : 0] next_state;

	reg signed [DATA_WIDTH - 1 : 0] int_reg [31 : 0];
	reg signed [DATA_WIDTH - 1 : 0] flt_reg [31 : 0];

	reg signed [DATA_WIDTH - 1 : 0] r1_w;
	reg signed [DATA_WIDTH - 1 : 0] r2_w;
	reg signed [DATA_WIDTH - 1 : 0] rd_w;

	reg signed [DATA_WIDTH - 1 : 0] r1_r;
	reg signed [DATA_WIDTH - 1 : 0] r2_r;
	reg signed [DATA_WIDTH - 1 : 0] rd_r;

	reg [4 : 0] r1_index_w;
	reg [4 : 0] r2_index_w;
	reg [4 : 0] rd_index_w;

	reg [4 : 0] r1_index_r;
	reg [4 : 0] r2_index_r;
	reg [4 : 0] rd_index_r;

	reg signed [12 : 0] imm_w;
	reg signed [12 : 0] imm_r;
	reg signed [DATA_WIDTH - 1 : 0] imm_expand_w;

	reg [6 : 0] opcode_w;
	reg [6 : 0] funct7_w;
	reg [2 : 0] funct3_w;
	reg [3 : 0] inst_type_w;

	reg [6 : 0] opcode_r;
	reg [6 : 0] funct7_r;
	reg [2 : 0] funct3_r;
	reg [3 : 0] inst_type_r;

	reg is_jump_w;
	reg is_invalid_w;

	reg fd_is_invalid_w;
	reg fi_is_invalid_w;

	reg is_jump_r;

	reg [4 : 0] f1_class_w;
	reg [4 : 0] f2_class_w;
	reg [4 : 0] fd_class_w;

	reg [ADDR_WIDTH - 1 : 0] o_addr_temp_w;

	integer i;

	// ---------------------------------------------------------------------------
	// Continuous Assignment
	// ---------------------------------------------------------------------------
	// ---- Add your own wire data assignments here if needed ---- //

	assign 	     o_status = o_status_r;
	assign o_status_valid = (current_state == NEXT_PC && inst_type_r != `INVALID_TYPE) ? 1 : 0;
	assign         o_addr = (current_state == ALU &&
							({funct3_r, opcode_r} == {`FUNCT3_LW, `OP_LW} || {funct3_r, opcode_r} == {`FUNCT3_FLW, `OP_FLW})) ?
							o_addr_w : o_addr_r;
	assign        o_wdata = o_wdata_w;
	assign           o_we = o_we_w;

	// ---------------------------------------------------------------------------
	// Combinational Blocks
	// ---------------------------------------------------------------------------
	// ---- Write your conbinational block design here ---- //
	always @ (*)
	begin
		 o_addr_w = 0;
		o_wdata_w = 0;
		   o_we_w = 0;

		r1_index_w = 0;
		r2_index_w = 0;
		rd_index_w = 0;

		r1_w = 0;
		r2_w = 0;
		rd_w = 0;

		imm_w = 0;
		imm_expand_w = 0;

		opcode_w = 0;
		funct7_w = 0;
		funct3_w = 0;

		inst_type_w = 0;

		is_jump_w = 0;
		is_invalid_w = 0;

		o_status_w = 0;

		f1_class_w = 0;
		f2_class_w = 0;
		fd_class_w = 0;

		fi_is_invalid_w = 0;
		fd_is_invalid_w = 0;

		o_addr_temp_w = 0;

		case (current_state)
			IDLE:
			begin
				o_addr_w = pc;
			end
			INST_FETCH:
			begin
				o_addr_w = pc;
			end
			INST_DECODE:
			begin
				o_addr_w = pc;
				opcode_w = i_rdata[6 : 0];
				funct7_w = i_rdata[31: 25];
				funct3_w = i_rdata[14: 12];

				r1_index_w = i_rdata[19 : 15];
				r2_index_w = i_rdata[24 : 20];
				rd_index_w = i_rdata[11 : 7];


				case (opcode_w)
					// ADD, SUB, SLT, SLL, SRL, FADD, FSUB, FCLASS, FLT
					`OP_ADD, `OP_FADD: 
						inst_type_w = `R_TYPE;

					// ADDI, LW, FLW
					`OP_ADDI, `OP_LW, `OP_FLW:
						inst_type_w = `I_TYPE;

					// SW, FSW
					`OP_SW, `OP_FSW:
						inst_type_w = `S_TYPE;

					// BEQ, BLT
					`OP_BEQ:
						inst_type_w = `B_TYPE;

					// EOF
					`OP_EOF:
						inst_type_w = `EOF_TYPE;

					default:
						inst_type_w = `INVALID_TYPE;
				endcase

				case (inst_type_w)
					`I_TYPE:
					begin
						imm_w = {{1{i_rdata[31]}}, i_rdata[31 : 20]};
					end
					`S_TYPE:
					begin
						imm_w = {{1{i_rdata[31]}}, i_rdata[31 : 25], i_rdata[11 : 7]};
					end
					`B_TYPE:
					begin
						imm_w = {i_rdata[31], i_rdata[7], i_rdata[30 : 25], i_rdata[11 : 8], 1'b0};
					end
				endcase

				case (inst_type_w)
					`R_TYPE:
					begin
						case (opcode_w)
							// ADD, SUB, SLT, SLL, SRL
							`OP_ADD:
							begin
								r1_w = int_reg[r1_index_w];
								r2_w = int_reg[r2_index_w];
							end
							// FADD, FSUB, FLT, FCLASS
							`OP_FADD:
							begin
								r1_w = flt_reg[r1_index_w];
								r2_w = flt_reg[r2_index_w];
							end
						endcase
					end

					// ADDI, LW, FLW
					`I_TYPE:
					begin
						r1_w = int_reg[r1_index_w];
					end

					// SW, FSW
					`S_TYPE:
					begin
						case (opcode_w)
							`OP_SW:
							begin
								r1_w = int_reg[r1_index_w];
								r2_w = int_reg[r2_index_w];
							end
							`OP_FSW:
							begin
								r1_w = int_reg[r1_index_w];
								r2_w = flt_reg[r2_index_w];
							end
						endcase
					end

					// BEQ, BLT
					`B_TYPE:
					begin
						r1_w = int_reg[r1_index_w];
						r2_w = int_reg[r2_index_w];
					end
				endcase
			end
			ALU:
			begin
				o_addr_w = pc;
				
				case (inst_type_r)
					`R_TYPE:
					begin
						case({funct7_r, funct3_r, opcode_r})
							{`FUNCT7_ADD, `FUNCT3_ADD, `OP_ADD}:
							begin
								rd_w = r1_r + r2_r;
								is_invalid_w = (r1_r[31] & r2_r[31] & ~rd_w[31]) || (~r1_r[31] & ~r2_r[31] & rd_w[31]);
							end
							{`FUNCT7_SUB, `FUNCT3_SUB, `OP_SUB}:
							begin
								rd_w = r1_r - r2_r;
								is_invalid_w = (r1_r[31] & ~r2_r[31] & ~rd_w[31]) || (~r1_r[31] & r2_r[31] & rd_w[31]);
							end
							{`FUNCT7_SLT, `FUNCT3_SLT, `OP_SLT}:
							begin
								rd_w = {{(DATA_WIDTH - 1){1'b0}}, (r1_r < r2_r)};
							end
							{`FUNCT7_SLL, `FUNCT3_SLL, `OP_SLL}:
							begin
								rd_w = (r1_r << r2_r);
							end
							{`FUNCT7_SRL, `FUNCT3_SRL, `OP_SRL}:
							begin
								rd_w = (r1_r >> r2_r);
							end
							{`FUNCT7_FADD, `FUNCT3_FADD, `OP_FADD}:
							begin
								f1_class_w = fclass(r1_r);
								f2_class_w = fclass(r2_r);
								fi_is_invalid_w = ((f1_class_w == 4'd8 || f1_class_w == 4'd7 || f1_class_w == 4'd0) ||
												   (f2_class_w == 4'd8 || f2_class_w == 4'd7 || f2_class_w == 4'd0));
								if (!fi_is_invalid_w)
								begin
									rd_w = fop(r1_r, r2_r, 0);
									fd_class_w = fclass(rd_w);
									fd_is_invalid_w = (fd_class_w == 4'd8 || fd_class_w == 4'd7 || fd_class_w == 4'd0);
								end
								is_invalid_w = (fi_is_invalid_w || fd_is_invalid_w);
							end
							{`FUNCT7_FSUB, `FUNCT3_FSUB, `OP_FSUB}:
							begin
								f1_class_w = fclass(r1_r);
								f2_class_w = fclass(r2_r);
								fi_is_invalid_w = ((f1_class_w == 4'd8 || f1_class_w == 4'd7 || f1_class_w == 4'd0) ||
												   (f2_class_w == 4'd8 || f2_class_w == 4'd7 || f2_class_w == 4'd0));
								if (!fi_is_invalid_w)
								begin
									rd_w = fop(r1_r, r2_r, 1);
									fd_class_w = fclass(rd_w);
									fd_is_invalid_w = (fd_class_w == 4'd8 || fd_class_w == 4'd7 || fd_class_w == 4'd0);
								end
								is_invalid_w = (fi_is_invalid_w || fd_is_invalid_w);
							end
							{`FUNCT7_FCLASS, `FUNCT3_FCLASS, `OP_FCLASS}:
							begin
								rd_w = {28'b0, fclass(r1_r)};
							end
							{`FUNCT7_FLT, `FUNCT3_FLT, `OP_FLT}:
							begin
								f1_class_w = fclass(r1_r);
								f2_class_w = fclass(r2_r);
								is_invalid_w = ((f1_class_w == 4'd8 || f1_class_w == 4'd7 || f1_class_w == 4'd0) ||
												(f2_class_w == 4'd8 || f2_class_w == 4'd7 || f2_class_w == 4'd0));
								if (!is_invalid_w)
								begin
									rd_w = {31'b0, flt(r1_r, r2_r)};
								end
							end
						endcase
					end
					`I_TYPE:
					begin
						case({funct3_r, opcode_r})
							{`FUNCT3_ADDI, `OP_ADDI}:
							begin
								imm_expand_w = (imm_r[12]) ? {{19{1'b1}}, imm_r} : {19'b0, imm_r};
								rd_w = r1_r + imm_expand_w;
								is_invalid_w = (r1_r[31] & imm_expand_w[31] & ~rd_w[31]) || (~r1_r[31] & ~imm_expand_w[31] & rd_w[31]);
							end
							{`FUNCT3_LW, `OP_LW}, {`FUNCT3_FLW, `OP_FLW}:
							begin
								o_addr_temp_w = r1_r + imm_r;
								is_invalid_w = (o_addr_temp_w < 32'd4096 || o_addr_temp_w > 32'd8191);
								if (!is_invalid_w)
								begin
									o_addr_w = o_addr_temp_w;
								end
							end
						endcase
					end
					`B_TYPE:
					begin
						case({funct3_r, opcode_r})
							{`FUNCT3_BEQ, `OP_BEQ}:
							begin
								if (r1_r == r2_r)
								begin
									o_addr_temp_w = pc + imm_r;
									is_invalid_w = (o_addr_temp_w > 32'd4095);
									is_jump_w = 1;
								end
							end
							{`FUNCT3_BLT, `OP_BLT}:
							begin
								if (r1_r < r2_r)
								begin
									o_addr_temp_w = pc + imm_r;
									is_invalid_w = (o_addr_temp_w > 32'd4095);
									is_jump_w = 1;
								end
							end
						endcase
					end
					`S_TYPE:
					begin
						o_addr_temp_w = r1_r + imm_r;
						is_invalid_w = (o_addr_temp_w < 32'd4096 || o_addr_temp_w > 32'd8191);
						if (!is_invalid_w)
						begin
							o_addr_w = o_addr_temp_w;
						end
					end
				endcase

				o_status_w = (is_invalid_w) ? `INVALID_TYPE : inst_type_r;
			end
			WRITE_BACK:
			begin
				o_addr_w = pc;
				if (opcode_r == `OP_SW || opcode_r ==`OP_FSW)
				begin
					o_we_w = 1;
					o_wdata_w = r2_r;
				end
			end
			NEXT_PC:
			begin
				o_addr_w = pc;
			end
			default:
			begin
			end
		endcase
	end

	// ---------------------------------------------------------------------------
	// Sequential Block
	// ---------------------------------------------------------------------------
	// ---- Write your sequential block design here ---- //

	// o_status_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			o_status_r <= 0;
		end
		else
		begin
			if (current_state == ALU)
			begin
				o_status_r <= o_status_w;
			end
			else
			begin
				o_status_r <= o_status_r;
			end
		end
	end

	// o_addr_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			o_addr_r <= 0;
		end
		else
		begin
			if (current_state == ALU || current_state == IDLE)
			begin
				o_addr_r <= o_addr_w;
			end
			else
			begin
				o_addr_r <= o_addr_r;
			end
		end
	end

	// o_wdata_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			o_wdata_r <= 0;
		end
		else
		begin
			o_wdata_r <= o_wdata_r;
		end
	end

	// r1_r, r2_r, imm_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			 r1_r <= 0;
			 r2_r <= 0;
			imm_r <= 0;
		end
		else
		begin
			if (current_state == INST_DECODE)
			begin
				 r1_r <= r1_w;
				 r2_r <= r2_w;
				imm_r <= imm_w;
			end
			else
			begin
				 r1_r <= r1_r;
				 r2_r <= r2_r;
				imm_r <= imm_r;
			end
		end
	end

	// rd_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			rd_r <= 0;
		end
		else
		begin
			if (current_state == ALU)
			begin
				rd_r <= rd_w;
			end
			else
			begin
				rd_r <= rd_r;
			end
		end
	end

	// is_jump_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			is_jump_r <= 0;
		end
		else
		begin
			if (current_state == ALU)
			begin
				is_jump_r <= is_jump_w;
			end
			else
			begin
				is_jump_r <= is_jump_r;
			end
		end
	end

	// pc
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			pc <= 0;
		end
		else
		begin
			if (current_state == NEXT_PC)
			begin
				if (is_jump_r)
				begin
					pc <= pc + imm_r;
				end
				else
				begin
					pc <= pc + 4;
				end
			end
			else
			begin
				pc <= pc;
			end
		end
	end

	// int_reg
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			for (i = 0; i < 32; i = i + 1)
			begin
				int_reg[i] <= 0;
			end
		end
		else
		begin
			for (i = 0; i < 32; i = i + 1)
			begin
				int_reg[i] <= int_reg[i];
				if (current_state == WRITE_BACK && i == rd_index_r)
				begin
					if (opcode_r == `OP_ADD ||
						opcode_r == `OP_ADDI ||
						{funct7_r, opcode_r} == {`FUNCT7_FLT, `OP_FLT} ||
						{funct7_r, opcode_r} == {`FUNCT7_FCLASS, `OP_FCLASS})
					begin
						int_reg[i] <= rd_r;
					end
					else if (opcode_r == `OP_LW)
					begin
						int_reg[i] <= i_rdata;
					end
				end
			end
		end
	end

	// flt_reg
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			for (i = 0; i < 32; i = i + 1)
			begin
				flt_reg[i] <= 0;
			end
		end
		else
		begin
			for (i = 0; i < 32; i = i + 1)
			begin
				flt_reg[i] <= flt_reg[i];
				if (current_state == WRITE_BACK && i == rd_index_r)
				begin
					if ({funct7_r, opcode_r} == {`FUNCT7_FADD, `OP_FADD} ||
						{funct7_r, opcode_r} == {`FUNCT7_FSUB, `OP_FSUB})
					begin
						flt_reg[i] <= rd_r;
					end
					else if (opcode_r == `OP_FLW)
					begin
						flt_reg[i] <= i_rdata;
					end
				end
			end
		end
	end

	// reg_index
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			r1_index_r <= 0;
			r2_index_r <= 0;
			rd_index_r <= 0;
		end
		else
		begin
			if (current_state == INST_DECODE)
			begin
				r1_index_r <= r1_index_w;
				r2_index_r <= r2_index_w;
				rd_index_r <= rd_index_w;
			end
			else
			begin
				r1_index_r <= r1_index_r;
				r2_index_r <= r2_index_r;
				rd_index_r <= rd_index_r;
			end
		end
	end

	// opcode_r, funct3_r, funct7_r, inst_type_r
	always @ (posedge i_clk or negedge i_rst_n)
	begin
		if (!i_rst_n)
		begin
			   opcode_r <= 0;
			   funct7_r <= 0;
			   funct3_r <= 0;
			inst_type_r <= 0;
		end
		else
		begin
			if (current_state == INST_DECODE)
			begin
				   opcode_r <= opcode_w;
				   funct7_r <= funct7_w;
				   funct3_r <= funct3_w;
				inst_type_r <= inst_type_w;
			end
			else
			begin
				   opcode_r <= opcode_r;
				   funct7_r <= funct7_r;
				   funct3_r <= funct3_r;
				inst_type_r <= inst_type_r;
			end
		end
	end


	// FSM
	// CS
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
	// NS
	always @ (*)
	begin
		case (current_state)
			IDLE:
			begin
				if (inst_type_r == `EOF_TYPE || inst_type_r == `INVALID_TYPE)
				begin
					next_state = IDLE;
				end
				else
				begin
					next_state = INST_FETCH;
				end
			end
			INST_FETCH:  next_state = INST_DECODE;
			INST_DECODE: next_state = ALU;
			ALU:
			begin
				if (o_status_w == `INVALID_TYPE)
				begin
					next_state = NEXT_PC;
				end
				else
				begin
					next_state = WRITE_BACK;
				end
			end
			WRITE_BACK:	 next_state = NEXT_PC;
			NEXT_PC:	 next_state = IDLE;
			default:     next_state = IDLE;
		endcase
	end

	function automatic [DATA_WIDTH - 1 : 0] fop;
		input [DATA_WIDTH - 1 : 0] r1;
		input [DATA_WIDTH - 1 : 0] r2;
		input                      op;

		reg r1_signed;
		reg r2_signed;
		reg fop_signed;

		reg [7 : 0] r1_exp;
		reg [7 : 0] r2_exp;
		reg [7 : 0] fop_exp_stage_1; // exponent shift
		reg [7 : 0] fop_exp_stage_2; // normalize
		reg [7 : 0] fop_exp_stage_3; // shift exponent after rounding

		reg [277 : 0] r1_mantissa;
		reg [277 : 0] r2_mantissa;
		reg [277 : 0] r1_mantissa_shifted;
		reg [277 : 0] r2_mantissa_shifted;
		reg [277 : 0] fop_mantissa_stage_1; // add
		reg [277 : 0] fop_mantissa_stage_1_shifted;
		reg [276 : 0] fop_mantissa_stage_2; // normalize
		reg [276 : 0] fop_mantissa_stage_3; // rounding
		reg [276 : 0] fop_mantissa_stage_4; // shift exponent after rounding

		reg [7 : 0] shifted_exp;

		reg [8 : 0] leading_zero_stage_1;
		reg [8 : 0] leading_zero_stage_2;
		reg sticky_bit;
		begin
			r1_signed = r1[31];
			r2_signed = r2[31];

			r1_exp = r1[30 : 23];
			r2_exp = r2[30 : 23];

			r1_mantissa = (r1_exp == 0) ? {2'b00, r1[22 : 0], 253'b0} : {2'b01, r1[22 : 0], 253'b0};
			r2_mantissa = (r2_exp == 0) ? {2'b00, r2[22 : 0], 253'b0} : {2'b01, r2[22 : 0], 253'b0};

			// exponent shift
			if (r1_exp > r2_exp)
			begin
				shifted_exp = r1_exp - r2_exp;
				fop_exp_stage_1 = r1_exp;
				r1_mantissa_shifted = r1_mantissa;
				if (r1_exp != 0 && r2_exp == 0)
				begin
					r2_mantissa_shifted = r2_mantissa >> (shifted_exp - 1);
				end
				else
				begin
					r2_mantissa_shifted = r2_mantissa >> shifted_exp;
				end
			end
			else
			begin
				shifted_exp = r2_exp - r1_exp;
				fop_exp_stage_1 = r2_exp;
				r2_mantissa_shifted = r2_mantissa;
				if (r1_exp == 0 && r2_exp != 0)
				begin
					r1_mantissa_shifted = r1_mantissa >> (shifted_exp - 1);
				end
				else
				begin
					r1_mantissa_shifted = r1_mantissa >> shifted_exp;
				end
			end

			// add
			case (op)
				1'b0:
				begin
					case({r1_signed, r2_signed})
						2'b11, 2'b00:
						begin
							fop_mantissa_stage_1 = r1_mantissa_shifted + r2_mantissa_shifted;
							fop_signed = r1_signed;
						end
						2'b01, 2'b10:
						begin
							if (r1_mantissa_shifted > r2_mantissa_shifted)
							begin
								fop_mantissa_stage_1 = r1_mantissa_shifted - r2_mantissa_shifted;
								fop_signed = r1_signed;
							end
							else
							begin
								fop_mantissa_stage_1 = r2_mantissa_shifted - r1_mantissa_shifted;
								fop_signed = r2_signed;
							end
						end
					endcase
				end
				1'b1:
				begin
					case({r1_signed, r2_signed})
						2'b01, 2'b10:
						begin
							fop_mantissa_stage_1 = r1_mantissa_shifted + r2_mantissa_shifted;
							fop_signed = r1_signed;
						end
						2'b11, 2'b00:
						begin
							if (r1_mantissa_shifted > r2_mantissa_shifted)
							begin
								fop_mantissa_stage_1 = r1_mantissa_shifted - r2_mantissa_shifted;
								fop_signed = r1_signed;
							end
							else
							begin
								fop_mantissa_stage_1 = r2_mantissa_shifted - r1_mantissa_shifted;
								fop_signed = !r1_signed;
							end
						end
					endcase
				end
			endcase

			// normalize
			// subnormal situation
			if (r1_exp == 0 && r2_exp == 0)
			begin
				fop_exp_stage_2 = fop_exp_stage_1 + fop_mantissa_stage_1[276];
				fop_mantissa_stage_2 = {1'b0, fop_mantissa_stage_1[275 : 0]};
			end
			// integer part = 10.xxx or 11.xxx
			else if (fop_mantissa_stage_1[277])
			begin
				fop_exp_stage_2 = fop_exp_stage_1 + 1;
				fop_mantissa_stage_1_shifted = fop_mantissa_stage_1 >> 1;
				fop_mantissa_stage_2 = {1'b0, fop_mantissa_stage_1_shifted[275 : 0]};
			end
			// integer part = 01.xxx
			else if (fop_mantissa_stage_1[276])
			begin
				fop_exp_stage_2 = fop_exp_stage_1;
				fop_mantissa_stage_2 = {1'b0, fop_mantissa_stage_1[275 : 0]};
			end
			// integer part = 00.xxx
			else
			begin
				leading_zero_stage_1 = cnt_leading_zero(fop_mantissa_stage_1[275 : 0]) + 1;
				if (leading_zero_stage_1 > {1'b0, fop_exp_stage_1})
				begin
					leading_zero_stage_2 = (r1_exp != 0 && r2_exp != 0);
					fop_exp_stage_2 = 0;
				end
				else if (leading_zero_stage_1 == {1'b0, fop_exp_stage_1})
				begin
					leading_zero_stage_2 = leading_zero_stage_1 - 1;
					fop_exp_stage_2 = 0;
				end
				else
				begin
					leading_zero_stage_2 = leading_zero_stage_1;
					fop_exp_stage_2 = {1'b0, fop_exp_stage_1} - leading_zero_stage_1;
				end
				fop_mantissa_stage_1_shifted = fop_mantissa_stage_1 << leading_zero_stage_2;
				fop_mantissa_stage_2 = {1'b0, fop_mantissa_stage_1_shifted[275 : 0]};
			end

			// rounding
			if (fop_mantissa_stage_2[252])
			begin
				sticky_bit = |fop_mantissa_stage_2[251 : 0];
				if (sticky_bit)
				begin
					fop_mantissa_stage_3 = fop_mantissa_stage_2 + {1'b1, 252'b0};
				end
				else
				begin
					if (fop_mantissa_stage_2[253])
					begin
						fop_mantissa_stage_3 = fop_mantissa_stage_2 + {1'b1, 252'b0};
					end
					else
					begin
						fop_mantissa_stage_3 = fop_mantissa_stage_2;
					end
				end
			end
			else
			begin
				fop_mantissa_stage_3 = fop_mantissa_stage_2;
			end

			// shift exponent after rounding
			if (fop_mantissa_stage_3[276])
			begin
				fop_exp_stage_3 = fop_exp_stage_2 + 1;
				fop_mantissa_stage_4 = {2'b0, fop_mantissa_stage_3[275 : 1]};
			end
			else
			begin
				fop_exp_stage_3 = fop_exp_stage_2;
				fop_mantissa_stage_4 = fop_mantissa_stage_3;
			end

			fop = (fop_exp_stage_3 == 0 && fop_mantissa_stage_4 == 0) ?
				  32'b0 :
				  {fop_signed, fop_exp_stage_3, fop_mantissa_stage_4[275 : 253]};
		end
	endfunction

	function automatic [4 : 0] fclass;
		input [DATA_WIDTH - 1 : 0] flt;

		reg flt_signed;
		reg [7 : 0] flt_exp;
		reg [22 : 0] flt_mantissa;
		begin
			flt_signed = flt[31];
			flt_exp = flt[30 : 23];
			flt_mantissa = flt[22 : 0];

			// normal number
			if (flt_exp > 8'd0 && flt_exp < 8'd255)
			begin
				// negative normal
				if (flt_signed)
				begin
					fclass = 1;
				end
				// positive normal
				else
				begin
					fclass = 6;
				end
			end
			// subnormal
			else if (flt_exp == 8'd0 && flt_mantissa != 23'd0)
			begin
				// negative subnormal
				if (flt_signed)
				begin
					fclass = 2;
				end
				// positive subnormal
				else
				begin
					fclass = 5;
				end
			end
			// zero
			else if (flt_exp == 8'd0 && flt_mantissa == 23'd0)
			begin
				// negative zero
				if (flt_signed)
				begin
					fclass = 3;
				end
				// positive zero
				else
				begin
					fclass = 4;
				end
			end
			// inf
			else if (flt_exp == 8'd255 && flt_mantissa == 23'd0)
			begin
				// negative inf
				if (flt_signed)
				begin
					fclass = 0;
				end
				// positive inf
				else
				begin
					fclass = 7;
				end
			end
			// nan
			else
			begin
				fclass = 8;
			end
		end
	endfunction

	function automatic flt;
		input [DATA_WIDTH - 1 : 0] r1;
		input [DATA_WIDTH - 1 : 0] r2;

		reg r1_signed;
		reg r2_signed;

		reg [7 : 0] r1_exp;
		reg [7 : 0] r2_exp;

		reg [22 : 0] r1_mantissa;
		reg [22 : 0] r2_mantissa;
		begin
			r1_signed = r1[31];
			r2_signed = r2[31];

			r1_exp = r1[30 : 23];
			r2_exp = r2[30 : 23];

			r1_mantissa = r1[22 : 0];
			r2_mantissa = r2[22 : 0];
			case ({r1_signed, r2_signed})
				2'b00:
				begin
					if (r1_exp > r2_exp)
					begin
						flt = 0;
					end
					else if (r1_exp == r2_exp)
					begin
						flt = (r1_mantissa < r2_mantissa);
					end
					else
					begin
						flt = 1;
					end
				end
				2'b01:
				begin
					flt = 0;
				end
				2'b10:
				begin
					flt = 1;
				end
				2'b11:
				begin
					if (r1_exp > r2_exp)
					begin
						flt = 1;
					end
					else if (r1_exp == r2_exp)
					begin
						flt = (r1_mantissa > r2_mantissa);
					end
					else
					begin
						flt = 0;
					end
				end
			endcase
		end
	endfunction

	function automatic [8 : 0] cnt_leading_zero;
		input [275 : 0] a;
		reg [8 : 0] leading_one;
		integer i;
		begin
			leading_one = 0;
			for (i = 275; i > 0; i = i - 1)
			begin
				if (a[i] && i > leading_one)
				begin
					leading_one = i;
				end
			end
			cnt_leading_zero = 276 - 1 - leading_one;
		end
	endfunction

endmodule