`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 20:37:05
// Design Name: 
// Module Name: sleep_controller
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

module Sleep_Controller (
    input wire clk,
    input wire rst,
    input wire sleep_request,
    input wire wakeup_request,
    output reg sleep_state_out
);
    parameter ACTIVE = 1'b0;
    parameter SLEEP = 1'b1;
    reg current_state, next_state;

    // Combinational next state logic
    always @(*) begin
        case (current_state)
            ACTIVE: next_state = sleep_request ? SLEEP : ACTIVE;
            SLEEP: next_state = wakeup_request ? ACTIVE : SLEEP;
            default: next_state = ACTIVE;
        endcase
    end

    // Sequential state update
    always @(posedge clk or negedge rst) begin
        if (!rst)
            current_state <= ACTIVE;
        else
            current_state <= next_state;
    end

    // Output
    always @(posedge clk or negedge rst) begin
        if (!rst)
            sleep_state_out <= 1'b0;
        else
            sleep_state_out <= current_state;
    end
endmodule