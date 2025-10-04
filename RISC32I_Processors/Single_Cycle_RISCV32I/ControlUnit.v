`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 09:38:53 PM
// Design Name: 
// Module Name: ControlUnit
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


module ControlUnit(
    input [6:0] opcode,
    input [2:0] func3,
    input [6:0] func7,
    output reg_write,
    output alu_src,
    output mem_read,
    output mem_write,
    output mem_to_reg,
    output branch,
    output jump,
    output [3:0] alu_op
);

reg reg_wr, a_src, mem_r, mem_w, mem2reg, br, jmp;
reg [3:0] a_op;

always @ (*)
    begin
    
    reg_wr = 1'b0;
    a_src = 1'b0;
    mem_r = 1'b0;
    mem_w = 1'b0;
    mem2reg = 1'b0;
    br = 1'b0;
    jmp = 1'b0;
    a_op = 4'b0000;
    
    
    //standard opcodes for riscv
        case(opcode)
            7'b0110011 : begin //r-type
                reg_wr = 1'b1;
                a_src = 1'b0;
                mem2reg = 1'b0;
                
                case(func3)
                    3'b000 : a_op = (func7[5] == 1) ? 4'b0001 : 4'b0000; //sub or add
                    3'b001 : a_op = 4'b0101; // sll
                    3'b010 : a_op = 4'b1000; //slt
                    3'b011 : a_op = 4'b1001; //sltu
                    3'b100 : a_op = 4'b0100; //xor
                    3'b101 : a_op = (func7[5] == 1) ? 4'b0111 : 4'b0110; //srl or sra
                    3'b110 : a_op = 4'b0011; //or
                    3'b111 : a_op = 4'b0010; //and
                endcase
                end
                
            7'b0010011 : begin //i-type arithmatic
                reg_wr = 1'b1;
                a_src = 1'b1;
                mem2reg = 1'b0;
                
                case(func3)
                    3'b000 : a_op = 4'b0000; //addi
                    3'b010 : a_op = 4'b1000; //slti
                    3'b011 : a_op = 4'b1001; //sltiu
                    3'b100 : a_op = 4'b0100; //xori
                    3'b110 : a_op = 4'b0011; //ori
                    3'b111 : a_op = 4'b0010; //andi
                    3'b001 : a_op = 4'b0101; //slli
                    3'b101 : a_op = (func7[5] == 1) ? 4'b0111 : 4'b0110; //srai or srli
                endcase
                end
                
           7'b0000011 : begin //i-type load
                reg_wr = 1'b1;
                a_src = 1'b1;
                mem_r = 1'b1;
                mem2reg = 1'b1;
                a_op = 4'b0000;
                end
                
          7'b0100011 : begin //s-type store
                a_src = 1'b1;
                mem_w = 1'b1;
                a_op = 4'b0000;
                end
                
          7'b1100011 : begin //b-type branch
                br = 1'b1; 
                a_src = 1'b0;
                a_op = 4'b0001;
                end
                
          7'b0110111 : begin //u-type lui
                reg_wr = 1'b1;
                a_src = 1'b1;
                mem2reg = 1'b0;
                a_op = 4'b0000;
                end
                
          7'b0010111 : begin //u-type auipc
                reg_wr = 1'b1;
                a_src = 1'b1;
                mem2reg = 1'b0;
                a_op = 4'b0000;
                end
                
          7'b1101111 : begin //j-type jal
                reg_wr = 1'b1;
                jmp = 1'b1;
                a_src = 1'b1;
                mem2reg = 1'b0;
                a_op = 4'b0000;
                end
                
          7'b1100111 : begin //i-type jalr
                reg_wr = 1'b1;
                jmp = 1'b1;
                a_src = 1'b1;
                mem2reg = 1'b0;
                a_op = 4'b0000;
                end
                
          default : ;
        endcase
    end
    
    assign reg_write = reg_wr;
    assign alu_src = a_src;
    assign mem_read = mem_r;
    assign mem_write = mem_w;
    assign mem_to_reg = mem2reg;
    assign branch = br;
    assign jump = jmp;
    assign alu_op = a_op;

endmodule
