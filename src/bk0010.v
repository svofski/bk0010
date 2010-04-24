// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. BK-0010 Main Module.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

module bk0010(
		clk50,
		clk25,
		reset_in,
		PS2_Clk, PS2_Data,
		button0,
		pdb,
		astb,
		dstb,
		pwr,
		pwait,
		iTCK,
		oTDO,
		iTDI,
		iTCS,
		greenleds,
		switch,
		ram_addr,
		ram_a_data,
		ram_a_ce,
		ram_a_lb,
		ram_a_ub,
		ram_we_n,
		ram_oe_n,
		RED,GREEN,BLUE,vs,hs,
		tape_out,
		tape_in,
		cpu_rd,
		cpu_wt,
		cpu_oe_n,
		_cpu_inst,
		cpu_adr,
		redleds,
		cpu_opcode,
		ram_out_data
	);

input 				clk50, clk25;
input 				button0;
input 				PS2_Clk, PS2_Data;

inout	[7:0] 		pdb;
input 				astb;
input 				dstb;
input 				pwr;
output 				pwait;
input 				iTCK, iTDI, iTCS;
output 				oTDO;

output 				cpu_rd,cpu_wt,cpu_oe_n;
output	[7:0] 		greenleds;
output 				_cpu_inst;
output 	[15:0]		cpu_adr;
input	[7:0] 		switch;

output 	[17:0] 		ram_addr;
inout 	[15:0] 		ram_a_data;
output 				ram_a_ce;
output 				ram_a_lb;
output 				ram_a_ub;
output 				ram_we_n;
output 				ram_oe_n;

output				tape_out;
input				tape_in;

input 				reset_in;

output 	reg			RED,GREEN,BLUE;
output				vs,hs;

output	[7:0]		redleds;
output  [15:0]		cpu_opcode;
output  [15:0]      ram_out_data;

wire 			kbd_data_wr;
wire 			video_access;
wire[9:0] 		screen_x;
wire[9:0] 		screen_y;
wire       		valid;
wire       		R,G,B;
wire        	color;
wire 			vga_oe_n;           // 0= ram data output to shifter
reg [1:0] 		vga_state;
reg [1:0] 		next_vga_state;

wire[17:0] 		usb_addr;
wire[15:0] 		usb_a_data;
wire 			usb_a_lb;
wire 			usb_a_ub;
wire 			usb_we_n;
wire 			usb_oe_n;           // 0= ram data output to usb
reg [1:0] 		usb_clk;

wire[12:0] 		vga_addr;
reg [15:0] 		data_to_interface;

wire 			RST_IN;
wire 			AUD_CLK;

wire 			kbd_available;


reg [23:0] 		cntr;               // slow counter for heartbeat LED

wire 			b0_debounced;
wire 			stop_run;

wire [7:0] 		led_from_usb;

wire 			cpu_lb, cpu_ub;


wire [15:0] 	cpu_out;
wire 			cpu_wt;
wire 			cpu_rd;
wire 			cpu_byte;
wire 			single_step;
wire 			cpu_pause;          // switch-controlled CPU pause (SW7)
wire 			clk_cpu;            // 25 MHz clock
wire            ce_cpu;             // CPU clock enable 
wire            ce_shifter_load;    // latch data into pixel shifter
reg [4:0] 		clk_cpu_count;
wire 			cpu_oe_n;           // 0= ram data output to cpu
wire 			cpu_we_n;           // 0= cpu outputs data to ram
wire 			read_kbd;

wire [7:0] 		roll;

reg [15:0] 		latched_ram_data;
reg [15:0] 		data_from_cpu;

reg [1:0] 		one_shot;


assign      single_step = switch[6];
assign      cpu_pause = switch[7];

assign      ce_cpu    = cpu_pause && (screen_x[3:0] == 3'b0110 || screen_x[3:0] == 3'b0101);
assign      clk_cpu   = clk25;

assign      ce_shifter_load = screen_x[3:0] == 4'b0000;


assign greenleds = {cpu_rdy, b0_debounced, kbd_available, usb_we_n, ram_we_n, cpu_we_n, cpu_wt, cntr[23]};

assign cpu_lb = cpu_byte & cpu_adr[0];  // if byte LOW, lb low. If even addr, low too 
assign cpu_ub = cpu_byte & ~cpu_adr[0];


/*
   debounce debounce(.pb_debounced(b0_debounced), .pb(button0), .clock_100Hz(cntr[16]));
  
   run_control run_control (.clk(clk_cpu_count[2]),.reset_in(reset_in), 
   					.start(b0_debounced), .stop(stop_run), .active(cpu_rdy ));
				//	.start(button0), .stop(stop_run));

				//	assign cpu_rdy = 1;

	wire cpu_rdy = 1;
*/
	

reg cpu_rdy;

reg b0samp;
always @(posedge clk_cpu) 
    if (ce_cpu) b0samp <= button0;

always @(posedge clk_cpu) begin
	if (reset_in) begin
		cpu_rdy <= 1;
		jtag_hlda <= 0;
	end 
	else if (ce_cpu) begin
		if (jtag_hold | single_step) begin
			cpu_rdy <= 0;
			jtag_hlda <= 1;
		end
		else begin
			cpu_rdy <= 1;
			jtag_hlda <= 0;
		end
		
		if (~b0samp & button0) cpu_rdy <= 1; // allow button click-step
	end
end

// ------------ simple breakpoint
wire breakpoint_latch = 0;
wire match_hit = 0;
/*
reg breakpoint_latch;
reg match_hit;

always @(negedge clk_cpu_buff) begin
    if (reset_in) begin
        breakpoint_latch <= 1'b0;
    end else begin
        if (_cpu_inst) begin
            case (cpu_adr)
            //'o100132, // EMT dispatch: JSR PC, (R5)
            //'o100742, // EMT 4 
            //'o110474          // draw a line at (R3) with contents of R1
            //'o110514            // exit from ^^
            //'o111130            // draw column marks
            //                :	match_hit <= 1'b1;
            
            
            default:		match_hit <= 1'b0;
            endcase
        end

        if (match_hit) breakpoint_latch <= 1'b1;
        if (~b0samp & button0) breakpoint_latch <= 1'b0;
    end
end
*/

// vga state machine runs on 50 MHz clock
always @(posedge clk50) begin
	if(reset_in) 
		vga_state <= 0;
	else begin
		vga_state <= next_vga_state;
	end
end

wire [6:0] ascii;
wire [7:0] kbd_data;
assign kbd_data = {1'b0, ascii};

wire CPU_reset;

wire [15:0] match_val_u;
wire [15:0] match_mask_u;
wire cpu_rdy_final;

assign CPU_reset = reset_in | led_from_usb[0]; 
assign stop_run = (cpu_rd & single_step) | (match_hit & led_from_usb[2]) ;
assign cpu_rdy_final = cpu_rdy &  ~breakpoint_latch;
   
/*
   match bp_match (
    .inp_val(inp_val), 
    .match_val(match_val_u), 
    .mask(match_mask_u), 
    .hit(match_hit)
    );
*/


wire kbd_stopkey;
wire kbd_keydown;
wire kbd_ar2;

 bkcore core (
    .p_reset(CPU_reset), 
    .m_clock(clk_cpu), 
    .ce(ce_cpu),
    .cpu_rdy(cpu_rdy_final), 
    .wt(cpu_wt), 
    .rd(cpu_rd), 
    .in(latched_ram_data), 
    .out(cpu_out), 
    .adr(cpu_adr), 
    .byte(cpu_byte),
    ._cpu_inst(_cpu_inst),
	.cpu_opcode(cpu_opcode),
    .kbd_data(kbd_data), 
    .kbd_available(kbd_available),
    .read_kbd(read_kbd),
    .roll_out(roll),
	.stopkey(kbd_stopkey),
	.keydown(kbd_keydown),
	.kbd_ar2(kbd_ar2),
	.tape_out(tape_out),
	.tape_in(tape_in),
	.redleds(redleds),
	.testselect(switch[3:2])
    );


// SEQ is here
reg [2:0] 		seq;

always @(posedge clk25) begin
	if(reset_in) begin
		clk_cpu_count <= 0;
		seq <= 0;
		one_shot <= 0;
	end
	else begin
		clk_cpu_count <= clk_cpu_count + 1;
		seq <= {seq[1:0],( cpu_rd | cpu_wt) & ce_cpu };
		one_shot <= {one_shot[0], ( cpu_rd | cpu_wt)};
	end
end  

assign cpu_oe_n = ~(cpu_rd & (seq[2] == 0) & (seq[0] == 1) & cpu_rdy ); 
assign cpu_we_n = ~(cpu_wt & (seq[1:0]== 2'b01) ); // FIXME


always @(posedge clk25) begin
	if(~cpu_oe_n & (seq == 3'b001))
		latched_ram_data <= ram_a_data;
end

always data_to_interface = ram_a_data;

//always @(posedge clk25) begin
//	if(~usb_oe_n)
//		data_to_interface = ram_a_data;
//end

//always @(negedge clk25) begin
//	if(cpu_wt)
//	   data_from_cpu <= cpu_out;
//end
always data_from_cpu <= cpu_out;

`ifdef WITH_USB
usbintf usb_intf (
    .mclk(usb_clk[1]), 
    .reset_in(reset_in), 
    .pdb(pdb), 
    .astb(astb), 
    .dstb(dstb), 
    .pwr(pwr), 
    .pwait(pwait), 
    .led(led_from_usb), 
    .switch(read_cap), 	// use this input for captured data
    .ram_addr(usb_addr), 
    .usb_ouT_data(usb_a_data),
    .in_ramdata(data_to_interface), 
    .ram_a_lb(usb_a_lb), 
    .ram_a_ub(usb_a_ub), 
    .ram_we(usb_we_n), 
    .ram_oe(usb_oe_n),
    .cap_rd(cap_rd), 
    .cap_rd_sel(cap_rd_sel),
    .match_val_u(match_val_u),
	.match_mask_u (match_mask_u)
 );
`endif
`ifdef WITH_DE1_JTAG

wire jtag_hold;
reg  jtag_hlda;
wire jtag_oe; // active high
wire jtag_we_n; // active low
assign usb_oe_n = ~jtag_oe;
assign usb_we_n = jtag_we_n;

jtag_top jtagger(
	.clk24(clk25),
	.reset_n(~reset_in),
	.oHOLD(jtag_hold),
	.iHLDA(jtag_hlda),
	.iTCK(iTCK),
	.oTDO(oTDO),
	.iTDI(iTDI),
	.iTCS(iTCS),
	.oJTAG_ADDR(usb_addr),
	.iJTAG_DATA_TO_HOST(ram_a_data/*data_to_interface*/),
	.oJTAG_DATA_FROM_HOST(usb_a_data),
	.oJTAG_SRAM_WR_N(jtag_we_n),
	.oJTAG_SELECT(jtag_oe)
);
assign usb_a_lb = 0;
assign usb_a_ub = 0;
`else
assign usb_we_n = 1;
assign usb_oe_n = 1;
`endif
   
sync_gen25 syncgen( .clk(clk25), .res(reset_in), .CounterX(screen_x), .CounterY(screen_y), 
		   .Valid(valid), .vga_h_sync(hs), .vga_v_sync(vs));

shifter shifter(.clk25(clk25),.color(color),.R(R),.G(G),.B(B),
	   .valid(valid),.data(ram_a_data),.x(screen_x),.load_i(ce_shifter_load));


assign RST_IN = 1'b0;
assign vga_addr = { screen_y[8:1] - 'o0330 + roll , screen_x[8:4]};

reg [15:0] ram_addr;
always @*
	casex ({~(cpu_oe_n & cpu_we_n),~(usb_we_n & usb_oe_n)})
		2'b10:		ram_addr <= {1'b0, cpu_adr[15:1]};
		2'bx1:		ram_addr <= usb_addr;
		default:	ram_addr <= {5'b00001, vga_addr};
	endcase

reg [15:0] ram_out_data;
always @*
	casex ({~cpu_we_n,~usb_we_n}) 
		2'b10:		ram_out_data <= data_from_cpu;
		2'bx1:		ram_out_data <= usb_a_data;
		default: 	ram_out_data <= data_from_cpu;
	endcase

	
/*
assign ram_addr = ~(cpu_oe_n & cpu_we_n) ? {1'b0, cpu_adr[15:1]}: // cpu has top priority
	~(usb_we_n & usb_oe_n)? usb_addr:			// usb if needed 
	 {5'b00001, vga_addr};

wire [15:0] ram_out_data = ~cpu_we_n ? data_from_cpu: ~usb_we_n ? usb_a_data : 16'h ffff;
*/

	
assign ram_a_ce = 0; // always on

assign ram_a_data =  ~cpu_we_n? data_from_cpu: 
				~usb_we_n ? usb_a_data : 
				16'b zzzzzzzzzzzzzzzz ;

assign ram_a_lb = ~( cpu_oe_n & cpu_we_n )? cpu_lb:
			~( usb_oe_n & usb_we_n )? usb_a_lb: 0;
  	  
assign ram_a_ub = ~( cpu_oe_n & cpu_we_n )? cpu_ub:
			~( usb_oe_n & usb_we_n )? usb_a_ub: 0;
  
  
assign ram_oe_n = usb_oe_n & vga_oe_n & cpu_oe_n; // either one active low
assign ram_we_n = usb_we_n & cpu_we_n;            // video never writes


assign      color = switch[0];

assign      video_access = ce_shifter_load; /* & switch[1]*/  // always read video data at the first half of a cycle 
   
assign vga_oe_n = ~video_access;

always @(posedge clk25) begin
	if(reset_in)
		usb_clk <= 0;
	else
		usb_clk <= usb_clk + 1;
end
   

wire show_char_line =  0;//((screen_y[9:4] == 6'b 100001) & ~screen_x[9]); // line after the valid screen
wire char_bit;

always @(posedge clk25) begin
if (valid) begin
		RED = R;
		GREEN = G;
		BLUE	=B;
end  
else	begin
  if(show_char_line) begin
		RED = char_bit;
		GREEN = char_bit;
		BLUE	= char_bit;
	end
	else	 begin
		RED = 0;
		GREEN = 0;
		BLUE	=0;
	end
end
end


always @(posedge clk25) begin
    cntr <= cntr + 1'b 1;
end

kbd_intf kbd_intf (
    .mclk25(clk25), 
    .reset_in(reset_in), 
    .PS2_Clk(PS2_Clk), 
    .PS2_Data(PS2_Data), 
    .ascii(ascii), 
    .kbd_available(kbd_available), 
    .read_kb(read_kbd),
	.key_stop(kbd_stopkey),
	.key_down(kbd_keydown),
	.ar2(kbd_ar2),
    );




/*
wire char_rom_cs, char_rom_rw; 
wire [10:0] char_rom_addr; 
wire [7:0] char_rom_rdata; 
wire [7:0] char_rom_wdata;
wire [3:0] char_line;

wire [6:0] char_code;

wire [2:0] sel_bit;

assign char_line = screen_y[3:0];
assign  char_rom_rw = 1;
assign  char_rom_cs = 1;
assign   char_rom_wdata = 0;

assign  sel_bit = ~screen_x[2:0];
assign  char_code = screen_x[9:3]+ 'h30;
assign  char_rom_addr = {char_code, char_line};
assign  char_bit = char_rom_rdata[sel_bit];

  char_rom char_rom (
    .clk(clk25), 
    .rst(reset_in), 
    .cs(char_rom_cs), 
    .rw(char_rom_rw), 
    .addr(char_rom_addr), 
    .rdata(char_rom_rdata), 
    .wdata(char_rom_wdata)
    );
*/

/*
wire [7:0]read_cap;
wire [2:0]cap_rd_sel;
wire cap_rd;

wire [3:0] capt_flags;
wire cap_wr;
assign cap_wr = ((cpu_rd | cpu_wt) & (seq[1:0] == 2'b01) & cpu_rdy);

assign capt_flags = { cpu_byte, _cpu_inst, cpu_rd , cpu_wt};

   capture capture (
    .res(reset_in), 
    .clk25(clk25), 
    .cap_addr(cpu_adr), 
    .cap_dat(ram_a_data),
    .flags(capt_flags), 
    .cap_wr(cap_wr), 
    .read_cap_l(read_cap), 
    .cap_rd(cap_rd), 
    .cap_rd_sel(cap_rd_sel)
    );

*/   
   


  
endmodule
