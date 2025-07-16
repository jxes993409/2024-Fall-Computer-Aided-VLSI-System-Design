`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000

`define PAT_NUM 4
`define times 4
`define DM_word(addr) u_data_mem.mem_r[addr]
`define DM_golden(addr) golden_IM_DM[addr]

`ifdef p0
	`define PATH "../00_TB/PATTERN_v3/p0/"
`elsif p1
	`define PATH "../00_TB/PATTERN_v3/p1/"
`elsif p2
	`define PATH "../00_TB/PATTERN_v3/p2/"
`elsif p3
	`define PATH "../00_TB/PATTERN_v3/p3/"
`else
	`define PATH "../00_TB/PATTERN_v3/p0/"
`endif

module testbed;

	reg  rst_n;
	reg  clk;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  2 : 0 ] mips_status;
	wire            mips_status_valid;

	reg [ 31 : 0 ]  golden_IM_DM [0 : 2048];
	reg [  2 : 0 ] golden_Status [0 : 1023];

	integer     IM_addr;
	integer     errorDM;
	integer errorStatus;

	core u_core (
		.i_clk			(clk),
		.i_rst_n		(rst_n),
		.o_status		(mips_status),
		.o_status_valid (mips_status_valid),
		.o_we			(dmem_we),
		.o_addr			(dmem_addr),
		.o_wdata		(dmem_wdata),
		.i_rdata		(dmem_rdata)
	);

	data_mem  u_data_mem (
		.i_clk	 (clk),
		.i_rst_n (rst_n),
		.i_we	 (dmem_we),
		.i_addr	 (dmem_addr),
		.i_wdata (dmem_wdata),
		.o_rdata (dmem_rdata)
	);

	always #(`HCYCLE) clk = ~clk;

	initial
	begin
		$fsdbDumpfile("core.fsdb");
		$fsdbDumpvars(0, testbed, "+mda");
	end

	// always
	// begin
	// 	wait(rst_n == 1'b0);
	// 	@(negedge clk);
	// 	if ((dmem_addr !== 0) || (dmem_we !== 0) || (dmem_wdata !== 0) || (mips_status !== 0) || (mips_status_valid !== 0))
	// 	begin
	// 		$display("**************************************************************");
	// 		$display("*    Output signal should be 0 after initial RESET at %4t   *", $time);
	// 		$display("**************************************************************");
	// 		$finish;
	// 	end
	// end

	initial
	begin
		#(`MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
	end

	// load data memory
	initial
	begin
		clk         = 0;
		IM_addr     = 0;
		errorDM     = 0;
		errorStatus = 0;

		// for (int pat_idx = 0; pat_idx < `times; pat_idx = pat_idx + 1)
		// begin
			// if (`times != 1)
			// begin
			// 	sTmp.itoa(pat_idx);
			// end

		IM_addr  = 0;
		errorDM = 0;
		resetTask();

		// #(`CYCLE);
		// dmem_addr[12:2] = 0;

		while (1) //IM_addr < 1024 && mips_status !== 3'd4 && mips_status !== 3'd5
		begin
			@(negedge clk);
			if (mips_status_valid == 1)
			begin
				if (golden_Status[IM_addr] !== mips_status && golden_Status[IM_addr] !== 3'bxxx)
				begin
					$write ("%c[1;34m",27);
					$display ("Status[%0d]: Error! Golden = %b ,Yours = %b", IM_addr, golden_Status[IM_addr], mips_status);
					$write ("%c[0m",27);
					errorStatus = errorStatus + 1;
				end
				if (IM_addr >= 1024 || mips_status === 3'd4 || mips_status === 3'd5 || golden_Status[IM_addr+1] === 3'bxxx)
				begin
					break;
				end
				IM_addr = IM_addr + 1;
			end
		end

		// #(`CYCLE);
		// force clk = 0;
		// Check Data Memory
		for (int i = 0; i < 2048; i++)
		begin
			if(`DM_word(i) !== `DM_golden(i))
			begin
				$write("%c[1;31m",27);
				$display("Data[%0d]: Error! Golden = %0d ,Yours = %0d", (i - 1024) * 4, `DM_golden(i), `DM_word(i));
				$write("%c[0m",27);
				errorDM = errorDM + 1;
			end
		end
		resultTask(errorStatus, errorDM);
		#100;
		// end
		$finish;
	end


	//================================================================
	// task
	//================================================================
	// << resetTask  >>
	task resetTask;
	begin
		rst_n = 1;
		#(0.25 * `CYCLE) rst_n = 0;
		#(`CYCLE) rst_n = 1;
		$readmemb({`PATH, "/inst.dat"}, u_data_mem.mem_r);
		$readmemb({`PATH, "/data.dat"}, golden_IM_DM);
		$readmemb({`PATH, "/status.dat"}, golden_Status);
	end
	endtask

	// << resultTask  >>
	task resultTask;
	input integer errorSt;
	input integer errorDM;
	begin
		if(errorSt === 0 && errorDM === 0) begin
				$write("%c[1;32m",27);
				$display("");
				// $display("	Pattern : %s ", pattern_num);
				$display("	*******************************               ");
				$display("	**                          **       |\__||  ");
				$display("	**    Congratulations !!    **      / O.O  | ");
				$display("	**                          **    /_____   | ");
				$display("	**    Simulation PASS!!     **   /^ ^ ^ \\  |");
				$display("	**                          **  |^ ^ ^ ^ |w| ");
				$display("	******************************   \\m___m__|_|");
				$display("");
				$write("%c[0m",27);
		end
		else begin
				$write("%c[1;31m",27);
				$display("");
				// $display("	Pattern : %s ", pattern_num);
				$display("	******************************               ");
				$display("	**                          **       |\__||  ");
				$display("	**    OOPS!!                **      / X,X  | ");
				$display("	**                          **    /_____   | ");
				$display("	**    Simulation Failed!!   **   /^ ^ ^ \\  |");
				$display("	**                          **  |^ ^ ^ ^ |w| ");
				$display("	******************************   \\m___m__|_|");
				$display("");
				$display("	Totally has %d errors (Status)               ", errorSt);
				$display("	Totally has %d errors (Data Memory)        \n", errorDM);
				$write("%c[0m",27);
		end
	end
	endtask

endmodule