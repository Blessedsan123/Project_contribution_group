`timescale 1ns / 1ps

module Pipelined_alu_top(
	input clk,
	input rst,
	input [4:0] src1,
	input [4:0] src2,
	input [4:0] dest_addr,
	input [6:0] opcode,
	input valid,
	output stall
);

wire [31:0] oprA, oprB;
reg [4:0] rf_waddr;
reg [31:0] rf_wdata;
reg rf_en;
reg [31:0] s1opA, s1opB;
reg [4:0] s1dest,s1srcA,s1srcB;
reg [6:0] s1opcode;
reg s1valid;
reg [4:0] s2dest;
reg [31:0] s2result;
reg s2valid;
wire [31:0] alu_res;
wire [31:0] alu_real_in1, alu_real_in2;

// for hazard unit------------------------
wire hazard_s2, hazard_s3;
wire fwdA_sel, fwdB_sel;

// registerfile instatiation----------

RegisterFile rf (
	.clk(clk),
	.rst(rst),
	.src_addr1(src1),
	.src_addr2(src2),
	.write_en(rf_en),
	.dest_addr(rf_waddr),
	.data_in(rf_wdata),
	.opA(oprA),
	.opB(oprB)
);

// Operand fetch stage ----

always @ (posedge clk)
	begin
		if(rst)
			begin
				s1opA <= 32'b0;
				s1opB <= 32'b0;
				s1dest <= 5'b0;
				s1srcA <= 5'b0;
				s1srcB <= 5'b0;
				s1opcode <= 7'b0;
				s1valid <= 1'b0;
			end
		else if (stall)
			begin
				//hold state
			end
		else
			begin
				s1opA <= oprA;
				s1opB <= oprB;
				s1dest <= dest_addr;
				s1srcA <= src1;
				s1srcB <= src2;
				s1opcode <= opcode;
				s1valid <= valid;
			end
	end
	
//alu instatiation-------

assign alu_real_in1 = (fwdA_sel) ? s2result : s1opA;
assign alu_real_in2 = (fwdB_sel) ? s2result : s1opB;

Alu dut (
	.opA(alu_real_in1),
	.opB(alu_real_in2),
	.opcode(s1opcode),
	.alu_result(alu_res)
);

// execute stage-------

always @ (posedge clk)
	begin
		if(rst)
			begin
				s2dest <= 5'b0;
				s2result <= 32'b0;
				s2valid <= 1'b0;
			end
		else if (stall)
			begin
				s2valid <= 1'b0; 
			end
		else
			begin
				s2dest <= s1dest;
				s2result <= alu_res;
				s2valid <= s1valid;
			end
	end

// writeback stage -----------------

always @ (*)
	begin
		if(rst)
			begin
				rf_waddr = 5'b0;
				rf_wdata = 32'b0;
				rf_en = 1'b0;
			end
		else
			begin
				rf_waddr = s2dest;
				rf_wdata = s2result;
				rf_en = (s2dest == 5'b0) ? 1'b0 : s2valid;
			end
	end

// hazard detection-----------

assign hazard_s2 = s1valid && s2valid && (s2dest != 0) && ((s1srcA == s2dest) || (s1srcB == s2dest));
assign hazard_s3 = s1valid && rf_en && (rf_waddr != 0) && ((s1srcA == rf_waddr) || (s1srcB == rf_waddr));

assign stall = hazard_s2;

assign fwdA_sel = (!hazard_s2 && hazard_s3 && s1srcA == s2dest);
assign fwdB_sel = (!hazard_s2 && hazard_s3 && s1srcB == s2dest);


endmodule
