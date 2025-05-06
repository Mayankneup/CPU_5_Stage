module Pipeline;
	reg [31:0] entryPoint;
	reg clk, INT;
	wire [31:0] ins, rd2, wb;
	Chip myChip(ins, rd2, wb, entryPoint, INT, clk);
	initial
		begin
		//-----Starting point
			entryPoint = 128; 
			INT = 1; 
			#1;
		//------Run program
		repeat (43)
		begin
		//-----Get the instruction
				clk = 1; 
				#1; 
				INT = 0;
		//-----Process the instruction
				clk = 0; 
				#1;
		//-----Show The Result in the Terminal
			$display("%h | register reads:%2d | Write-back value:%2d", ins, rd2, wb);
		end
		$finish;
	end
endmodule
