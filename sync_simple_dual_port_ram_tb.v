`include "sync_simple_dual_port_ram.v"
module tb;

	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 4;
	parameter DEPTH = 16;

	reg wr_clk,rd_clk,cs_0,cs_1,wr_en,rd_en;
	reg [ADDR_WIDTH-1:0] addr_wr,addr_rd;
	reg [DATA_WIDTH-1:0] data_in;
	wire [DATA_WIDTH-1:0] data_out;

	sync_sdp_ram DUT(.wr_clk(wr_clk),
					 .cs_0(cs_0),
					 .wr_en(wr_en),
					 .addr_wr(addr_wr),
					 .data_in(data_in),
					 .rd_clk(rd_clk),
					 .cs_1(cs_1),
					 .rd_en(rd_en),
					 .addr_rd(addr_rd),
					 .data_out(data_out));

	initial begin
		wr_clk = 0;
		forever #5 wr_clk = ~wr_clk;
	end

	initial begin
		rd_clk = 0;
		forever #7 rd_clk = ~rd_clk;
	end

	integer i,error_count;

	//WRITE OPERATION

	task writes;
		input [ADDR_WIDTH-1:0] wr_addr;
		input [DATA_WIDTH-1:0] data;
		begin

			@(negedge wr_clk);
			cs_0    = 1'b1;
			wr_en	= 1'b1;
			addr_wr = wr_addr;
			data_in = data;

			@(posedge wr_clk);
			#1;
			$display("WRITE: addr=%b data=%h",wr_addr,data);

			@(negedge wr_clk);
			cs_0    = 1'b0;
			wr_en	= 1'b0;
		end
	endtask

	// READ OPERATION

	task reads;
		input [ADDR_WIDTH-1:0] rd_addr;
		input [DATA_WIDTH-1:0] expected;
		begin
			@(negedge rd_clk);
			cs_1     = 1'b1;
			rd_en    = 1'b1;
			addr_rd  = rd_addr;

			@(posedge rd_clk);
			#1;
			if(expected === data_out)begin
				$display("READ PASS: addr=%b expected =%h data=%h",rd_addr,expected,data_out);
			end
			else begin
				$display("READ FAILED : addr=%b expected =%h data=%h",rd_addr,expected,data_out);
				error_count = error_count+1;
			end
			@(negedge rd_clk);
			cs_1    = 1'b0;
			rd_en	= 1'b0;
		end
	endtask


	initial begin
		cs_0    = 1'b0;
		wr_en	= 1'b0;
		addr_wr = 0;
		data_in = 0;

		cs_1	= 1'b0;
		rd_en	= 1'b0;
		addr_rd = 0;

		error_count = 0;

		#10;

		// SINGLE WRITE

		$display("SINGLE WRITE");
		writes(4'd5,32'habcdef12);
		$display("--------------------------------------------------");
		
		#5;

		// SINGLE READ

		$display("SINGLE READ");
		reads(4'd5,32'habcdef12);
		$display("--------------------------------------------------");

		// MULTIPLE WRITE

		$display("MULTIPLE WRITES");
		for(i=0;i<5;i=i+1)begin
			writes(4'd5+i,32'habcdef00+i);
		end
		$display("--------------------------------------------------");

		// MULTIPLE READ

		$display("MULTIPLE READ");
		for(i=0;i<5;i=i+1)begin
			reads(4'd5+i,32'habcdef00+i);
		end
		$display("--------------------------------------------------");

		// ALL WRITES

		$display("ALL WRITES");
		for(i=0;i<DEPTH;i=i+1)begin
			writes(4'd0+i,32'habcdef00+i);
		end
		$display("--------------------------------------------------");

		// ALL READS 

		$display("ALL READS");
		for(i=0;i<DEPTH;i=i+1)begin
			reads(4'd0+i,32'habcdef00+i);
		end
		$display("--------------------------------------------------");

		// SIMULTANEOUS WRITE AND READ

		$display(" SIMULTANEOUS WRITE AND READ ");

		@(negedge wr_clk);
		cs_0    = 1'b1;
		wr_en	= 1'b1;
		addr_wr = 4'd5;
		data_in = 32'hAAAA_AAAA;

		@(negedge rd_clk);
		cs_1    = 1'b1;
		rd_en	= 1'b1;
		addr_rd = 4'd10;
		
		@(posedge wr_clk);
		@(posedge rd_clk);
		#1;

		$display("SIMULTANEOUS WRITE: addr=%b data=%h",addr_wr,data_in);
		
		if(data_out === 32'habcdef0a)begin
			$display("SIMULTANEOUS READ PASS: addr=%b data=%h",addr_rd,data_out);
		end
		else begin
			$display("SIMULTANEOUS READ FAIL: addr=%b Expected=%h data=%h",addr_rd,32'habcdef0a,data_out);
			error_count = error_count+1;
		end
		cs_0	= 1'b0;
		wr_en 	= 1'b0;
		cs_1	= 1'b0;
		rd_en	= 1'b0;
		$display("--------------------------------------------------");

		// WRITE ENABLE = 0

		$display(" WRITE ENABLE=0 ");

		@(negedge wr_clk);
		cs_0	= 1'b1;
		wr_en	= 1'b0;
		addr_wr = 4'd5;
		data_in = 32'hBBBB_BBBB;

		@(posedge wr_clk);
		#1;
		$display("write operation is disabled");
		cs_0= 1'b0;

		reads(4'd5,32'hAAAA_AAAA); // reading old data
		$display("--------------------------------------------------");

		#5;

		// READ ENABLE = 0

		$display(" READ ENABLE=0 ");
		@(negedge rd_clk);
		cs_1	= 1'b1;
		rd_en	= 1'b0;
		addr_rd = 4'd5;

		@(posedge rd_clk);
		#1;
		$display("previous data is unchanged");
		cs_1 = 1'b0;
		$display("--------------------------------------------------");

		#10;

		// FINAL RESULT

		$display(" FINAL RESULT" );

		if(error_count == 0)begin
			$display("ALL TEST CASES ARE PASSED");
			$display("error count: %0d", error_count);
		end
		else begin
			$display("TEST CASE ARE FAILED");
			$display("error count: %0d", error_count);
		end

		#50;
		$finish;


	end

endmodule
