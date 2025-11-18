`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 19:28:27
// Design Name: 
// Module Name: ALU
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

module ALU (
    input [31:0] A,
    input [31:0] B,
    input [2:0] ALUControl,
    output Carry,
    output OverFlow,
    output Zero,
    output Negative,
    output [31:0] Result
);
    wire Cout;
    wire [31:0] Sum = (ALUControl[0] == 1'b0) ? (A + B) : (A + (~B + 1));

    // Output assignment
    assign {Cout, Result} = (
        ALUControl == 3'b000 ? Sum :
        ALUControl == 3'b001 ? Sum :
        ALUControl == 3'b010 ? (A & B) :
        ALUControl == 3'b011 ? (A | B) :
        ALUControl == 3'b101 ? {31'b0, Sum[31]} :
        33'b0
    );

    assign OverFlow = ((Sum[31] ^ A[31]) & (~(ALUControl[0] ^ B[31] ^ A[31])) & (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = ~|Result;
    assign Negative = Result[31];
endmodule
