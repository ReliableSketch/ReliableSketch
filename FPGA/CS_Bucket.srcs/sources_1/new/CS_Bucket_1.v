//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/07 10:35:50
// Design Name: Wang Sha
// Module Name: CS_Bucket_1
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

module CS_Bucket_1
#(parameter
	RAMAddWidth						= 12,						//The RAM address width
	DataDepth						= 4096,					    //The RAM data depth
	ErrorThreshold					= 5'd16                     //The number of elements per window
)
(
    //clock and reset signal
	input 							Clk,						//clock, this is synchronous clock
	input 							Reset_N,					//Reset the all signal, active high
	//Input port
	input		[63:0]				CS_Bucket_in_key,			//receive metadata
	input							CS_Bucket_in_key_wr,		//receive write
	output							CS_Bucket_out_key_alf,		//output ACL allmostfull
	//Output port
	output	reg[63:0]     			CS_Bucket_out_value,		//send metadata to DMUX
	output	reg						CS_Bucket_out_value_wr,	    //receive write to DMUX
	input							CS_Bucket_in_key_alf		//output ACL allmostfull
);
    
    //wire
	wire							check_key_empty;			//fifo empty
	wire		[3:0]				check_key_usedw;			//fifo usedword
	reg								check_key_rd;				//fifo read 
	wire		[63:0]				check_key_q;				//fifo data
	reg			[2:0]				count;						//count the read-signal
	reg			[63:0]				check_key_q_reg0;			//restore the key
	reg			[63:0]				check_key_q_reg1;			//restore the key
	reg			[63:0]				check_key_q_reg2;			//restore the key
	
	//----------------------ram--------------------------//
	reg			[RAMAddWidth-1:0]	ram_addr_a;					//ram a-port address        read
	reg			[RAMAddWidth-1:0]	ram_addr_b;					//ram b-port address        write
	reg			[71:0]				ram_data_a;					//ram a-port data
	reg			[71:0]				ram_data_b;					//ram b-port data
	reg								ram_rden_a;					//read a-port 
	reg								ram_rden_b;					//read b-port 
	reg								ram_wren_a;					//write a-port
	reg								ram_wren_b;					//write b-port
	wire		[71:0]				ram_out_a;					//data a-port
	wire		[71:0]				ram_out_b;					//data b-port
//-------------------state------------------------//
	reg			[3:0]				lookup_state;				//look up state
	parameter						idle_s 		=	4'h0,
									pharse_1_s	=	4'h1,
									pharse_2_s	=	4'h2,
									pharse_3_s	=	4'h3,
									pharse_4_s	=	4'h4,
									wait_1_s	=	4'h5,
									wait_2_s	=	4'h6,
									read_s		=	4'h7;
										
	assign CS_Bucket_out_key_alf			    = &check_key_usedw[3:0];					//send out allmostfull
 
   
always @(posedge Clk or negedge Reset_N)
	if (~Reset_N) 
	begin
	    CS_Bucket_out_value_wr              <= 1'b0;
	    CS_Bucket_out_value                 <= 64'b0;
	
		check_key_q_reg0					<= 64'b0;									//clean all signal
		check_key_q_reg1					<= 64'b0;									//clean all signal
		check_key_q_reg2					<= 64'b0;									//clean all signal
		
		
		ram_addr_a							<= {(RAMAddWidth){1'b0}};					//clean all signal
		ram_data_a							<= 72'b0;									//clean all signal
		ram_rden_a							<= 1'b0;									//clean all signal
		ram_wren_a							<= 1'b0;									//clean all signal		
		ram_addr_b							<= {(RAMAddWidth){1'b0}};					//clean all signal
		ram_data_b							<= 72'b0;									//clean all signal
		ram_rden_b							<= 1'b0;									//clean all signal
		ram_wren_b							<= 1'b0;									//clean all signal
		
		check_key_rd						<= 1'b0;									//clean all signal
		count								<= 3'd0;									//clean all signal
		lookup_state						<= idle_s;									//clean all signal
	end
	else 
	begin
		case(lookup_state)
		idle_s: 
		begin
		   CS_Bucket_out_value_wr               <= 1'b0;
	       CS_Bucket_out_value                  <= 64'b0;
																					
			ram_rden_a							<= 1'b0;								//clean signal
			ram_addr_a                          <= {(RAMAddWidth){1'b0}};			
			ram_wren_b							<= 1'b0;								//clean signal
			ram_addr_b                          <= {(RAMAddWidth){1'b0}};
			ram_data_b							<= 72'b0;
			
			check_key_q_reg0					<= 64'b0;								//clear
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			
			
			if (check_key_empty == 1'b0 && CS_Bucket_in_key_alf == 1'b0) 
			begin				//address is coming
				check_key_rd					<= 1'b1;								//read the address fifo
				lookup_state					<= pharse_1_s;							//read-data need 2 cycle from ram 
				count							<= 3'd1;								//counter, record the read cycle
			end
			else 
			begin																	    //no address, wait
				check_key_rd					<= 1'b0;								//clean signal
				lookup_state					<= idle_s;								//waiting
			end
		end
		
		pharse_1_s: 
		begin
			ram_rden_a							<= 1'b1;								//read the ram
			ram_addr_a							<= check_key_q[RAMAddWidth-1:0];		//send the address
			check_key_q_reg0					<= check_key_q;							//restore the key
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			
			
			if (check_key_usedw	> 4'h2)	
			begin											//hash address isn't empty, read
				check_key_rd					<= 1'b1;								//read fifo
				lookup_state					<= pharse_2_s;							//turn to pharse_2_s		
				count							<= count + 3'd1;						//counter=2
			end
			else begin																	//no address, wait data
				check_key_rd					<= 1'b0;								//don't read fifo
				lookup_state					<= wait_1_s;							//counter=1			
			end
		end
		
		pharse_2_s: 
		begin
			ram_rden_a							<= 1'b1;								//read the ram
			ram_addr_a							<= check_key_q[RAMAddWidth-1:0];		//send the address
			
			check_key_q_reg0					<= check_key_q;							//restore the key
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			if (check_key_usedw	> 4'h2)	
			begin											//hash address isn't empty, read
				check_key_rd					<= 1'b1;								//read fifo
				lookup_state					<= pharse_3_s;							//turn to pharse_3_s		
				count							<= count + 3'd1;						//counter=3
			end
			else 
			begin																	//no address, wait data
				check_key_rd					<= 1'b0;								//don't read fifo
				lookup_state					<= wait_2_s;							//counter=2			
			end
		end	
		
		pharse_3_s: 
		begin
			ram_rden_a							<= 1'b1;								//read the ram
			ram_addr_a							<= check_key_q[RAMAddWidth-1:0];	            	//send the address
			check_key_q_reg0					<= check_key_q;							//restore the key
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			if (check_key_usedw	> 4'h2)	
			begin											//hash address isn't empty, read
				check_key_rd					<= 1'b1;								//read fifo
				lookup_state					<= pharse_4_s;							//turn to pharse_4_s		
				count							<= count + 3'd1;						//counter=4
			end
			else 
			begin																	    //no address, wait data
				check_key_rd					<= 1'b0;								//don't read fifo
				lookup_state					<= read_s;								//counter=3			
			end
		end	
		
		pharse_4_s: 
		begin
			ram_rden_a							<= 1'b1;
			ram_addr_a							<= check_key_q[RAMAddWidth-1:0];		//send the address
			check_key_q_reg0					<= check_key_q;							//restore the key
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
            
		    if(check_key_q_reg2[63:32]=={(32){1'b0}})                                   //entered the previous bucket
		    begin
		         CS_Bucket_out_value_wr         <= 1'b1;
		         CS_Bucket_out_value            <= check_key_q_reg2;
		         ram_addr_b                     <={(RAMAddWidth){1'b0}};
			     ram_data_b                     <={(72){1'b0}};           
		         ram_wren_b						<= 1'b0;
		    end
		    else
		    begin		              
		         if(ram_out_a[39:32]<ErrorThreshold || ram_out_a[71:40]==check_key_q_reg2[63:32] || ram_out_a[31:0]<=ram_out_a[39:32]+ram_out_a[39:32])
		         //entered the current bucket£¬and the bits of CS_Bucket_out_value are all set to 0
		         begin		         
		              ram_wren_b						    <= 1'b1;
		              ram_addr_b                            <=check_key_q_reg2[RAMAddWidth-1:0];
		              ram_data_b[31:0]                      <= ram_out_a[31:0]+1'b1;
		              if(ram_out_a[31:0]<=ram_out_a[39:32]+ram_out_a[39:32])
		              begin		                   	
			                ram_data_b[71:40]               <=check_key_q_reg2[63:32];
			                ram_data_b[39:32]               <=ram_out_a[39:32];				            				                           
		              end
		              else if(ram_out_a[71:40]!=check_key_q_reg2[63:32])		              		 
		              begin
		                    ram_data_b[71:40]               <=ram_out_a[71:40];
			                ram_data_b[39:32]               <=ram_out_a[39:32]+1'b1; 
		              end
		              else
		              begin
		                    ram_data_b[71:32]               <=ram_out_a[71:32];
		              end
		              CS_Bucket_out_value_wr         <= 1'b1;
		              CS_Bucket_out_value            <= {(64){1'b0}};		              
		         end
		         else//the next layer
		         begin
		              CS_Bucket_out_value_wr         <= 1'b1;
		              CS_Bucket_out_value            <= check_key_q_reg2;
		              ram_addr_b                     <={(RAMAddWidth){1'b0}};
			          ram_data_b                     <={(72){1'b0}};           
		              ram_wren_b					 <= 1'b0;
		         end
		    end
		    		
			
			if (check_key_usedw	> 4'h2)
			begin											//hash address isn't empty, read
				check_key_rd					<= 1'b1;								//read fifo
				lookup_state					<= pharse_4_s;							//countue send
			end
			else begin																	//no address, wait data
				check_key_rd					<= 1'b0;								//don't read fifo
				count							<= count - 3'd1;						//decrease 1
				lookup_state					<= read_s;								//counter=3
			end
		end
		
		wait_1_s: 
		begin																	//ram have 2 cycle to send data, so wait 2 cycle 
			check_key_q_reg0					<= 64'b0;								//clear
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			ram_rden_a							<= 1'b0;								//clean signal
			ram_addr_a                          <= {(RAMAddWidth){1'b0}};
			ram_wren_b						    <= 1'b0;
			ram_addr_b                          <= {(RAMAddWidth){1'b0}};
			ram_data_b							<= 72'b0;
			lookup_state						<= wait_2_s;							//waiting data
		end
		
		wait_2_s: 
		begin
			check_key_q_reg0					<= 64'b0;								//clear
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			ram_rden_a							<= 1'b0;								//clean signal
			ram_addr_a                          <= {(RAMAddWidth){1'b0}};
			ram_wren_b						    <= 1'b0;
			ram_addr_b                          <= {(RAMAddWidth){1'b0}};
			ram_data_b							<= 72'b0;
			lookup_state						<= read_s;								//waiting data
		end
		
		read_s: 
		begin
			check_key_q_reg0					<= 64'b0;								//clear
			check_key_q_reg1					<= check_key_q_reg0;					//restore the key
			check_key_q_reg2					<= check_key_q_reg1;					//restore the key
			ram_rden_a							<= 1'b0;								//clean signal
			ram_addr_a                          <= {(RAMAddWidth){1'b0}};

            if(check_key_q_reg2[63:32]=={(32){1'b0}})                                   //entered the previous bucket
		    begin
		         CS_Bucket_out_value_wr         <= 1'b1;
		         CS_Bucket_out_value            <= check_key_q_reg2;
		         ram_addr_b                     <={(RAMAddWidth){1'b0}};
			     ram_data_b                     <={(72){1'b0}};           
		         ram_wren_b						<= 1'b0;
		    end
		    else
		    begin		              
		         if(ram_out_a[39:32]<ErrorThreshold || ram_out_a[71:40]==check_key_q_reg2[63:32] || ram_out_a[31:0]<=ram_out_a[39:32]+ram_out_a[39:32])
		         //entered the current bucket£¬and the bits of CS_Bucket_out_value are all set to 0
		         begin		         
		              ram_wren_b						    <= 1'b1;
		              ram_addr_b                            <=check_key_q_reg2[RAMAddWidth-1:0];
		              ram_data_b[31:0]                      <= ram_out_a[31:0]+1'b1;
		              if(ram_out_a[31:0]<=ram_out_a[39:32]+ram_out_a[39:32])
		              begin		                   	
			                ram_data_b[71:40]               <=check_key_q_reg2[63:32];
			                ram_data_b[39:32]               <=ram_out_a[39:32];				            				                           
		              end
		              else if(ram_out_a[71:40]!=check_key_q_reg2[63:32])		              		 
		              begin
		                    ram_data_b[71:40]               <=ram_out_a[71:40];
			                ram_data_b[39:32]               <=ram_out_a[39:32]+1'b1; 
		              end
		              else
		              begin
		                    ram_data_b[71:32]               <=ram_out_a[71:32];
		              end
		              CS_Bucket_out_value_wr         <= 1'b1;
		              CS_Bucket_out_value            <= {(64){1'b0}};		              
		         end
		         else//the next layer
		         begin
		              CS_Bucket_out_value_wr         <= 1'b1;
		              CS_Bucket_out_value            <= check_key_q_reg2;
		              ram_addr_b                     <={(RAMAddWidth){1'b0}};
			          ram_data_b                     <={(72){1'b0}};           
		              ram_wren_b					 <= 1'b0;
		         end
		    end
            
			
			if (count == 3'd1)	
			begin 													                    //all read is empty
				lookup_state					<= idle_s;								//go back
			end			
			else  
			begin
				count							<= count - 3'd1;						//send 
				lookup_state					<= read_s;								//countine
			end			
		end
		
		default: 
		begin
			lookup_state						<= idle_s;								//go back
		end
		endcase
	end


//----PKT_FIFO----//
	wire						pkt_Reset;		
	wire						pkt_wrclock;	
	wire	[63:0]				pkt_RamData;	
	wire						pkt_RamRdreq;	
	wire						pkt_RamWrreq;	
	wire	[3:0]				pkt_rdaddress;	
	wire	[3:0]				pkt_wraddress;	
	wire	[63:0]				pkt_Ram_q;	
	fifo_top
	#(		.ShowHead			(1							),	//show head model,1<->show head,0<->normal
			.SynMode			(1							),	//1<->SynMode,0<->AsynMode
			.DataWidth			(64							),	//This is data width
			.DataDepth			(16							),	//for ASYNC,DataDepth must be 2^n (n>=1). for SYNC,DataDepth is a positive number(>=1)
			.RAMAddWidth		(4							)	//RAM address width, RAMAddWidth= log2(DataDepth).
	)scfifo_64_16_pkt_fifo_1(
			.aclr				(~Reset_N					),	//Reset the all signal, active high
			.data				(CS_Bucket_in_key			),	//The Inport of data 
			.rdclk				(Clk						),	//ASYNC ReadClk
			.rdreq				(check_key_rd				),	//active-high
			.wrclk				(Clk						),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq				(CS_Bucket_in_key_wr		),	//active-high
			.q					(check_key_q				),	//The Outport of data
			.rdempty			(check_key_empty			),	//active-high
			.wrfull				(							),	//active-high
			.wrusedw			(check_key_usedw			),	//RAM wrusedword
			.rdusedw			(							),	//RAM rdusedword			
			.Reset				(pkt_Reset					),	//The signal of reset, active high
			.wrclock			(pkt_wrclock				),	//ASYNC WriteClk, SYNC use wrclk
			.rdclock			(							),	//ASYNC ReadClk
			.RamData			(pkt_RamData				),	//RAM input data
			.RamRdreq			(pkt_RamRdreq				),	//RAM read request
			.RamWrreq			(pkt_RamWrreq				),	//RAM write request
			.rdaddress			(pkt_rdaddress				),	//RAM read address
			.wraddress			(pkt_wraddress				),	//RAM write address
			.Ram_q				(pkt_Ram_q					)	//RAM output data			
	);	
	
	ram_64_16_1	ram_64_16_pkt1 (
					.clka		(pkt_wrclock				),	//ASYNC WriteClk, SYNC use wrclk
					.ena		(pkt_RamWrreq				),	//RAM write address
					.wea		(pkt_RamWrreq				),	//RAM write address
					.addra		(pkt_wraddress				),	//RAM read address
					.dina		(pkt_RamData				),	//RAM input data
					.douta		(							),
					.clkb		(pkt_wrclock				),	//ASYNC WriteClk, SYNC use wrclk
					.enb		(pkt_RamRdreq				),  //RAM write request
					.web		(1'b0						),
					.addrb		(pkt_rdaddress				),  //RAM read request
					.dinb		(64'b0						),
					.doutb		(pkt_Ram_q					)	//RAM output data				
				);	

//----hash 1 ram----//
	wire							hash_clka;		
	wire							hash_ena;	
	wire							hash_wea;	
	wire	[RAMAddWidth-1:0]		hash_addra;		
	wire	[71:0]					hash_dina;		
	wire	[71:0]					hash_douta;		
	wire							hash_clkb;		
	wire							hash_enb;	
	wire							hash_web;	
	wire	[RAMAddWidth-1:0]		hash_addrb;		
	wire	[71:0]					hash_dinb;		
	wire	[71:0]					hash_doutb;		

	ASYNCRAM#(
					.DataWidth	(72						    ),	//This is data width	
					.DataDepth	(DataDepth					),	//for ASYNC,DataDepth must be 2^n (n>=1). for SYNC,DataDepth is a positive number(>=1)
					.RAMAddWidth(RAMAddWidth				)	//RAM address width, RAMAddWidth= log2(DataDepth).			
	)	
	hash_1(
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

	ram_72_65536  hash1(
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
				
				
////----hash 1 ram----//
//	wire							hash_clka;		
//	wire							hash_ena;	
//	wire							hash_wea;	
//	wire	[RAMAddWidth-1:0]		hash_addra;		
//	wire	[71:0]					hash_dina;		
//	wire	[71:0]					hash_douta;		
//	wire							hash_clkb;		
//	wire							hash_enb;	
//	wire							hash_web;	
//	wire	[RAMAddWidth-1:0]		hash_addrb;		
//	wire	[71:0]					hash_dinb;		
//	wire	[71:0]					hash_doutb;		

//	ASYNCRAM#(
//					.DataWidth	(72						    ),	//This is data width	
//					.DataDepth	(DataDepth					),	//for ASYNC,DataDepth must be 2^n (n>=1). for SYNC,DataDepth is a positive number(>=1)
//					.RAMAddWidth(RAMAddWidth				)	//RAM address width, RAMAddWidth= log2(DataDepth).			
//	)	
//	hash_1(
//					.aclr		(~Reset_N					),	//Reset the all write signal	
//					.address_a	(ram_addr_a					),	//RAM A port address
//					.address_b	(ram_addr_b					),	//RAM B port assress
//					.clock_a	(Clk						),	//Port A clock
//					.clock_b	(Clk						),	//Port B clock	
//					.data_a		(ram_data_a					),	//The Inport of data 
//					.data_b		(ram_data_b					),	//The Inport of data 
//					.rden_a		(ram_rden_a					),	//active-high, read signal
//					.rden_b		(ram_rden_b					),	//active-high, read signal
//					.wren_a		(ram_wren_a					),	//active-high, write signal
//					.wren_b		(ram_wren_b					),	//active-high, write signal
//					.q_a		(ram_out_a					),	//The Output of data
//					.q_b		(ram_out_b					),	//The Output of data
//					// ASIC RAM
//					.reset		(							),	//Reset the RAM, active higt
//					.clka		(hash_clka					),	//Port A clock
//					.ena		(hash_ena					),	//Port A enable
//					.wea		(hash_wea					),	//Port A write
//					.addra		(hash_addra				    ),	//Port A address
//					.dina		(hash_dina					),	//Port A input data
//					.douta		(hash_douta				    ),	//Port A output data
//					.clkb		(hash_clkb					),	//Port B clock
//					.enb		(hash_enb					),	//Port B enable
//					.web		(hash_web					),	//Port B write
//					.addrb		(hash_addrb				    ),	//Port B address
//					.dinb		(hash_dinb					),	//Port B input data
//					.doutb		(hash_doutb				    )	//Port B output data	
//	);

//	ram_72_4096  hash1(
//					.clka		(hash_clka					),	//ASYNC WriteClk, SYNC use wrclk
//					.ena		(hash_ena					),	//RAM write address
//					.wea		(hash_wea					),	//RAM write address
//					.addra		(hash_addra				    ),	//RAM read address
//					.dina		(hash_dina					),	//RAM input data
//					.douta		(hash_douta				    ),	//RAM output data
//					.clkb		(hash_clkb					),	//ASYNC WriteClk, SYNC use wrclk
//					.enb		(hash_enb					),  //RAM write request
//					.web		(hash_web					),	//RAM write address
//					.addrb		(hash_addrb				    ),  //RAM read request
//					.dinb		(hash_dinb					),	//RAM input data
//					.doutb		(hash_doutb				    )	//RAM output data				
//				);					

endmodule
