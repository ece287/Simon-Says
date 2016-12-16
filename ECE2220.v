// Top Level Control Module
// Written by: Keeley Edwards; Edited by Anthony Roberto
// Clock and VGA Sync written by: Brandon Hill (modified by: Anthony Roberto)

module ECE2220(clk, player, state, rst,pulse,
				hsync, vsync, vga_R, vga_G, vga_B, vga_sync, vga_blank, vga_clk, colourLEDs,rxdata,
				Player1, Player2, storeHex1,storeHex2,playercolour1,playercolour2,PS2_DATA,PS2_CLOCK,
);
	input wire clk, player;
	input [1:0] state; // 00 = static, 01 = game, 10 = user, 11 = static
	reg [3:0] colour;
	input playercolour1,playercolour2;
	output hsync, vsync;
	output reg [7:0] vga_R, vga_G, vga_B;
	output vga_sync;
	output vga_blank;
	output vga_clk;
	output reg pulse;
	input rst;
	
	output reg [3:0] Player1, Player2;
	output [7:0] colourLEDs;
	output reg [0:6] storeHex1,storeHex2;

	wire [7:0] gvga_R, gvga_G, gvga_B, tvga_R, tvga_G, tvga_B;
	reg [9:0] pixel_x;
	reg [8:0] pixel_y;
	wire checkMark;
	reg match, win;
	wire img_on;
	reg [3:0]colourStore1;
	reg [3:0]colourStore2;
	reg [2:0] LevelOut;
	
	
//----Keyboard---// Anthony Roberto
//This will register user imput, and store color in player register
keyboard mykeyboard(clk,PS2_DATA,PS2_CLOCK,rxdata);
  input PS2_DATA;
  input PS2_CLOCK;
  output [7:0]rxdata;
  reg [7:0] rxdata1;
  reg datafetched;
	
	always@(posedge PS2_CLOCK)
	begin
	rxdata1=rxdata;
		begin
		case(rxdata)
		8'h1C: colour[0] = 1;  //r a
		8'h1B: colour[1] = 1;  //y s
		8'h23: colour[2] = 1;  //b d
		8'h2B: colour[3] = 1;  //g f
		//player2 color register below
	/*	8'h3B: colourStore2 = 4'b0001;  //r h
		8'h42: colourStore2 = 4'b0010;  //y j
		8'h4B: colourStore2 = 4'b0100;  //b k
		8'h4C: colourStore2 = 4'b1000;  //g l */
		default colour[3:0] = 0;
		endcase
	end
	end
//------ Initialize VGA  ------//
	reg vga_HS, vga_VS;
	reg clock25;
	
	wire CounterXmaxed = (pixel_x==799); //799 full width of field including front and back porches and sync
	wire CounterYmaxed = (pixel_y==525); //525 full length of field including front and back porches and sync
 
//----- 25 MHz clock (//
	always @(posedge clk)
		if(clock25)
			begin
				clock25 = 0;
			end
		else
			begin
				clock25 = 1;
			end

//-----Synchronize VGA Output (modified from Brandon Hill) (AR)-----//
	assign vga_clk = clock25;
	assign vga_blank = vsync & hsync;
	assign vga_sync = 1;
		
	always @(posedge clock25)
		if(CounterXmaxed && ~CounterYmaxed)
			begin
			pixel_x <= 0;
			pixel_y <= pixel_y + 1;
			end 
		else if (~CounterXmaxed)
			pixel_x <= pixel_x + 1;
		else if (CounterXmaxed && CounterYmaxed)
			begin
			pixel_y <= 0;
			pixel_x <= 0;
			end
//	
	always @(posedge clock25)
		begin
			vga_HS <= (pixel_x <= 96);   // active for 16 clocks
			vga_VS <= (pixel_y <= 2);   // active for 800 clocks
		end 

	assign hsync = ~vga_HS;
	assign vsync = ~vga_VS;
	
//----- Instantiate Modules (KE) -----//	
	imageDisplay image_unit (.LevelOut(LevelOut), .colour(colour), .player(player), .match(checkMark), .win(win), 
										.pix_x(pixel_x), .pix_y(pixel_y),
											.vga_R(gvga_R), .vga_G(gvga_G), .vga_B(gvga_B), .video_on(img_on));	
	//store store_unit (.colourStore(colourStore), .player(player), .match(match), .LevelNumber(LevelOut), .Player1(Player1), .Player2(Player2), .storeHex(storeHex));

//----- Assign a signal to pass to the display to indicate a match (AR) -----//
	
	
	always@(posedge state[1])	
		begin
		if((Player2[3:0] == Player1[3:0]) && (Player2[3:0] != 0) && (Player1[3:0] != 0))
			begin
				LevelOut <= (LevelOut + 1);
				match = 1;
			end
		else
			match = 0;
		end

	assign checkMark = match;
	
//----- Detect user input (colour) and store it as colourStore (Anthony Roberto) -----//
	initial colourStore1 = 4'b0000;
	initial colourStore2 = 4'b0010;

	always@(*)
	
		begin
		if (colour[3] == 1)
			colourStore1 = 4'b1000;
			
		else if(colour[2] == 1)
			colourStore1 = 4'b0100;
			
		else if(colour[1] == 1)
			colourStore1 = 4'b0010;
		else if (colour[0]==1)
			colourStore1 = 4'b0001;
	
		
	// player 2 below
	/*
		if (colour[3] == 1)
			colourStore2 = 4'b1000;
			
		else if(colour[2] == 1)
			colourStore2 = 4'b0100;
			
		else if(colour[1] == 1)
			colourStore2 = 4'b0010;
		else if (colour[0]==1)
			colourStore2 = 4'b0001;	
		end*/
end
	assign colourLEDs[0] = colourStore1[0];
	assign colourLEDs[1] = colourStore1[1];
	assign colourLEDs[2] = colourStore1[2];
	assign colourLEDs[3] = colourStore1[3];
	assign colourLEDs[4] = colourStore2[0];
	assign colourLEDs[5] = colourStore2[1];
	assign colourLEDs[6] = colourStore2[2];
	assign colourLEDs[7] = colourStore2[3];

	
always @(colourStore1,colourStore2)
	begin
	// Display the current colour being stored.
	case(colourStore1)
	4'b0001: storeHex1 = 7'b1111010; //r 
	4'b0010: storeHex1 = 7'b1000100; //y
	4'b0100: storeHex1 = 7'b1100000; //b
	4'b1000: storeHex1 = 7'b0000100; //g
	default: storeHex1 = 7'b1111111; //off
	endcase
	
	
	Player1[3:0] = colourStore1;
	
	
	
	Player2[3:0] = colourStore2;
	
		

		
	case(colourStore2)
	4'b0001: storeHex2 = 7'b1111010; //r 
	4'b0010: storeHex2 = 7'b1000100; //y
	4'b0100: storeHex2 = 7'b1100000; //b
	4'b1000: storeHex2 = 7'b0000100; //g
	default: storeHex2 = 7'b1111111; //off
	endcase 
	

	end  
//----- Update VGA colour based on pixel location and imageDisplay module (KE) -----//	
	always @(posedge clk)
		if(img_on)
		begin
			vga_R = gvga_R;
			vga_G = gvga_G;
			vga_B = gvga_B;
		end 
		 
endmodule		

// VGA output control module
// Written by: Keeley Edwards
module imageDisplay (colour, LevelOut, player, match, win, pix_x, pix_y, vga_R, vga_G, vga_B, video_on);
	input  match, win;
	input player; 
	input [3:0] colour;
	input [2:0] LevelOut;
	input [9:0] pix_x, pix_y;
	output reg [7:0] vga_R, vga_G, vga_B;
	output reg video_on;
	
	//constant declaration
	localparam Max_X = 788;
	localparam Max_Y = 490;
	
	//Square Buttons
	localparam button_spacing = 25;
	localparam button_size = 50;
	localparam RED_X_L = 315;
	localparam RED_X_R = RED_X_L + button_size;
	localparam RED_Y_T = 250;
	localparam RED_Y_B = RED_Y_T + button_size;
	localparam YEL_X_L = RED_X_R + button_spacing;
	localparam YEL_X_R = YEL_X_L + button_size;
	localparam YEL_Y_T = 250;
	localparam YEL_Y_B = YEL_Y_T + button_size;
	localparam BLU_X_L = YEL_X_R + button_spacing;
	localparam BLU_X_R = BLU_X_L + button_size;
	localparam BLU_Y_T = 250;
	localparam BLU_Y_B = BLU_Y_T + button_size;
	localparam GRN_X_L = BLU_X_R + button_spacing;
	localparam GRN_X_R = GRN_X_L + button_size;
	localparam GRN_Y_T = 250;
	localparam GRN_Y_B = GRN_Y_T + button_size;

	//status signals
	wire redB_on, yelB_on, grnB_on, bluB_on, bounding_box;
	reg bright;
	
	//pixel in red button
	assign redB_on = ((RED_X_L <= pix_x) && (pix_x <= RED_X_R) &&
							(RED_Y_T <= pix_y) && (pix_y <= RED_Y_B));

	//pixel in yellow button
	assign yelB_on = ((YEL_X_L <= pix_x) && (pix_x <= YEL_X_R) &&
							(YEL_Y_T <= pix_y) && (pix_y <= YEL_Y_B));
						
	//pixel in green button
	assign grnB_on = ((GRN_X_L <= pix_x) && (pix_x <= GRN_X_R) &&
							(GRN_Y_T <= pix_y) && (pix_y <= GRN_Y_B));
						
	//pixel in blue button
	assign bluB_on = ((BLU_X_L <= pix_x) && (pix_x <= BLU_X_R) &&
							(BLU_Y_T <= pix_y) && (pix_y <= BLU_Y_B));

							
	//pixel is in bounding box
	assign bounding_box = (pix_x == 250 && pix_y <= 450 && 100 <= pix_y) | 
									(pix_x == 650 && pix_y <= 450 && 100 <= pix_y) | 
										(pix_y == 100 && pix_x <= 650 && 250 <= pix_x) |
											(pix_y == 450 && pix_x <= 650 && 250 <= pix_x);
	

//-------------Display the Letter L for level--------------//
wire [2:0] L_addr, L_col;
reg [7:0] L_data;
wire L_bit;
wire L_on;

always@*
		case (L_addr)
		3'b000: L_data = 8'b00000000; //
		3'b001: L_data = 8'b01000000; // *
		3'b010: L_data = 8'b01000000; // *
		3'b011: L_data = 8'b01000000; // *
		3'b100: L_data = 8'b01000000; // *
		3'b101: L_data = 8'b01000000; // *
		3'b110: L_data = 8'b01111110; // ******
		3'b111: L_data = 8'b00000000; //
		endcase

	assign L_addr = pix_y[3:1];
	assign L_col = pix_x[3:1];
	assign L_bit = L_data[~L_col];
	
	assign L_on = (256<=pix_x && pix_x<=271 && 112<= pix_y && pix_y <= 127 && L_bit);	

//-------------Display the number 1 or 2 to identify which player is playing--------------//
wire [2:0] P1_addr, P1_col;
reg [7:0] P1_data;
wire P1_bit;
wire P1_on;

always@*
		case (P1_addr)
		3'b000: P1_data = 8'b00000000; //
		3'b001: P1_data = 8'b00011000; //   **
		3'b010: P1_data = 8'b00101000; //  * *
		3'b011: P1_data = 8'b00001000;//     *
		3'b100: P1_data = 8'b00001000; //    *
		3'b101: P1_data = 8'b00001000; //    *
		3'b110: P1_data = 8'b00001000; //    *
		3'b111: P1_data = 8'b01111110; //  *****
		endcase


	assign P1_addr = pix_y[4:2];
	assign P1_col = pix_x[4:2];
	assign P1_bit = P1_data[~P1_col];
	
	assign P1_on = (416<=pix_x && pix_x<=447 && 192<= pix_y && pix_y <= 224 && P1_bit && player ==0);		


wire [2:0] P2_addr, P2_col;
reg [7:0] P2_data;
wire P2_bit;
wire P2_on;

always@*
		case (P2_addr)
		3'b000: P2_data = 8'b00000000; //
		3'b001: P2_data = 8'b00111100; //  ****
		3'b010: P2_data = 8'b01000010; // *    *
		3'b011: P2_data = 8'b00000100; //     *
		3'b100: P2_data = 8'b00001000; //    *
		3'b101: P2_data = 8'b00010000; //   *
		3'b110: P2_data = 8'b00100000; //  *
		3'b111: P2_data = 8'b01111110; // ******
		endcase

	assign P2_addr = pix_y[4:2];
	assign P2_col = pix_x[4:2];
	assign P2_bit = P2_data[~P2_col];
	
	assign P2_on = (480<=pix_x && pix_x<=511 && 192<= pix_y && pix_y <= 224 && P2_bit && player==1);	

//-------------Display the Check Mark to indicate a match--------------//
wire [2:0] match_addr, match_col;
reg [7:0] match_data;
wire match_bit;
wire match_on;

always@*
		case (match_addr)
		3'b000: match_data = 8'b00000000; //       
		3'b001: match_data = 8'b00000001; //       *
		3'b010: match_data = 8'b00000010; //      *
		3'b011: match_data = 8'b00000100; //     *
		3'b100: match_data = 8'b10001000; //*   *
		3'b101: match_data = 8'b01010000; // * *
		3'b110: match_data = 8'b00100000; //  *
		3'b111: match_data = 8'b00000000; //
		endcase

	assign match_addr = pix_y[4:2];
	assign match_col = pix_x[4:2];
	assign match_bit = match_data[~match_col];
	
	assign match_on = (544<=pix_x && pix_x<=575 && 192<= pix_y && pix_y <= 224 && match_bit && match);


//----- Display the current level as a number -----//

wire [2:0] num_addr, num_col;
reg [7:0] num_data;
wire num_bit;
wire num_on;

always@*
	if (LevelOut == 0)
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b00011000; //   **
		3'b010: num_data = 8'b00101000; //  * *
		3'b011: num_data = 8'b00001000; //    *
		3'b100: num_data = 8'b00001000; //    *
		3'b101: num_data = 8'b00001000; //    *
		3'b110: num_data = 8'b00111110; //  *****
		3'b111: num_data = 8'b00000000; //
		endcase
		
	else if (LevelOut == 1)
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b00111100; //  ****
		3'b010: num_data = 8'b01000010; // *    *
		3'b011: num_data = 8'b00000100; //     *
		3'b100: num_data = 8'b00001000; //    *
		3'b101: num_data = 8'b00010000; //   *
		3'b110: num_data = 8'b01111110; // ******
		3'b111: num_data = 8'b00000000; //
		endcase
		
	else if (LevelOut ==2)
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b00111100; //  ****
		3'b010: num_data = 8'b01000010; // *    *
		3'b011: num_data = 8'b00001100; //    **
		3'b100: num_data = 8'b00000010; //      *
		3'b101: num_data = 8'b01000010; // *    *
		3'b110: num_data = 8'b00111100; //  ****
		3'b111: num_data = 8'b00000000; //
		endcase
		
	else if (LevelOut ==3)
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b01000010; // *    *
		3'b010: num_data = 8'b01000010; // *    *
		3'b011: num_data = 8'b01111110; // ******
		3'b100: num_data = 8'b00000010; //      *
		3'b101: num_data = 8'b00000010; //      *
		3'b110: num_data = 8'b00000010; //      *
		3'b111: num_data = 8'b00000000; //
		endcase
		
	else if (LevelOut ==4)
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b01111110; // ******
		3'b010: num_data = 8'b01000000; // *    
		3'b011: num_data = 8'b01111100; // *****
		3'b100: num_data = 8'b00000010; //      *
		3'b101: num_data = 8'b01000010; // *    *
		3'b110: num_data = 8'b00111100; //  ****
		3'b111: num_data = 8'b00000000; //
		endcase
		
	else
		case (num_addr)
		3'b000: num_data = 8'b00000000; //
		3'b001: num_data = 8'b00000000; //
		3'b010: num_data = 8'b00000000; //
		3'b011: num_data = 8'b00000000; //
		3'b100: num_data = 8'b00000000; //
		3'b101: num_data = 8'b00000000; //
		3'b110: num_data = 8'b00000000; //
		3'b111: num_data = 8'b00000000; //
		endcase

	assign num_addr = pix_y[3:1];
	assign num_col = pix_x[3:1];
	assign num_bit = num_data[~num_col];
	
	assign num_on = (272<=pix_x && pix_x<=287 && 112<= pix_y && pix_y <= 127 && num_bit);
		
//----- Colour Selection MUX -----//	
	//check if there is input - indicates need for a bright signal 
	always@(player)
		if (player || ~player)
			bright = 1;
		else
			bright = 0; 
	
	//Produce colour when the pixel is in the range of the button, boudning box or other indicator.
	always@*
	begin 
		if (bounding_box)
		begin
			video_on = 1;
			vga_R = 8'b11111111;
			vga_G = 8'b11111111;
			vga_B = 8'b11111111;
			end 
		// based on input verus rest: assign lit versus unlit colour to each button.
		else if (redB_on)
		begin
			video_on = 1;
			vga_G = 8'b00000000;
			vga_B = 8'b00000000;
			if (bright && colour[0])
				vga_R = 8'b11111111;
			else
				vga_R = 8'b01100000;
		end	
		else if (yelB_on)
		begin
			video_on = 1;
			if (bright && colour[1])
			begin
				vga_R = 8'b11111111;
				vga_G = 8'b11111111;
				vga_B = 8'b00000000;
			end 
			else
			begin
				vga_R = 8'b01111111;
				vga_G = 8'b01111111;
				vga_B = 8'b00110000;
			end
		end		
		else if (grnB_on)
		begin
			video_on = 1;
			vga_R = 8'b00000000;
			vga_B = 8'b00000000;
			if (bright && colour[3])
				vga_G = 8'b11111111;
			else 
				vga_G = 8'b01100000;
		end		
		else if (bluB_on)
		begin
			video_on = 1;
			vga_R = 8'b00000000;
			vga_G = 8'b00000000;
			if (bright && colour[2])
				vga_B = 8'b11111111;
			else
				vga_B = 8'b01100000;
		end
		else if (L_on || P1_on || P2_on || match_on || num_on)
		begin
		if (num_on && win)		//shows the number 5 in green if the player wins
			begin
			video_on = 1;
			vga_R = 8'b00000000;
			vga_G = 8'b11111111;
			vga_B = 8'b00000000;
			end
		else
			begin
			video_on = 1;
			vga_R = 8'b11111111;
			vga_G = 8'b11111111;
			vga_B = 8'b11111111;
			end
		end
		else
		begin
			vga_R = 8'b00000000;
			vga_G = 8'b00000000;
			vga_B = 8'b00000000;
			end
			end
			
endmodule			


//KeyBoard			
module keyboard (
  input clk,
  input PS2_DATA,
  input PS2_CLOCK,
  output reg [7:0] rxdata,
  output reg datafetched
); 

parameter idle    = 2'b01;
parameter receive = 2'b10;
parameter ready   = 2'b11;

reg [7:0] previousKey; 
reg [1:0]  state=idle;
reg [15:0] rxtimeout=16'b0000000000000000;
reg [10:0] rxregister=11'b11111111111;
reg [1:0]  datasr=2'b11;
reg [1:0]  clksr=2'b11;



reg rxactive;
reg dataready;
  
always @(posedge clk ) 
begin 
  rxtimeout<=rxtimeout+1;
  datasr <= {datasr[0],PS2_DATA};
  clksr  <= {clksr[0],PS2_CLOCK};


  if(clksr==2'b10)
    rxregister<= {datasr[1],rxregister[10:1]};


  case (state) 
    idle: 
    begin
      rxregister <=11'b11111111111;
      rxactive   <=0;
      dataready  <=0;
		datafetched <=0;
      rxtimeout  <=16'b0000000000000000;
      if(datasr[1]==0 && clksr[1]==1)
      begin
        state<=receive;
        rxactive<=1;
      end   
    end
    
    receive:
    begin
      if(rxtimeout==50000)
        state<=idle;
      else if(rxregister[0]==0)
      begin
        dataready<=1;
        rxdata<=rxregister[8:1];
        state<=ready;
        datafetched<=1;
      end
    end
    
    ready: 
    begin
      if(datafetched==1)
      begin
        state     <=idle;
        dataready <=0;
        rxactive  <=0;
		  datafetched <=0;
      end  
    end  
  endcase
end 
endmodule

/*endmodule 

// Store module
// Written by: Keeley Edwards and Ainslee Heim

module store(colourStore, player, match, LevelNumber, Player1, Player2, storeHex,win,colour,clk);
//
input [3:0] colourStore;
input player,clk;
output reg [2:0] LevelNumber;
output reg win;
output reg [0:6] storeHex;
output reg [3:0] Player1, Player2;
reg [3:0] i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11;
reg [3:0] j1,j2,j3,j4,j5,j6,j7,j8,j9,j10,j11;
input [3:0] colour;
output reg match;

always @(colourStore)
	begin
// Display the current colour being stored.
	case(colourStore)
	4'b0001: storeHex = 7'b1111010; //r 
	4'b0010: storeHex = 7'b1000100; //y
	4'b0100: storeHex = 7'b1100000; //b
	4'b1000: storeHex = 7'b0000100; //g
	default: storeHex = 7'b1111111; //off
	endcase 

		
	if(player==0)
		Player1[3:0] = colourStore;
	else	
		Player2[3:0] = colourStore;

	end 
	
always @(*)	
	begin
			case(colourStore)
			4'b0001: Player2[3:0] = colourStore;
			4'b0010: Player2[3:0] = colourStore;
			4'b0100: Player2[3:0] = colourStore;
			4'b1000: Player2[3:0] = colourStore;
			default: Player2[3:0] = 4'b0000;
			endcase
	 
			case(colourStore)
			4'b0001: j1 = colourStore;
			4'b0010: j1 = colourStore;
			4'b0100: j1 = colourStore;
			4'b1000: j1 = colourStore;
			default: j1 = 0;
			endcase 

			case(colourStore)
			4'b0001: j2 = colourStore;
			4'b0010: j2 = colourStore;
			4'b0100: j2 = colourStore;
   		4'b1000: j2 = colourStore;
			default: j2 = 0;
			endcase 

			case(colourStore)
			4'b0001: j3 = colourStore;
			4'b0010: j3 = colourStore;
			4'b0100: j3 = colourStore;
			4'b1000: j3 = colourStore;
			default: j3 = 0;
			endcase 
end
always@(posedge clk)
begin
	 if (LevelNumber == 1)
		begin
		if (i1 == 0)
				i1 <= colour;
			else if (i2 == 0)
				i2 <= colour;
			else if (i3 == 0)
				i3 <= colour;
			else if (i4 == 0)
				i4 <= colour;
			else if (i5 == 0)
				i5 <= colour;
		if(player == 0)
			Player1[9:0] = {i5, i4, i3, i2, i1};
		else
			begin
			Player2[9:0] = {j5, j4, j3, j2, j1};
			if(Player2[9:0] == Player1[9:0])
			begin
				LevelNumber <= 2;
				match <= 1;
				Player1 <= 0;
				Player2 <= 0;
			end
			end
		end
		else if (LevelNumber == 2)
		begin
			if (i1 == 0)
				i1 <= colour;
			else if (i2 == 0)
				i2 <= colour;
			else if (i3 == 0)
				i3 <= colour;
			else if (i4 == 0)
				i4 <= colour;
			else if (i5 == 0)
				i5 <= colour;
			else if (i6 == 0)
				i6 <= colour;
			else if (i7 == 0)
				i7 <= colour;
		if(player == 0)
			Player1[13:0] <= {i7, i6, i5, i4, i3, i2, i1};
		else
			begin
			Player2[13:0] <= {j7, j6, j5, j4, j3, j2, j1};
			if(Player2[13:0] == Player1[13:0])
			begin
				LevelNumber <= 3;
				match = 1;
				Player1 <= 0;
				Player2 <= 0;
			end
			end
		end
	else if (LevelNumber == 3)
		begin
			if (i1 == 0)
				i1 <= colour;
			else if (i2 == 0)
				i2 <= colour;
			else if (i3 == 0)
				i3 <= colour;
			else if (i4 == 0)
				i4 <= colour;
			else if (i5 == 0)
				i5 <= colour;
			else if (i6 == 0)
				i6 <= colour;
			else if (i7 == 0)
				i7 <= colour;
			else if (i8 == 0)
				i8 <= colour;
			else if (i9 == 0)
				i9 <= colour;
		if(player == 0)
			Player1[17:0] = {i9, i8, i7, i6, i5, i4, i3, i2, i1};
		else
			begin
			Player2[17:0] = {j9, j8, j7, j6, j5, j4, j3, j2, j1};
			if(Player2[17:0] == Player1[17:0])
			begin
				LevelNumber <= 4;
				match = 1;
				Player1 = 0;
				Player2 = 0;
			end
			end
		end
	else if (LevelNumber == 4)
		begin
			if (i1 == 0)
				i1 <= colour;
			else if (i2 == 0)
				i2 <= colour;
			else if (i3 == 0)
				i3 <= colour;
			else if (i4 == 0)
				i4 <= colour;
			else if (i5 == 0)
				i5 <= colour;
			else if (i6 == 0)
				i6 <= colour;
			else if (i7 == 0)
				i7 <= colour;
			else if (i8 == 0)
				i8 <= colour;
			else if (i9 == 0)
				i9 <= colour;
			else if (i10 == 0)
				i10 <= colour;
			else if (i11 == 0)
				i11 <= colour;
				//end for loop
		if(player == 0)
			Player1[21:0] = {i11, i10, i9, i8, i7, i6, i5, i4, i3, i2, i1};
		else
			begin
			Player2[21:0] = {j11, j10, j9, j8, j7, j6, j5, j4, j3, j2, j1};
			if(Player2[21:0] == Player1[21:0])
			begin
				win = 1;
				match = 1;
				Player1 = 0;
				Player2 = 0;
			end
			end
		end
	end */
//endmodule 
