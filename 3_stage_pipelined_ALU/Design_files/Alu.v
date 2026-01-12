`timescale 1ns / 1ps

module Alu #(
	parameter data_width = 32,
	parameter opcode_width = 7
)(
	input [data_width-1:0] opA,
	input [data_width-1:0] opB,
	input [opcode_width-1:0] opcode,
	output reg [data_width-1:0] alu_result
);

    localparam ADD = 7'h1;
	localparam SUB = 7'h2;
	localparam AND = 7'h3;
	localparam OR =  7'h4;
	localparam XOR = 7'h5;
	localparam SADD = 7'h6;
	
	
	always @ (*)
		begin
			case(opcode)
				ADD : alu_result = opA + opB;
				SUB : alu_result = opA - opB;
				AND : alu_result = opA & opB;
				OR  : alu_result = opA | opB;
				XOR : alu_result = opA ^ opB;
				SADD : alu_result = $signed(opA) + $signed(opB);
				default : alu_result = {data_width{1'b0}};
			endcase
		end
endmodule
