`timescale 1ns / 1ns
`define clk_cycle 4
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/07 15:30:28
// Design Name: Wang Sha
// Module Name: CS_tb
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

module CS_tb();

localparam   KEY_RANGE=10000;               //The range of key  1~KEY_RANGE
localparam   KEY_NUMBER=6000;              //The number of key

reg 					nreset;
reg						clk;
wire					KEY_WR;
wire	[31:0]			KEY;
wire					KEY_ALLMOSTFULL;	
reg		[0:0]			pkt_begin;						//send pkt
`ifdef DUMP_FSDB
initial 
begin
  $fsdbDumpfile("wave.fsdb");
  $fsdbDumpvars(0,CS_tb);
end
`endif

initial//clock 125M
begin
	clk 					<= 0;
	nreset 					<= 1'b0;
	pkt_begin				<= 1'b0;
//------reset release---------
	#28 nreset 				<= 1'b1;
	#80
	pkt_begin				<= 1'b1;
	#50000;
	$finish;
end
always #`clk_cycle clk = ~clk;

key_send#(
	.KEY_RANGE_1				(KEY_RANGE			)
)key_send_inst(	
	.Clk						(clk				),	//The input clock
	.nreset						(pkt_begin			),	//Reset, active low
	.NUM						(KEY_NUMBER			),	//The number of key
	.KEY_WR						(KEY_WR				),	//Key write
	.KEY						(KEY				),	//Key
	.KEY_ALLMOSTFULL			(KEY_ALLMOSTFULL	)	//allmostfull
);

//--------------------
//CS_Bucket test
//--------------------
CS_top cs_top_inst(
	//clock and reset signal
	.SYS_CLK					(clk				),	//clock, this is system clock
	.RESET_N					(nreset				),	//Reset the all signal, active low
	
	//Input port
	.KEY_WR						(KEY_WR				),	//write signal
	.KEY						(KEY				),	//KEY
	.KEY_ALLMOSTFULL			(KEY_ALLMOSTFULL	),	//key is allmostfull
	
	//Output port
	.KEY_VALUE_ALLMOSTFULL		(1'b0				)	//VALUE is allmostfull
);

endmodule
