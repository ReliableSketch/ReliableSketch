//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/07 10:23:41
// Design Name: Wang Sha
// Module Name: CS_top
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

module CS_top(
    //clock and reset signal
	input 						SYS_CLK,					//clock, this is system clock
	input 						RESET_N,					//Reset the all signal, active low
	//Input port
	input						KEY_WR,						//write signal
	input	[31:0]				KEY,						//KEY
	output						KEY_ALLMOSTFULL,			//key is allmostfull
	//Output port
	input						KEY_VALUE_ALLMOSTFULL		//VALUE is allmostfull
);

    wire	[63:0]				cs_bucket_input_1;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_1_wr;
	wire						cs_bucket_1_2_alf;
	wire	[63:0]				cs_bucket_input_2;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_2_wr;
	wire						cs_bucket_2_3_alf;
	wire	[63:0]				cs_bucket_input_3;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_3_wr;
	wire						cs_bucket_3_4_alf;
	wire	[63:0]				cs_bucket_input_4;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_4_wr;
	wire						cs_bucket_4_5_alf;
	wire	[63:0]				cs_bucket_input_5;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_5_wr;
	wire	[63:0]				cs_bucket_input_6;			//First Layer Collision-Sensible Bucket
	wire						cs_bucket_input_6_wr;		

    
CRC32h_32bit	CRC32h_32bit_inst(
//----------CLK & RST INPUT-----------
	.clk						(SYS_CLK								),			//The clock come from 
	.reset_n					(RESET_N								),			//hardware reset
//-----------CLK & RST GEN-----------
	.data						(KEY									),			//Origin KEY
	.datavalid					(KEY_WR									),			//key write
	.checksum					(cs_bucket_input_1					    ),		    //hash_value
	.crcvalid					(cs_bucket_input_1_wr				    )			//hash_value_wr
);


CS_Bucket_1#(
	.RAMAddWidth				(16										),
	.DataDepth					(65536									),
	.ErrorThreshold			    (5'd16                                  )
) cs_bucket_1(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_1					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_1_wr				    ),			//receive write
	.CS_Bucket_out_key_alf	    (KEY_ALLMOSTFULL						),			//output ACL allmostfull
	//Output port
	.CS_Bucket_out_value		(cs_bucket_input_2				        ),			//send metadata to DMUX
	.CS_Bucket_out_value_wr		(cs_bucket_input_2_wr				    ),			//receive write to DMUX
	.CS_Bucket_in_key_alf		(cs_bucket_1_2_alf					    )			//output ACL allmostfull
);


CS_Bucket_2#(
	.RAMAddWidth				(15										),
	.DataDepth					(32768									),
	.ErrorThreshold			    (5'd8                                   )
) cs_bucket_2(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_2					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_2_wr				    ),			//receive write
	.CS_Bucket_out_key_alf	    (cs_bucket_1_2_alf					    ),			//output ACL allmostfull
//	.CS_Bucket_in_key			(cs_bucket_input_1					    ),			//receive metadata
//	.CS_Bucket_in_key_wr		(cs_bucket_input_1_wr				    ),			//receive write
//	.CS_Bucket_out_key_alf	    (KEY_ALLMOSTFULL					    ),			//output ACL allmostfull
	//Output port
	.CS_Bucket_out_value		(cs_bucket_input_3				        ),			//send metadata to DMUX
	.CS_Bucket_out_value_wr		(cs_bucket_input_3_wr				    ),			//receive write to DMUX
	.CS_Bucket_in_key_alf		(cs_bucket_2_3_alf					    )			//output ACL allmostfull
);

CS_Bucket_3#(
	.RAMAddWidth				(14										),
	.DataDepth					(16384									),
	.ErrorThreshold			    (5'd4                                   )
) cs_bucket_3(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_3					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_3_wr				    ),			//receive write
	.CS_Bucket_out_key_alf	    (cs_bucket_2_3_alf					    ),			//output ACL allmostfull
//	.CS_Bucket_in_key			(cs_bucket_input_1					    ),			//receive metadata
//	.CS_Bucket_in_key_wr		(cs_bucket_input_1_wr				    ),			//receive write
//	.CS_Bucket_out_key_alf	    (KEY_ALLMOSTFULL					    ),			//output ACL allmostfull
	//Output port
	.CS_Bucket_out_value		(cs_bucket_input_4				        ),			//send metadata to DMUX
	.CS_Bucket_out_value_wr		(cs_bucket_input_4_wr				    ),			//receive write to DMUX
	.CS_Bucket_in_key_alf		(cs_bucket_3_4_alf					    )			//output ACL allmostfull
);


CS_Bucket_4#(
	.RAMAddWidth				(13										),
	.DataDepth					(8192									),
	.ErrorThreshold			    (5'd2                                   )
) cs_bucket_4(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_4					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_4_wr				    ),			//receive write
	.CS_Bucket_out_key_alf	    (cs_bucket_3_4_alf					    ),			//output ACL allmostfull
//	.CS_Bucket_in_key			(cs_bucket_input_1					    ),			//receive metadata
//	.CS_Bucket_in_key_wr		(cs_bucket_input_1_wr				    ),			//receive write
//	.CS_Bucket_out_key_alf	    (KEY_ALLMOSTFULL					    ),			//output ACL allmostfull
	//Output port
	.CS_Bucket_out_value		(cs_bucket_input_5				        ),			//send metadata to DMUX
	.CS_Bucket_out_value_wr		(cs_bucket_input_5_wr				    ),			//receive write to DMUX
	.CS_Bucket_in_key_alf		(cs_bucket_4_5_alf					    )			//output ACL allmostfull
);


CS_Bucket_5#(
	.RAMAddWidth				(12										),
	.DataDepth					(4096									),
	.ErrorThreshold			    (5'd1                                   )
) cs_bucket_5(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_5					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_5_wr				    ),			//receive write
	.CS_Bucket_out_key_alf	    (cs_bucket_4_5_alf						),			//output ACL allmostfull
//	.CS_Bucket_in_key			(cs_bucket_input_1					    ),			//receive metadata
//	.CS_Bucket_in_key_wr		(cs_bucket_input_1_wr				    ),			//receive write
//	.CS_Bucket_out_key_alf	    (KEY_ALLMOSTFULL						),			//output ACL allmostfull
	//Output port
	.CS_Bucket_out_value		(cs_bucket_input_6				        ),			//send metadata to DMUX
	.CS_Bucket_out_value_wr		(cs_bucket_input_6_wr				    ),			//receive write to DMUX
	.CS_Bucket_in_key_alf		(KEY_VALUE_ALLMOSTFULL					)			//output ACL allmostfull
);


ES_Bucket#(
	.RAMAddWidth				(7										),
	.DataDepth					(128									)
) es_bucket(
	//clock and reset signal
	.Clk						(SYS_CLK								),			//clock, this is synchronous clock
	.Reset_N					(RESET_N								),			//Reset the all signal, active high
	//Input port
	.CS_Bucket_in_key			(cs_bucket_input_6					    ),			//receive metadata
	.CS_Bucket_in_key_wr		(cs_bucket_input_6_wr				    )			//receive write
);

    
endmodule
