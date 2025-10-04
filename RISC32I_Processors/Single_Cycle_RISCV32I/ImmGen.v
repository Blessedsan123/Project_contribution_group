`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 07:07:50 PM
// Design Name: 
// Module Name: ImmGen
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


module ImmGen(
    input [31:0] instruction,
    output [31:0] immediate
);

wire [6:0] opcode = instruction[6:0];
reg [31:0] imm;

always @ (*)
    begin
        case(opcode)
            7'b0010011, // i-type arithmatic
            7'b0000011, // i-type load
            7'b1100111  // i-type jalr
                   : imm = {{20{instruction[31]}}, instruction[31:20]};
            
            7'b0100011  // s-type store
                   : imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                   
            7'b1100011  // b-type branch
                   : imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8],1'b0};
            
            7'b0110111, // u-type lui
            7'b0010111 // u-type auipc
                   : imm = {instruction[31:12], 12'b0};
                   
            7'b1101111 // j-type jal
                   : imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                   
            default //unknown
                   : imm = 32'd0;
        endcase
    end
    
assign immediate = imm;
    
endmodule
