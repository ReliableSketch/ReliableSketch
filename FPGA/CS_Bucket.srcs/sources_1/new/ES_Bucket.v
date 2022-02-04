//`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/07 13:34:54
// Design Name: Wang Sha
// Module Name: ES_Bucket
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

module ES_Bucket
#(parameter
	RAMAddWidth						= 7,						//The RAM address width
	DataDepth						= 128					    //The RAM data depth
)
(
    //clock and reset signal
	input 							Clk,						//clock, this is synchronous clock
	input 							Reset_N,					//Reset the all signal, active high
	//Input port
	input		[63:0]				CS_Bucket_in_key,			//receive metadata
	input							CS_Bucket_in_key_wr		//receive write
);
    
	reg         [RAMAddWidth-1:0]   index_bucket;
	//----------------------ram--------------------------//
	reg			[RAMAddWidth-1:0]	ram_addr_a;					//ram a-port address        write
	reg			[RAMAddWidth-1:0]	ram_addr_b;					//ram b-port address        
	reg			[31:0]				ram_data_a;					//ram a-port data
	reg			[31:0]				ram_data_b;					//ram b-port data
	reg								ram_rden_a;					//read a-port 
	reg								ram_rden_b;					//read b-port 
	reg								ram_wren_a;					//write a-port
	reg								ram_wren_b;					//write b-port
	wire		[31:0]				ram_out_a;					//data a-port
	wire		[31:0]				ram_out_b;					//data b-port
	
	reg			[63:0]				check_key_q_reg0;			//restore the key
	//State
    reg			     				lookup_state;				//look up state
    
	localparam						idle_s 		=	1'b0,
									pharse_1_s	=	1'b1;
    

always @(posedge Clk or negedge Reset_N)
	if (~Reset_N) 
	begin			
		index_bucket                        <= {(RAMAddWidth){1'b0}};	
		ram_addr_a							<= {(RAMAddWidth){1'b0}};					//clean all signal
		ram_data_a							<= 32'b0;									//clean all signal
		ram_rden_a							<= 1'b0;									//clean all signal
		ram_wren_a							<= 1'b0;									//clean all signal		
		ram_addr_b							<= {(RAMAddWidth){1'b0}};					//clean all signal
		ram_data_b							<= 32'b0;									//clean all signal
		ram_rden_b							<= 1'b0;									//clean all signal
		ram_wren_b							<= 1'b0;									//clean all signal
	    lookup_state						<= idle_s;									//clean all signal
	end
	else 
	begin
	    case(lookup_state)
	    idle_s:
	    begin
	        check_key_q_reg0                <= CS_Bucket_in_key;
	        lookup_state                    <= pharse_1_s;
	    end
	    pharse_1_s:
	    begin
	        check_key_q_reg0                <= CS_Bucket_in_key;
	        if(check_key_q_reg0!=64'h0)//insert the escape bucket
		    begin
		          ram_addr_a                     <=index_bucket;
			      ram_data_a                     <=check_key_q_reg0[63:32];
			      //ram_data_a                     <=index_bucket;            
		          ram_wren_a					 <=1'b1;
		          index_bucket                   <=index_bucket+1'b1;		      
		    end
		    else
		    begin
                  //entered the previous bucket		      
		          ram_addr_a                     <={(RAMAddWidth){1'b0}};
			      ram_data_a                     <={(32){1'b0}};           
		          ram_wren_a					 <= 1'b0;
		    end
	    end
	    endcase
	end
				
				
//----hash 6 ram----//
	wire							hash_clka;		
	wire							hash_ena;	
	wire							hash_wea;	
	wire	[RAMAddWidth-1:0]		hash_addra;		
	wire	[31:0]					hash_dina;		
	wire	[31:0]					hash_douta;		
	wire							hash_clkb;		
	wire							hash_enb;	
	wire							hash_web;	
	wire	[RAMAddWidth-1:0]		hash_addrb;		
	wire	[31:0]					hash_dinb;		
	wire	[31:0]					hash_doutb;		

	ASYNCRAM#(
					.DataWidth	(32						    ),	//This is data width	
					.DataDepth	(DataDepth					),	//for ASYNC,DataDepth must be 2^n (n>=1). for SYNC,DataDepth is a positive number(>=1)
					.RAMAddWidth(RAMAddWidth				)	//RAM address width, RAMAddWidth= log2(DataDepth).			
	)	
	hash_6(
					.aclr		(~Reset_N					),	//Reset the all write signal	
					.address_a	(ram_addr_a					),	//RAM A port address
					.address_b	(ram_addr_b					),	//RAM B port assress
					.clock_a	(Clk						),	//Port A clock
					.clock_b	(Clk						),	//Port B clock	
					.data_a		(ram_data_a					),	//The Inport of data 
					.data_b		(ram_data_b					),	//The Inport of data 
					.rden_a		(ram_rden_a					),	//active-high, read signal
					.rden_b		(ram_rden_b					),	//active-high, read signal
					.wren_a		(ram_wren_a					),	//active-high, write signal
					.wren_b		(ram_wren_b					),	//active-high, write signal
					.q_a		(ram_out_a					),	//The Output of data
					.q_b		(ram_out_b					),	//The Output of data
					// ASIC RAM
					.reset		(							),	//Reset the RAM, active higt
					.clka		(hash_clka					),	//Port A clock
					.ena		(hash_ena					),	//Port A enable
					.wea		(hash_wea					),	//Port A write
					.addra		(hash_addra				    ),	//Port A address
					.dina		(hash_dina					),	//Port A input data
					.douta		(hash_douta				    ),	//Port A output data
					.clkb		(hash_clkb					),	//Port B clock
					.enb		(hash_enb					),	//Port B enable
					.web		(hash_web					),	//Port B write
					.addrb		(hash_addrb				    ),	//Port B address
					.dinb		(hash_dinb					),	//Port B input data
					.doutb		(hash_doutb				    )	//Port B output data	
	);

	ram_32_128  hash6(
					.clka		(hash_clka					),	//ASYNC WriteClk, SYNC use wrclk
					.ena		(hash_ena					),	//RAM write address
					.wea		(hash_wea					),	//RAM write address
					.addra		(hash_addra				    ),	//RAM read address
					.dina		(hash_dina					),	//RAM input data
					.douta		(hash_douta				    ),	//RAM output data
					.clkb		(hash_clkb					),	//ASYNC WriteClk, SYNC use wrclk
					.enb		(hash_enb					),  //RAM write request
					.web		(hash_web					),	//RAM write address
					.addrb		(hash_addrb				    ),  //RAM read request
					.dinb		(hash_dinb					),	//RAM input data
					.doutb		(hash_doutb				    )	//RAM output data				
				);		

endmodule
