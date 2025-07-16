`timescale 1ns/1ps
`define CYCLE       5.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   2


`ifdef tb1
	`define INFILE "../00_TESTBED/PATTERN/indata1.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
	`define OP_NUM 41
	`define GOLD_NUM 80
`elsif tb2
	`define INFILE "../00_TESTBED/PATTERN/indata2.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
	`define OP_NUM 41
	`define GOLD_NUM 320
`elsif tb3
	`define INFILE "../00_TESTBED/PATTERN/indata3.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
	`define OP_NUM 41
	`define GOLD_NUM 320
`elsif tb4
	`define INFILE "../00_TESTBED/PATTERN/indata4.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode4.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden4.dat"
	`define OP_NUM 121
	`define GOLD_NUM 708
`elsif tb5
	`define INFILE "../00_TESTBED/PATTERN/indata5.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode5.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden5.dat"
	`define OP_NUM 98
	`define GOLD_NUM 6272
`elsif tb6
	`define INFILE "../00_TESTBED/PATTERN/indata6.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode6.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden6.dat"
	`define OP_NUM 99
	`define GOLD_NUM 3136
`elsif tb7
	`define INFILE "../00_TESTBED/PATTERN/indata7.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode7.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden7.dat"
	`define OP_NUM 100
	`define GOLD_NUM 1568
`elsif tb8
	`define INFILE "../00_TESTBED/PATTERN/indata8.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode8.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden8.dat"
	`define OP_NUM 98
	`define GOLD_NUM 196
`elsif tb9
	`define INFILE "../00_TESTBED/PATTERN/indata9.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode9.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden9.dat"
	`define OP_NUM 98
	`define GOLD_NUM 196
`elsif tb10
	`define INFILE "../00_TESTBED/PATTERN/indata10.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode10.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden10.dat"
	`define OP_NUM 99
	`define GOLD_NUM 196
`elsif tb11
	`define INFILE "../00_TESTBED/PATTERN/indata11.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode11.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden11.dat"
	`define OP_NUM 100
	`define GOLD_NUM 196
`elsif tb12
	`define INFILE "../00_TESTBED/PATTERN/indata12.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode12.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden12.dat"
	`define OP_NUM 98
	`define GOLD_NUM 784
`elsif tb13
	`define INFILE "../00_TESTBED/PATTERN/indata13.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode13.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden13.dat"
	`define OP_NUM 98
	`define GOLD_NUM 784
`elsif tb14
	`define INFILE "../00_TESTBED/PATTERN/indata14.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode14.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden14.dat"
	`define OP_NUM 202
	`define GOLD_NUM 2864
`elsif tb15
	`define INFILE "../00_TESTBED/PATTERN/indata15.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode15.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden15.dat"
	`define OP_NUM 602
	`define GOLD_NUM 3652
`elsif tbh
	`define INFILE "../00_TESTBED/PATTERN/indatah.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmodeh.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/goldenh.dat"
	`define OP_NUM 501
	`define GOLD_NUM 2848
`else
	`define INFILE "../00_TESTBED/PATTERN/indata0.dat"
	`define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
	`define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
	`define OP_NUM 41
	`define GOLD_NUM 1984
`endif

// Modify your sdf file name
`define SDFFILE "../02_SYN/Netlist/core_pr.sdf"


module testbed;

reg         clk, rst_n;
wire        op_ready;
wire        in_ready;
wire        out_valid;
wire [13:0] out_data;

reg        op_valid;
reg [ 3:0] op_mode;
reg        in_valid;
reg [ 7:0] in_data;

reg  [ 7:0] indata_mem [0:2047];
reg  [ 3:0] opmode_mem [0:1023];
reg  [13:0] golden_mem [0:8192];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
integer i, j, k;
integer error;


// For gate-level simulation only
`ifdef SDF
	initial $sdf_annotate(`SDFFILE, u_core);
	initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("core.fsdb");
  $fsdbDumpvars(0, "+mda");
end


core u_core (
	.i_clk       (clk),
	.i_rst_n     (rst_n),
	.i_op_valid  (op_valid),
	.i_op_mode   (op_mode),
	.o_op_ready  (op_ready),
	.i_in_valid  (in_valid),
	.i_in_data   (in_data),
	.o_in_ready  (in_ready),
	.o_out_valid (out_valid),
	.o_out_data  (out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

// Clock generation
initial clk = 1'b0;
always
begin
	#(`HCYCLE) clk = ~clk;
end

initial
begin
	i = 0;
	j = 0;
	k = 0;
	error = 0;

	in_valid = 0;
	in_data = 0;
	op_mode = 0;
	op_valid = 0;

	@(negedge clk);
	// load image
	while (op_ready == 1'b0)
	begin
		@(negedge clk);
	end
	@(negedge clk);
	op_valid  =  1'b1;
	op_mode   =  4'b0;

	@(negedge clk);
	if (op_ready && out_valid)
	begin
		$display ("Error! op_ready and out_valid are high!");
		$finish;
	end
	op_valid  = 1'b0;
	in_valid  = 1'b1;
	in_data   = indata_mem[k];

	while (k < 2047)
	begin
		@(negedge clk);
		if (in_ready == 1)
		begin
			k = k + 1;
			in_data = indata_mem[k];
		end
		if (op_ready && out_valid)
		begin
			$display ("Error! op_ready and out_valid are high!");
			$finish;
		end
	end

	@(negedge clk);
	in_valid  = 1'b0;
	in_data   = 0;

	while (i < `OP_NUM && j < `GOLD_NUM)
	begin
		@(negedge clk);
		if (in_valid && out_valid)
		begin
			$display ("Error! in_valid and out_valid are high!");
			$finish;
		end
		else if (op_valid && out_valid)
		begin
			$display ("Error! op_valid and out_valid are high!");
			$finish;
		end
		else if (in_valid && op_ready)
		begin
			$display ("Error! in_valid and op_ready are high!");
			$finish;
		end
		else if (op_valid && op_ready)
		begin
			$display ("Error! op_valid and op_ready are high!");
			$finish;
		end
		else if (op_ready && out_valid)
		begin
			$display ("Error! op_ready and out_valid are high!");
			$finish;
		end

		if (op_ready)
		begin
			@(negedge clk);
			i = i + 1;
			op_mode = opmode_mem[i];
			op_valid = 1;
		end

		if (op_valid)
		begin
			@(negedge clk);
			op_valid = 0;
			op_mode = 0;
		end

		if (out_valid)
		begin
			if (out_data !== golden_mem[j])
			begin
				$display("Test[%d]: Error! Golden=%d, Yours=%d", j, golden_mem[j], out_data);
				error = error + 1;
			end
			j = j + 1;
		end
	end

	if (error == 0 && j == `GOLD_NUM)
	begin
        $display("----------------------------------------------");
        $display("-                 ALL PASS!                  -");
        $display("----------------------------------------------");
    end
	else
	begin
        $display("----------------------------------------------");
        $display("  Wrong! Total error: %d                      ", error);
        $display("----------------------------------------------");
        $display("  Wrong! j: %8d, golden output: %8d           ", j, `GOLD_NUM);
        $display("----------------------------------------------");
    end
	$finish;
end

// Reset generation
initial begin
	rst_n = 1; # (               0.25 * `CYCLE);
	rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
	rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
	$display("Error! Runtime exceeded!");
	$finish;
end


// ==============================================
// TODO: Check pattern after process finish
// ==============================================

endmodule
