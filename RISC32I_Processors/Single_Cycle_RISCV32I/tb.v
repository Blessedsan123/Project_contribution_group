`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 04:27:27 PM
// Design Name: 
// Module Name: tb
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


module tb;
    reg clk, rst;
    wire [31:0] pc_debug;
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] instruction;
    wire [31:0] immediate;
    wire [31:0] read_data_A;
    wire [31:0] read_data_B;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] wb_data;
    wire zero_flag;
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem2reg;
    wire branch;
    wire jump;
    wire pc_src;
    wire [3:0] alu_op;

    SingleCycleRV32I dut (.clk(clk), 
                          .rst(rst), 
                          .pc_debug(pc_debug),
                          .pc_current(pc_current),
                          .pc_next(pc_next),
                          .instruction(instruction),
                          .immediate(immediate),
                          .read_data_A(read_data_A),
                          .read_data_B(read_data_B),
                          .alu_result(alu_result),
                          .mem_read_data(mem_read_data),
                          .wb_data(wb_data),
                          .zero_flag(zero_flag),
                          .reg_write(reg_write),
                          .alu_src(alu_src),
                          .mem_read(mem_read),
                          .mem_write(mem_write),
                          .mem2reg(mem2reg),
                          .branch(branch),
                          .jump(jump),
                          .pc_src(pc_src),
                          .alu_op(alu_op)
                    );

    always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    #10 rst = 0;
    #2000 $finish;  // <== Give at least 150–200 ns per 10 instructions if clock at 10ns period
end
endmodule
