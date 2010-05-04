// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. Miscellaneous modules.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

module debounce(pb_debounced, pb, clock_100Hz);
input pb, clock_100Hz;
output pb_debounced;
reg [3:0] shift;
reg pb_debounced;

// filters out mechanical switch bounce for about 40ms,
// provided that the debounce clock is approximately 10ms (100Hz)
always @ (posedge clock_100Hz)
begin
	shift[2:0] <= shift[3:1];
	shift[3] <= pb;
	if (shift==4'b0000) pb_debounced <= 1'b0; 
	else pb_debounced <= 1'b1;
end 
endmodule



module run_control(clk,reset_in, start, stop, active);
input clk, reset_in, start, stop;
output active;

reg [1:0] run_state;
reg [1:0] run_state_next;
  assign active = run_state[0];
  always @(posedge clk) begin
    	if(reset_in) 
    		run_state <= 1;
    	else 
    		run_state <= run_state_next;
  end

  always @(run_state or run_state_next or start or stop) begin
  	case (run_state)
	0:	if(start)
			if(stop)
				run_state_next <= 3;
			 else
			 	run_state_next <= 1;

	1:	if(stop)
			run_state_next <= 2;

	2:  	if(~start)
			run_state_next <= 0;

	3:	if(!stop)	
			run_state_next <= 1;
	endcase

  end

endmodule



module hex_7seg(hex_digit,a,b,c,d,e,f,g);
input [3:0] hex_digit;
output a,b,c,d,e,f,g;
reg [6:0] seg;

always @ (hex_digit)
case (hex_digit)
	4'b0000 : seg = 7'b1111110; // 0
	4'b0001 : seg = 7'b0110000; // 1
	4'b0010 : seg = 7'b1101101; // 2
	4'b0011 : seg = 7'b1111001; // 3
	4'b0100 : seg = 7'b0110011; // 4
	4'b0101 : seg = 7'b1011011; // 5
	4'b0110 : seg = 7'b1011111; // 6
	4'b0111 : seg = 7'b1110000; // 7
	4'b1000 : seg = 7'b1111111; // 8
	4'b1001 : seg = 7'b1111011; // 9 
	4'b1010 : seg = 7'b1110111; // A
	4'b1011 : seg = 7'b0011111; // b 
	4'b1100 : seg = 7'b1001110; // C 
	4'b1101 : seg = 7'b0111101; // d 
	4'b1110 : seg = 7'b1001111; // E
	4'b1111 : seg = 7'b1000111; // F
	default : seg = 7'b0111110; // U
endcase

// extract segment data and LED driver is inverted
assign {a,b,c,d,e,f,g} = ~seg;
endmodule

