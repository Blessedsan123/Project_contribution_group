`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 20:43:42
// Design Name: 
// Module Name: System_Top
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


module System_Top (
    // System-level inputs
    input  wire main_clk,
    input  wire rst,
    input  wire sleep_request,
    input  wire wakeup_request,

    // All the debug outputs from your RiscV_top
    output wire PCSrcE,
    output wire RegWriteW,
    output wire RegWriteE,
    output wire ALUSrcE,
    output wire MemWriteE,
    output wire ResultSrcE,
    output wire BranchE,
    output wire RegWriteM,
    output wire MemWriteM,
    output wire ResultSrcM,
    output wire ResultSrcW,
    output wire [2:0] ALUControlE,
    output wire [4:0] RD_E,
    output wire [4:0] RD_M,
    output wire [4:0] RDW,
    output wire [31:0] PCTargetE,
    output wire [31:0] InstrD,
    output wire [31:0] PCD,
    output wire [31:0] PCPlus4D,
    output wire [31:0] ResultW,
    output wire [31:0] RD1_E,
    output wire [31:0] RD2_E,
    output wire [31:0] Imm_Ext_E,
    output wire [31:0] PCE,
    output wire [31:0] PCPlus4E,
    output wire [31:0] PCPlus4M,
    output wire [31:0] WriteDataM,
    output wire [31:0] ALU_ResultM,
    output wire [31:0] PCPlus4W,
    output wire [31:0] ALU_ResultW,
    output wire [31:0] ReadDataW,
    output wire [4:0] RS1_E,
    output wire [4:0] RS2_E,
    output wire [1:0] ForwardBE,
    output wire [1:0] ForwardAE
);

    // Internal wires for clock gating
    wire sleep_mode;   // 1 if sleeping, 0 if active
    wire clock_enable; // 1 if clock should run
    wire riscv_clk;    // The gated clock for the RISC-V core

    Sleep_Controller sc_inst (
        .clk(main_clk),
        .rst(rst),
        .sleep_request(sleep_request),
        .wakeup_request(wakeup_request),
        .sleep_state_out(sleep_mode) // Output is 1 for SLEEP, 0 for ACTIVE
    );

    // The clock is enabled when the core is NOT in sleep mode.
    assign clock_enable = ~sleep_mode;


    Clock_Gater cg_inst (
        .clk(main_clk),
        .enable(clock_enable),
        .gated_clk(riscv_clk)
    );

    RiscV_top riscv_core_inst (
        .clk(riscv_clk), // <-- Connect to the GATED clock
        .rst(rst),       // <-- Connect to the main reset

        // Pass all debug ports directly up to the top
        .PCSrcE(PCSrcE),
        .RegWriteW(RegWriteW),
        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE),
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .ResultSrcW(ResultSrcW),
        .ALUControlE(ALUControlE),
        .RD_E(RD_E),
        .RD_M(RD_M),
        .RDW(RDW),
        .PCTargetE(PCTargetE),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .ResultW(ResultW),
        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM),
        .ALU_ResultM(ALU_ResultM),
        .PCPlus4W(PCPlus4W),
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW(ReadDataW),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),
        .ForwardBE(ForwardBE),
        .ForwardAE(ForwardAE)
    );

endmodule

