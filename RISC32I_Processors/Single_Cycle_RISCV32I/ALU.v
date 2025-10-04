`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 06:15:20 PM
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
    
    
    module ALU(
        input  [31:0] A,
        input  [31:0] B,
        input  [3:0]  ALU_op,
        output [31:0] ALU_out,
        output Zero
    );
    
    reg [31:0] result;
    
    always @ (*)
        begin
            case(ALU_op)
                4'b0000 : result = A + B; //add
                4'b0001 : result = A - B; //sub
                4'b0010 : result = A & B; //and
                4'b0011 : result = A | B; //or
                4'b0100 : result = A ^ B; //xor
                4'b0101 : result = A << B[4:0]; //sll
                4'b0110 : result = A >> B[4:0]; //srl
                4'b0111 : result = $signed(A) >>> B[4:0]; //sra
                4'b1000 : result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; //slt
                4'b1001 : result = (A < B) ? 32'd1 : 32'd0; //sltu
                default : result = 32'd0;
            endcase
        end
        
        assign ALU_out = result;
        assign Zero = (result == 32'd0);
        
endmodule
