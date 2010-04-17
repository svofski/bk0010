// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. Keyboard interface.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

`default_nettype none

module kbd_intf(mclk25, reset_in, PS2_Clk, PS2_Data, shift, ar2, ascii, kbd_available, read_kb, key_stop, key_down);

input 				mclk25, reset_in, read_kb;
input 				PS2_Clk,PS2_Data;

output 				shift, ar2, kbd_available;
   
output 				key_stop;
output reg 			key_down;		// any key is down

reg    [2:0] 		kbd_state;	
reg    [2:0] 		kbd_state_next;
reg 				shift;
reg 				ctrl;
reg 				alt;
reg    [7:0]		code_latched;
reg 				kbd_available;

wire				autoar2;		// AR2 forced by special keys (e.g. POVT)
output [6:0] 		ascii;
wire   [6:0] 		decoded;
wire   [7:0] 		Scan_Code;
wire 				DoRead;
wire 				Scan_Err;
wire 				Scan_DAV;

assign ar2 = alt | autoar2;

PS2_Ctrl PS2_Ctrl (
    .Clk(mclk25), 
    .Reset(reset_in), 
    .PS2_Clk(PS2_Clk), 
    .PS2_Data(PS2_Data), 
    .DoRead(DoRead), 
    .Scan_Err(Scan_Err), 
    .Scan_DAV(Scan_DAV), 
    .Scan_Code(Scan_Code)
    );

assign  DoRead = Scan_DAV;

kbd_transl kbd_transl( .shift(shift), .incode(code_latched), .outcode(decoded), .autoar2(autoar2));	


assign ascii = ctrl? {2'b0, decoded[4:0]} : decoded;

wire scan_shift = Scan_Code == 8'h12;
wire scan_ctrl  = Scan_Code == 8'h14;
wire scan_alt   = Scan_Code == 8'h11;
wire scan_stop  = Scan_Code == 8'h07;

always @(posedge mclk25 ) begin	
	if(reset_in) begin
		shift <= 0;
		ctrl <= 0;
		alt <= 0;
		stop_ctr <= 0;
	end
	else begin
		if( kbd_state == 1) begin
			if (scan_shift)
				shift <= 1;
			else if (scan_ctrl)
				ctrl <= 1;
			else if (scan_alt)
				alt <= 1;
			else if (scan_stop) begin
				stop_ctr <= 1;
			end
		end 
		else if( kbd_state == 6) begin
			if(scan_shift)
				shift <= 0;
			else if (scan_ctrl)
				ctrl <= 0;
			else if (scan_alt)
				alt <= 0;
		end
		
		if (stop_ctr != 0) stop_ctr <= stop_ctr + 1;
	end
end //always


reg [15:0] stop_ctr;

assign key_stop = stop_ctr[7:0] != 0 && stop_ctr[15:8] == 0;
 
always @(posedge mclk25) begin
	if(reset_in) begin
		kbd_state <= 0;
		code_latched <= 0;
		kbd_available <= 0;
	end
	else begin
		kbd_state <= kbd_state_next;
		if(read_kb)
			kbd_available <= 0;
		if( kbd_state == 7)	begin
			if (!key_down) begin
				code_latched <= Scan_Code;
				kbd_available <= 1;
				key_down <= 1;
			end
		end	
		else if (kbd_state == 6) begin
			key_down <= 0;
		end
	end
end

always @ (kbd_state or Scan_Code or Scan_DAV) begin
	case (kbd_state)
	0:	if( Scan_DAV)
			kbd_state_next <= 1;
		else
			kbd_state_next <= 0;

	1:   // have something, get it
		kbd_state_next <= 2;

	2:	if(Scan_Code == 8'hf0)
			kbd_state_next <= 3;
		else if(Scan_Code == 8'hE0)
			kbd_state_next <= 0;
		else if(scan_shift | scan_ctrl | scan_alt | scan_stop) begin
			kbd_state_next <= 0;
		end
		else
			kbd_state_next <= 7;

	3:	// was F0	 wait a couple of states for 	Scan_DAV to go down
		kbd_state_next <= 4;

	4:
		kbd_state_next <= 5;

	5:	if( Scan_DAV)	// wait for more
			kbd_state_next <= 6;
		else
			kbd_state_next <= 5;

	6:	kbd_state_next <= 0;

	7:  kbd_state_next <= 0;
	
	default: 
		kbd_state_next <= 0;
	endcase
end

endmodule
