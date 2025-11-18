`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 20:48:12
// Design Name: 
// Module Name: System_Top_tb
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


module System_Top_tb;

    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    reg main_clk;
    reg rst;
    reg sleep_request;
    reg wakeup_request;

    // All debug output wires from the DUT
    wire PCSrcE;
    wire RegWriteW;
    wire RegWriteE;
    wire ALUSrcE;
    wire MemWriteE;
    wire ResultSrcE;
    wire BranchE;
    wire RegWriteM;
    wire MemWriteM;
    wire ResultSrcM;
    wire ResultSrcW;
    wire [2:0] ALUControlE;
    wire [4:0] RD_E;
    wire [4:0] RD_M;
    wire [4:0] RDW;
    wire [31:0] PCTargetE;
    wire [31:0] InstrD;
    wire [31:0] PCD;
    wire [31:0] PCPlus4D;
    wire [31:0] ResultW;
    wire [31:0] RD1_E;
    wire [31:0] RD2_E;
    wire [31:0] Imm_Ext_E;
    wire [31:0] PCE;
    wire [31:0] PCPlus4E;
    wire [31:0] PCPlus4M;
    wire [31:0] WriteDataM;
    wire [31:0] ALU_ResultM;
    wire [31:0] PCPlus4W;
    wire [31:0] ALU_ResultW;
    wire [31:0] ReadDataW;
    wire [4:0] RS1_E;
    wire [4:0] RS2_E;
    wire [1:0] ForwardBE;
    wire [1:0] ForwardAE;

    // Add any additional DUT signals as needed from your System_Top.v port list

    // DUT instantiation
    System_Top dut (
        .main_clk(main_clk),
        .rst(rst),
        .sleep_request(sleep_request),
        .wakeup_request(wakeup_request),

        // All debug outputs connected:
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

    // Clock generation
    initial main_clk = 1'b0;
    always #(CLK_PERIOD/2) main_clk = ~main_clk;

    // Test sequence for verification
    initial begin
        $display("----- Starting System_Top simulation -----");

        // Initial states
        rst = 1;
        sleep_request = 0;
        wakeup_request = 0;

        // Reset sequence
        # (CLK_PERIOD*2);
        rst = 0;
        # (CLK_PERIOD*2);
        rst = 1;
        $display("Reset complete. System ACTIVE.");

        // Run ACTIVE mode for initial cycles
        # (CLK_PERIOD*30);

        // Enter SLEEP mode
        $display("Sleep mode requested.");
        sleep_request = 1;
        # (CLK_PERIOD);
        sleep_request = 0;
        # (CLK_PERIOD*30);

        // Wakeup request
        $display("Wakeup requested.");
        wakeup_request = 1;
        # (CLK_PERIOD);
        wakeup_request = 0;
        # (CLK_PERIOD*30);

        $display("----- Testbench complete. -----");
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("T=%0t | rst=%b | sleep_req=%b | wakeup_req=%b | PC=%h | InstrD=%h | RegWriteE=%b | ALU_ResultM=%h",
                  $time, rst, sleep_request, wakeup_request, PCD, InstrD, RegWriteE, ALU_ResultM);
    end

    // Optional: Waveform file for Vivado
    initial begin
        $dumpfile("system_top_tb.vcd");
        $dumpvars(0, System_Top_tb);
    end

endmodule