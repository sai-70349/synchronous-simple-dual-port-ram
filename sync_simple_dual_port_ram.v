module sync_sdp_ram(wr_clk,cs_0,wr_en,addr_wr,data_in,rd_clk,cs_1,rd_en,addr_rd,data_out);

	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 4;
	parameter DEPTH = 16;

	input wr_clk,rd_clk,cs_0,cs_1,wr_en,rd_en;
	input [ADDR_WIDTH-1:0] addr_wr,addr_rd;
	input [DATA_WIDTH-1:0] data_in;
	output reg [DATA_WIDTH-1:0] data_out;

	reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

	always@(posedge wr_clk)begin
		if(cs_0 && wr_en)begin
			memory[addr_wr] <= data_in;
		end
	end
	
	always@(posedge rd_clk)begin
		if(cs_1 && rd_en)begin
			data_out <= memory[addr_rd];
		end
	end

endmodule
