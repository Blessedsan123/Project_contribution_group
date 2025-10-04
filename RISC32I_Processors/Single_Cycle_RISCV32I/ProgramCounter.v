`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 10:41:08 PM
// Design Name: 
// Module Name: ProgramCounter
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


module ProgramCounter(
    input clk,
    input rst,
    input [31:0] next_pc,
    input pc_write,
    output [31:0] current_pc
);

reg [31:0] pc;

always @ (posedge clk or posedge rst)
    begin
        if(rst)
            pc <= 32'd0;
        else if(pc_write)
            pc <= next_pc;
    end
    
    assign current_pc = pc;
endmodule
