//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/07 15:31:01
// Design Name: Wang Sha
// Module Name: key_send
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

module key_send
#(parameter
	KEY_RANGE_1		= 15
)
(
	input	wire							Clk,					//The input clock
	input	wire							nreset,					//Reset, active low
	input	wire		[31:0]				NUM,					//The number of key	
	//Send the KEY
	output	reg								KEY_WR,					//Key write
	output	reg			[31:0]				KEY,					//Key
	input	wire							KEY_ALLMOSTFULL		    //allmostfull
	
);

	reg		[31:0]				send_cnt;
always@(posedge Clk or negedge nreset)
	if(!nreset) 
	begin
		KEY_WR							<= 1'b0;
		KEY								<= 32'b0;
		send_cnt						<= 32'b1;
	end
	else 
	begin
		if (KEY_ALLMOSTFULL == 1'b0)
		begin				                                           //KEY isn't full
			if (send_cnt <= NUM)
			begin					                                   //Send the key
				KEY_WR				     <= 1'b1;	                   //write is high
				KEY						 <= 1+{$random}%KEY_RANGE_1;
				send_cnt				 <= send_cnt + 32'h1;	       //send counter  
			end
			else 
			begin									                   //All KEY is send out
				KEY_WR					 <= 1'b0;
				KEY						 <= {(32){1'b0}};
			end
		end
		else 
		begin										                   //CS_Bucket top is full, waiting
			KEY_WR						 <= 1'b0;
			KEY							 <= {(32){1'b0}};
		end
	end

endmodule
