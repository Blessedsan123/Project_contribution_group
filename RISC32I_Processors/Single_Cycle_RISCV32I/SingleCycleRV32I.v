`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 03:34:45 PM
// Design Name: 
// Module Name: SingleCycleRV32I
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SingleCycleRV32I(
input clk,
input rst,
output [31:0] pc_debug,
output [31:0] pc_current,
output [31:0] pc_next,
output [31:0] instruction,
output [31:0] immediate,
output [31:0] read_data_A,
output [31:0] read_data_B,
output [31:0] alu_result,
output [31:0] mem_read_data,
output [31:0] wb_data,
output zero_flag,
output reg_write,
output alu_src,
output mem_read,
output mem_write,
output mem2reg,
output branch,
output jump,
output pc_src,
output [3:0] alu_op
);

wire [31:0] pcplus4, branch_target;
wire pc_write = 1'b1;


// decode instruction

wire [6:0] opcode = instruction[6:0];
wire [4:0] rs1 = instruction[19:15];
wire [4:0] rs2 = instruction[24:20];
wire [4:0] rd = instruction[11:7];
wire [2:0] func3 = instruction[14:12];
wire [6:0] func7 = instruction[31:25];

//program counter

ProgramCounter pc (
    .clk(clk),
    .rst(rst),
    .next_pc(pc_next),
    .current_pc(pc_current),
    .pc_write(pc_write)
);

assign pcplus4 = pc_current+32'd4;
assign branch_target = pc_current + immediate;
assign pc_next = pc_src ? branch_target : pcplus4;

//instruction_mem

InstructionMem im (
    .clk(clk),
    .addr(pc_current),
    .instruction(instruction)
);


//immediate generator

ImmGen ig (
    .instruction(instruction),
    .immediate(immediate)
);

//controlunit

ControlUnit cu (
    .opcode(opcode),
    .func3(func3),
    .func7(func7),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .mem_to_reg(mem2reg),
    .branch(branch),
    .jump(jump),
    .alu_op(alu_op)
);

//register file

RegisterFile rf (
    .clk(clk),
    .rst(rst),
    .reg_write(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(wb_data),
    .read_data_A(read_data_A),
    .read_data_B(read_data_B)
);


wire [31:0] alu_in2;

assign alu_in2 = (alu_src) ? immediate : read_data_B;

//ALU

ALU alu (
    .A(read_data_A),
    .B(alu_in2),
    .ALU_op(alu_op),
    .ALU_out(alu_result),
    .Zero(zero_flag)
);

//data_memory

DataMem dm (
    .clk(clk),
    .addr(alu_result),
    .write_data(read_data_B),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .read_data(mem_read_data)
);

// writeback

assign wb_data = mem2reg ? mem_read_data : alu_result;

reg branch_taken;
always @(*) 
    begin
        case (func3)  // For branch instructions
                3'b000: branch_taken = zero_flag;                    // BEQ
                3'b001: branch_taken = ~zero_flag;                   // BNE
                3'b100: branch_taken = ($signed(read_data_A) < $signed(read_data_B)); // BLT
                3'b101: branch_taken = ($signed(read_data_A) >= $signed(read_data_B)); // BGE
                3'b110: branch_taken = (read_data_A < read_data_B);  // BLTU
                3'b111: branch_taken = (read_data_A >= read_data_B); // BGEU
                default: branch_taken = 1'b0;
        endcase
    end
    
assign pc_src = (branch & branch_taken) | jump;

assign pc_debug = pc_current;
    
endmodule
