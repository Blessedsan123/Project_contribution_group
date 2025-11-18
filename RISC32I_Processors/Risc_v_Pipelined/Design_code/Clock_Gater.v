`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 20:38:03
// Design Name: 
// Module Name: Clock_Gater
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

module Clock_Gater (
    input wire clk,
    input wire enable,
    output wire gated_clk
);
    reg enable_latch;
    always @(negedge clk) enable_latch <= enable;
    assign gated_clk = clk & enable_latch;
endmodule