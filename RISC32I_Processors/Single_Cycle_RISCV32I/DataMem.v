`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 08:24:09 AM
// Design Name: 
// Module Name: DataMem
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


module DataMem #(
    parameter size = 256
    )(
    input clk,
    input [31:0] addr,
    input [31:0] write_data,
    input mem_write,
    input mem_read,
    output [31:0] read_data
);

reg [31:0] read_reg;
reg [31:0] memory [0:size-1];
integer i;
initial
    begin
        for(i = 0 ;i < size; i = i+1)
            begin
                memory[i] = 32'd0;
            end
    end
    
always @ (posedge clk)
    begin
      if(mem_write)
        begin
            memory[addr[31:2] % size] <= write_data; 
        end
      if(mem_read)
        begin
            read_reg <= memory[addr[31:2] % size] ; 
        end
    end
    
assign read_data = read_reg;
endmodule
