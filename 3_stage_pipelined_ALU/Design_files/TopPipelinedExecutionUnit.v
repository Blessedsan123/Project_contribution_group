`timescale 1ns / 1ps

module TopPipelinedExecutionUnit (
	input clk,
	input rst,
	output reg [31:0] pc,
	output [31:0] instr,
	output [6:0] opcode_d,
	output [4:0] src1_d,src2_d,dest_d,
	output reg valid_flag
);

wire stall;
//program counter=====================

always @ (posedge clk)
	begin
		if(rst)
			begin
				pc <= 32'hFFFF_FFFC;
				valid_flag <= 0;
			end
		else if(stall)
			begin
				pc <= pc;
				valid_flag <= valid_flag;
			end
		else
			begin
				pc <= pc + 4;
				valid_flag <= 1;
			end
	end
	
// instruction memory=====================

reg [31:0] instr_mem [0:255];

initial
	begin
		$readmemh("mem.hex",instr_mem);
	end
	
assign instr = instr_mem[pc[9:2]];

// instruction decoder=====================

assign opcode_d = instr[31:25];
assign src2_d = instr[24:20];
assign src1_d = instr[19:15];
assign dest_d = instr[14:10];
	
// pipelined alu instantiation ============

Pipelined_alu_top pat (
	.clk(clk),
	.rst(rst),
	.src1(src1_d),
	.src2(src2_d),
	.dest_addr(dest_d),
	.opcode(opcode_d),
	.valid(valid_flag),
	.stall(stall)
);

endmodule