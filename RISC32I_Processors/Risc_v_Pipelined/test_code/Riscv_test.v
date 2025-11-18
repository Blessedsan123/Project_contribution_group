`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 20:12:39
// Design Name: 
// Module Name: Riscv_test
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


module RiscV_test;

    // Clock and Reset
    reg clk;
    reg rst;

    // Outputs from DUT
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    wire RegWriteM, MemWriteM, ResultSrcM, ResultSrcW;
    wire [2:0] ALUControlE;
    wire [4:0] RD_E, RD_M, RDW, RS1_E, RS2_E;
    wire [1:0] ForwardBE, ForwardAE;
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E;
    wire [31:0] PCPlus4M, WriteDataM, ALU_ResultM;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;

    // Instantiate DUT
    RiscV_top uut (
        .clk(clk),
        .rst(rst),
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

    // Clock Generation: 10 ns period (100 MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst = 0;

        // Apply Reset
        $display("Applying Reset...");
        #20;
        rst = 1;
        $display("Releasing Reset...");

        // Run simulation
        #500;

        // Finish simulation
        $display("Simulation Complete.");
        $finish;
    end

    // Optional: Monitor some signals
    initial begin
        $monitor("Time=%0t | PC=%h | Instr=%h | ALU_ResultM=%h | RegWriteW=%b",
                 $time, PCE, InstrD, ALU_ResultM, RegWriteW);
    end

endmodule
