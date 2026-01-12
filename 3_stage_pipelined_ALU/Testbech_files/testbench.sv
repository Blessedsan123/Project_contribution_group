`timescale 1ns / 1ps


module testbench;

//interface class ======================================
interface intf ;

	logic clk;
	logic rst;
	
	logic [31:0] pc;
	logic[31:0] instr;
	logic [6:0] opcode_d;
	logic [4:0] src1_d,src2_d,dest_d;
	logic valid_flag; 
	
	
	modport dut (
		input  clk, rst,
		output pc, instr, opcode_d,
			   src1_d, src2_d, dest_d,
			   valid_flag
    );
    
    modport tb (
		output  clk, rst,
		input pc, instr, opcode_d,
			   src1_d, src2_d, dest_d,
			   valid_flag
    );

endinterface

//driver class =========================================
class driver;
 	
 	virtual intf vintf;
 	
 	function new (virtual intf vintf);
 	this.vintf = vintf;
 	endfunction
 	
 	task main();
 		vintf.clk = 0;
 		vintf.rst = 1;
 		repeat(5) #5 vintf.clk = ~vintf.clk;
 		vintf.rst = 0;
 		forever #5 vintf.clk = ~vintf.clk;
 	endtask
endclass

//monitor class ===========================================
class monitor;

	virtual intf vintf;
	logic [31:0] last_pc;
	
	function new (virtual intf vintf);
		this.vintf = vintf;
		last_pc = '0;
	endfunction
	
	task main();
		forever 
			begin
				@(posedge vintf.clk)
				if(vintf.valid_flag)
					begin
						$display("[MONITOR] ===> pc = %h , instruction = %h",vintf.pc, vintf.instr);
					end
				if(vintf.pc == last_pc)
					begin
						$display("[MONITOR] ==> Stall detected at pc = %h",vintf.pc);
						last_pc = vintf.pc;
					end
			end
	endtask
endclass

//scoreboard class ========================================

class scoreboard;
	
	virtual intf vintf;
	int stall_count;
	
	function new( virtual intf vintf);
	this.vintf = vintf;
	stall_count = 0;
	endfunction
	
	task main();
		logic [31:0] prev_pc;
		
		prev_pc = '0;
		
		forever
			begin
				@(posedge vintf.clk)
				if(vintf.valid_flag)
					begin
						if(vintf.pc == prev_pc)
							begin
								stall_count ++;
							end
						prev_pc = vintf.pc;
					end
			end
	endtask
	
	task check_result();
		#500;
		
		if(stall_count != 1)
			$error("expected 1 stall, got %0d",stall_count);
		else
			$display("[SCOREBOARD] ===> stall check passed");
		
		$finish;
	endtask
	
endclass


intf ri();

TopPipelinedExecutionUnit dut(
	.clk(ri.clk),
	.rst(ri.rst),
	.pc(ri.pc),
	.instr(ri.instr),
	.opcode_d(ri.opcode_d),
	.src1_d(ri.src1_d),
	.src2_d(ri.src2_d),
	.dest_d(ri.dest_d),
	.valid_flag(ri.valid_flag)
	);
	
driver drv;
monitor mon;
scoreboard scb;

initial
	begin
		drv = new(ri);
		mon = new(ri);
		scb = new(ri);
		
		fork
			drv.main();
			mon.main();
			scb.main();
		join_none;
		
		scb.check_result();
	end


//=================================  verilog testbench ======================================

//    // -----------------------------
//    // DUT inputs
//    // -----------------------------
//    reg clk;
//    reg rst;

//    // -----------------------------
//    // DUT outputs
//    // -----------------------------
//    wire [31:0] pc;
//    wire [31:0] instr;
//    wire [6:0]  opcode_d;
//    wire [4:0]  src1_d;
//    wire [4:0]  src2_d;
//    wire [4:0]  dest_d;
//    wire        valid_flag;

//    // -----------------------------
//    // DUT instantiation
//    // -----------------------------
//    TopPipelinedExecutionUnit dut (
//        .clk        (clk),
//        .rst        (rst),
//        .pc         (pc),
//        .instr      (instr),
//        .opcode_d   (opcode_d),
//        .src1_d     (src1_d),
//        .src2_d     (src2_d),
//        .dest_d     (dest_d),
//        .valid_flag (valid_flag)
//    );

//    // -----------------------------
//    // Clock generation (10 ns period)
//    // -----------------------------
//    initial begin
//        clk = 0;
//        forever #5 clk = ~clk;
//    end

//    // -----------------------------
//    // Reset sequence
//    // -----------------------------
//    initial begin
//        rst = 1;
//        #20;
//        rst = 0;
//    end

//    // -----------------------------
//    // Simple monitor (optional but useful)
//    // -----------------------------
//    initial begin
//        $display("TIME\tPC\t\tINSTR\t\tVALID");
//        $monitor("%0t\t%h\t%h\t%b",
//                 $time, pc, instr, valid_flag);
//    end

//    // -----------------------------
//    // Stop simulation after some time
//    // -----------------------------
//    initial begin
//        #1000;
//        $display("Simulation finished");
//        $stop;
//    end


endmodule
