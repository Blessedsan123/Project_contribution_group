`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 08:05:28 AM
// Design Name: 
// Module Name: InstructionMem
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


module InstructionMem #(
    parameter size = 256
)(
    input clk,
    input [31:0] addr,
    output [31:0] instruction
);

reg [31:0] memory [0:size-1];

initial begin
    // Initialize to NOPs/zeros for safety (first 10 entries)
    memory[0]  = 32'h00000013;  // ADDI x0, x0, 0 (NOP, stabilizes)
    memory[1]  = 32'h00000013;  // NOP
    memory[2]  = 32'h00000013;  // NOP
    memory[3]  = 32'h00000013;  // NOP
    memory[4]  = 32'h00000013;  // NOP
    memory[5]  = 32'h00000013;  // NOP
    memory[6]  = 32'h00000013;  // NOP
    memory[7]  = 32'h00000013;  // NOP
    memory[8]  = 32'h00000013;  // NOP
    memory[9]  = 32'h00000013;  // NOP

    // Phase 1: Initialize Registers with x0 (define read_data_A/B early)
    memory[10] = 32'h00000193;  // ADDI x3, x0, 1     ; x3=1 (alu_src=1, alu_op=0000, wb_data=1)
    memory[11] = 32'h00200213;  // ADDI x4, x0, 2     ; x4=2 (read_data_B will use this later)
    memory[12] = 32'h00300393;  // ADDI x7, x0, 3     ; x7=3
    memory[13] = 32'h00400413;  // ADDI x8, x0, 4     ; x8=4
    memory[14] = 32'h00500593;  // ADDI x11, x0, 5    ; x11=5
    memory[15] = 32'h00600613;  // ADDI x12, x0, 6    ; x12=6
    memory[16] = 32'h00700793;  // ADDI x15, x0, 7    ; x15=7
    memory[17] = 32'h00800813;  // ADDI x16, x0, 8    ; x16=8
    memory[18] = 32'h00900993;  // ADDI x19, x0, 9    ; x19=9
    memory[19] = 32'h00a00a13;  // ADDI x20, x0, 10   ; x20=10

    // Phase 2: LUI/AUIPC (U-type, alu_src=1, large immediates, no X in imm)
    memory[20] = 32'h000010b7;  // LUI x1, 0x1        ; x1=0x00010000 (wb_data=large defined)
    memory[21] = 32'h00201137;  // AUIPC x2, 0x200    ; x2=PC+0x20000 (PC known after init)
    memory[22] = 32'h003012b7;  // LUI x5, 0x300      ; x5=0x00030000
    memory[23] = 32'h00401337;  // AUIPC x6, 0x400    ; x6=PC+0x40000

    // Phase 3: R-type ALU Ops (alu_src=0, use initialized regs for read_data_A/B)
    memory[24] = 32'h003080b3;  // ADD x1, x1, x3     ; A=x1(defined), B=x3=1 -> alu_result=0x10001, zero=0
    memory[25] = 32'h40308133;  // SUB x2, x1, x3     ; A=x1, B=x3 -> alu_result=0x10000, zero=0
    memory[26] = 32'h003041b3;  // AND x3, x0, x3     ; A=0, B=1 -> alu_result=0, zero=1 (TEST zero_flag=1)
    memory[27] = 32'h004051b3;  // OR x10, x0, x4     ; A=0, B=2 -> alu_result=2, zero=0
    memory[28] = 32'h005061b3;  // XOR x12, x0, x5    ; A=0, B=0x30000 -> alu_result=0x30000, zero=0
    memory[29] = 32'h006071b3;  // SLT x14, x0, x6    ; A=0, B=PC+0x40000 -> slt=0 (0 >= large), zero=1
    memory[30] = 32'h007081b3;  // SLTU x16, x0, x7   ; A=0, B=3 -> sltu=1 (0 < 3), zero=0
    memory[31] = 32'h008091b3;  // SLL x17, x0, x8    ; A=0, B=4 -> shift=0, zero=1
    memory[32] = 32'h0090a1b3;  // SRL x20, x0, x9    ; A=0, B=9 -> shift=0, zero=1
    memory[33] = 32'h40a0a233;  // SRA x4, x0, x11    ; A=0, B=5 -> sra=0, zero=1

    // Phase 4: I-type ALU (alu_src=1, immediate defined, mix with regs)
    memory[34] = 32'h0010a1b3;  // SLTI x3, x0, 1     ; A=0, imm=1 -> slti=0, zero=1
    memory[35] = 32'h0020b293;  // SLTIU x5, x0, 2    ; A=0, imm=2 -> sltiu=0, zero=1
    memory[36] = 32'h0030c313;  // XORI x6, x0, 3     ; A=0, imm=3 -> alu_result=3, zero=0
    memory[37] = 32'h0040d393;  // ORI x6, x0, 4      ; A=0, imm=4 -> alu_result=4, zero=0
    memory[38] = 32'h0050e413;  // ANDI x8, x0, 5     ; A=0, imm=5 -> alu_result=0, zero=1
    memory[39] = 32'h0060f593;  // ADDI x11, x0, 6    ; A=0, imm=6 -> alu_result=6, zero=0
    memory[40] = 32'h001109b3;  // SLLI x19, x0, 1    ; A=0, shamt=1 -> shift=0, zero=1
    memory[41] = 32'h00211a13;  // SRLI x20, x0, 2    ; A=0, shamt=2 -> shift=0, zero=1
    memory[42] = 32'h40311b93;  // SRAI x23, x0, 3    ; A=0, shamt=3 -> sra=0, zero=1

    // Phase 5: Memory Writes (S-type, alu_src=1, write_data=read_data_B defined)
    memory[43] = 32'h00302023;  // SW x3, 0(x0)       ; addr=0+0=0, write_data=x3=0 (mem_write=1)
    memory[44] = 32'h00402823;  // SW x4, 4(x0)       ; addr=4, write_data=x4=defined
    memory[45] = 32'h005030a3;  // SW x5, 8(x0)       ; addr=8, write_data=x5
    memory[46] = 32'h00603923;  // SW x6, 12(x0)      ; addr=12, write_data=4 (from ORI)
    memory[47] = 32'h00704203;  // SW x7, 16(x0)      ; addr=16, write_data=3
    memory[48] = 32'h00804aa3;  // SW x8, 20(x0)      ; addr=20, write_data=0 (from ANDI)
    memory[49] = 32'h009053e3;  // SW x9, 24(x0)      ; addr=24, write_data=9

    // Phase 6: Memory Reads (I-type Load, mem_read=1, mem2reg=1 -> wb_data=mem_read_data)
    memory[50] = 32'h00002083;  // LW x1, 0(x0)       ; addr=0, mem_read_data=0 (from SW), wb_data=0
    memory[51] = 32'h00402b03;  // LW x22, 4(x0)      ; addr=4, mem_read_data=x4 (defined)
    memory[52] = 32'h00802c83;  // LW x25, 8(x0)      ; addr=8, mem_read_data=x5
    memory[53] = 32'h00c02d03;  // LW x26, 12(x0)     ; addr=12, mem_read_data=4
    memory[54] = 32'h01002e83;  // LW x29, 16(x0)     ; addr=16, mem_read_data=3
    memory[55] = 32'h01402f03;  // LW x30, 20(x0)     ; addr=20, mem_read_data=0 (zero test)
    memory[56] = 32'h01802083;  // LW x1, 24(x0)      ; addr=24, mem_read_data=9, wb_data=9

    // Phase 7: Branches (B-type, test zero_flag, pc_src)
    memory[57] = 32'h00308063;  // BEQ x1, x0, 8      ; x1=9 !=0, zero=0 -> not taken (func3=000)
    memory[58] = 32'h00000013;  // NOP (skipped if taken, but not)
    memory[59] = 32'h00000013;  // NOP
    memory[60] = 32'h00408963;  // BEQ x0, x0, 16     ; 0==0, zero=1 -> taken (pc_src=1)
    memory[61] = 32'h00000013;  // NOP (skipped)
    memory[62] = 32'h00000013;  // NOP
    memory[63] = 32'h005090e3;  // BNE x1, x0, 24     ; x1=9 !=0, ~zero=1 -> taken
    memory[64] = 32'h00000013;  // NOP (skipped)
    memory[65] = 32'h00609a23;  // BNE x0, x0, 32     ; 0==0, ~zero=0 -> not taken
    memory[66] = 32'h0070a3a3;  // BLT x1, x0, 40     ; 9 < 0? No (signed), not taken (func3=100)
    memory[67] = 32'h0080ace3;  // BLT x0, x1, 48     ; 0 < 9? Yes -> taken
    memory[68] = 32'h0090b623;  // BGE x1, x0, 56     ; 9 >=0? Yes -> taken (func3=101)
    memory[69] = 32'h00a0bea3;  // BGE x0, x1, 64     ; 0 >=9? No -> not taken
    memory[70] = 32'h00b0c7e3;  // BLTU x1, x0, 72    ; 9 < 0? No (unsigned) -> not taken (func3=110)
    memory[71] = 32'h00c0d063;  // BLTU x0, x1, 80    ; 0 < 9? Yes -> taken
    memory[72] = 32'h00d0d8a3;  // BGEU x1, x0, 88    ; 9 >=0? Yes -> taken (func3=111)
    memory[73] = 32'h00e0e123;  // BGEU x0, x1, 96    ; 0 >=9? No -> not taken

    // Phase 8: Jumps (J/I-type, jump=1, pc_src=1)
    memory[74] = 32'h0080026f;  // JAL x4, 16         ; rd=x4=PC+4 (defined), jump forward
    memory[75] = 32'h00000013;  // NOP (skipped)
    memory[76] = 32'h00000013;  // NOP
    memory[77] = 32'h00000013;  // NOP
    memory[78] = 32'h010003ef;  // JAL x7, 32         ; Larger jump
    memory[79] = 32'h00008067;  // JALR x0, 0(x0)     ; Jump to 0 (loop back, no link)

    // Pad with NOPs to end (stabilize waveform)
    memory[80] = 32'h00000013;  // NOP
    memory[81] = 32'h00000013;  // NOP
    // ... (repeat up to memory[255] if needed, but 82 entries suffice)
end
    
reg [31:0] instruction_reg;
    
always @ (posedge clk)
    begin
        instruction_reg <= memory[addr[31:2] % size]; //for proper addressing 
    end
    
assign instruction = instruction_reg;
endmodule
