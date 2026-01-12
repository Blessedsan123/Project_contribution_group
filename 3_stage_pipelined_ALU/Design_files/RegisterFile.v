`timescale 1ns / 1ps

module RegisterFile #(
 parameter width = 32
)(
	input clk,
	input rst,
	input [4:0]src_addr1,
	input [4:0]src_addr2,
	input write_en,
	input [4:0] dest_addr,
	input [31:0] data_in,
	output [31:0] opA,
	output [31:0] opB
);

reg [width-1:0] register [0:width-1];
integer i;

	
assign opA =register[src_addr1];
assign opB =register[src_addr2];

always @ (posedge clk)
	begin
		if(rst)
		begin
			for(i = 0 ; i<width; i = i + 1)
				begin
					register[i] = 32'h0;
				end
		end
		else if(write_en && dest_addr != 5'b0)
			begin
				register[dest_addr] = data_in;
			end
	end

endmodule
