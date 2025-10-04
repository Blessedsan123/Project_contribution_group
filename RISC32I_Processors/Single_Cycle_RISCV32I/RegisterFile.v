`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 06:41:51 PM
// Design Name: 
// Module Name: RegisterFile
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


module RegisterFile(
    input clk,
    input rst,
    input reg_write,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data,
    output [31:0] read_data_A,
    output [31:0] read_data_B
);

reg [31:0] memory [0:31];
integer i;

always @ (posedge clk or posedge rst)
    begin
        if(rst)
            begin
                for(i = 0 ; i < 32 ; i = i + 1)
                    begin
                        memory[i] <= 32'd0;
                    end
            end
        else if( reg_write && (rd != 5'd0))
            begin
                memory[rd] <= write_data;
            end
    end
    
assign read_data_A = (rs1 == 5'd0) ? 32'd0 : memory[rs1];
assign read_data_B = (rs2 == 5'd0) ? 32'd0 : memory[rs2];

initial memory[0] = 32'd0; //always makes memory[0] x0 = 32'd0;


endmodule
