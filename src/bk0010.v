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

// Debug features available on DE1 (via DE1 Control Panel):
//  Write to address 0x8000: address of unconditional breakpoint
//  Read from addresses 0x8010-0x8018: contents of R0-R7 and PSW
//  SW[6] == 1 Enables breakpoints
//  KEY[2] skips past current location (sometimes)

module bk0010(
		clk50,
		clk25,
		reset_in,
		hypercharge_i,
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
		ifetch,
		cpu_adr,
		redleds,
		cpu_opcode, cpu_sp,
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
output 				ifetch;
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

input               hypercharge_i;

output 	reg			RED,GREEN,BLUE;
output				vs,hs;

output	[7:0]		redleds;
output  [15:0]		cpu_opcode, cpu_sp;

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

wire [143:0]    cpu_registers;


reg [23:0] 		cntr;               // slow counter for heartbeat LED

wire 			b0_debounced;
//wire 			stop_run;

wire [7:0] 		led_from_usb;

wire 			cpu_lb, cpu_ub;


wire [15:0] 	cpu_out;
wire 			cpu_wt;
wire 			cpu_rd;
wire 			cpu_byte;
wire 			enable_bpts;        // 1 == hw breakpoints are enabled
wire 			cpu_pause_n;        // switch-controlled CPU pause (SW7)
wire 			clk_cpu;            // 25 MHz clock
reg             ce_cpu;             // CPU clock enable 
wire            ce_shifter_load;    // latch data into pixel shifter
reg [4:0] 		clk_cpu_count;
reg             cpu_oe_n;           // 0= ram data output to cpu
reg             cpu_we_n;           // 0= cpu outputs data to ram
wire 			read_kbd;

wire [7:0] 		roll;
wire            full_screen;

reg [15:0] 		latched_ram_data;
reg [15:0] 		data_from_cpu;


assign      enable_bpts = switch[6];
assign      cpu_pause_n = switch[7];

`ifdef CORE_25MHZ    
assign      clk_cpu   = clk25;
`else
assign      clk_cpu   = clk50;

reg         cediv50;
always @(posedge clk_cpu or negedge ~reset_in)
    if (reset_in)
        cediv50 <= 0;
    else
        cediv50 <= ~cediv50;
`endif


always @*
    casex({hypercharge_i,cpu_pause_n,screen_x[3:0]}) 
`ifdef CORE_25MHZ    
    6'b11xxxx:  ce_cpu <= screen_x[3:0] != 4'b1111 && screen_x[3:0] != 4'b1110;
    //6'b11xxxx:  ce_cpu <= |screen_x[3:0] && screen_x[3:0] != 4'b1111 && screen_x[3:0] != 4'b1110;
    6'b010101:  ce_cpu <= 1;
`else
    6'b11xxxx:  ce_cpu <= screen_x[3:0] != 4'b1111 && screen_x[3:0] != 4'b1110; // @50MHz this leaves enough cycles for the last CPU access to complete, so no 1110
    6'b010101:  ce_cpu <= cediv50;
`endif    
    default:    ce_cpu <= 0;
    endcase


`ifdef CORE_25MHZ
assign      ce_shifter_load = screen_x[3:0] == 4'b0000; // seems to contradict with ce_cpu @ 0001, but it doesn't
`else
assign      ce_shifter_load = screen_x[3:0] == 4'b0000; 
`endif

assign greenleds = {cpu_rdy, b0_debounced, kbd_available, usb_we_n, ram_we_n, cpu_we_n, cpu_wt, cntr[23]};

assign cpu_lb = cpu_byte & cpu_adr[0];  // if byte LOW, lb low. If even addr, low too 
assign cpu_ub = cpu_byte & ~cpu_adr[0];

wire cpu_rdy = 1'b1;

reg b0samp;
    
reg [15:0] debounce_counter;    
always @(posedge clk_cpu) 
    if (ce_cpu) begin
        b0samp <= button0;
        if (~b0samp & button0) 
            debounce_counter <= 16'hffff;
        else
            if (|debounce_counter) debounce_counter <= debounce_counter - 1;
    end    

assign b0_debounced = |debounce_counter;    

always @(posedge clk25) begin
	if (reset_in) begin
		jtag_hlda <= 0;
	end 
	else if (~cpu_pause_n) begin
		if (jtag_hold) begin
			jtag_hlda <= 1;
		end
		else begin
			jtag_hlda <= 0;
		end
	end
end

// ------------ simple breakpoint
reg [15:0] breakpoint_addr;

always @*
    case (usb_addr)
    'h8010:         data_to_interface <= cpu_registers[15:0]   ;  // = R[0];
    'h8011:         data_to_interface <= cpu_registers[31:16]  ;   // = R[1];
    'h8012:         data_to_interface <= cpu_registers[47:32]  ;   // = R[2];
    'h8013:         data_to_interface <= cpu_registers[63:48]  ;   // = R[3];
    'h8014:         data_to_interface <= cpu_registers[79:64]  ;   // = R[4];
    'h8015:         data_to_interface <= cpu_registers[95:80]  ;   // = R[5];
    'h8016:         data_to_interface <= cpu_registers[111:96] ;   // = R[6];
    'h8017:         data_to_interface <= cpu_registers[127:112];  // = R[7];
    'h8018:         data_to_interface <= cpu_registers[143:128];  // = psw; 
    default:        data_to_interface <= ram_a_data;
    endcase

always@(posedge clk_cpu) begin
    if (~usb_we_n) begin
        if (usb_addr == 'h8000) begin
            breakpoint_addr <= usb_a_data;
        end
    end
end

reg breakpoint_latch;

always @(negedge clk_cpu) begin
    if (reset_in) begin
        breakpoint_latch <= 1'b0;
    end else 
    if (ce_cpu) begin
        if (enable_bpts) begin
            if (ifetch & cpu_rd) begin
                if (cpu_adr == breakpoint_addr) 
                        breakpoint_latch <= 1'b1;
            end
        end
        
        if (~b0samp & button0) begin
            breakpoint_latch <= 1'b0;
        end
    end
end


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
//assign stop_run = (cpu_rd & single_step) | (match_hit & led_from_usb[2]) ;
assign cpu_rdy_final = cpu_rdy &  ~breakpoint_latch;
   

wire kbd_stopkey;
wire kbd_keydown;
wire kbd_ar2;

 bkcore core (
    .reset_n(~CPU_reset), 
    .clk(clk_cpu), 
    .ce(ce_cpu),
    .cpu_rdy(cpu_rdy_final), 
    .wt(cpu_wt), 
    .rd(cpu_rd), 
    .reply_i(ram_reply),
    .ram_data_i(latched_ram_data), 
    .ram_data_o(cpu_out), 
    .adr(cpu_adr), 
    .byte(cpu_byte),
    .ifetch(ifetch),
	.cpu_opcode(cpu_opcode),
    .kbd_data(kbd_data), 
    .kbd_available(kbd_available),
    .read_kbd(read_kbd),
    .roll_out(roll),
    .full_screen_o(full_screen),
	.stopkey(kbd_stopkey),
	.keydown(kbd_keydown),
	.kbd_ar2(kbd_ar2),
	.tape_out(tape_out),
	.tape_in(tape_in),
	.redleds(redleds),
	.testselect(switch[3:2]),
`ifdef WITH_RTEST	
	.cpu_sp(cpu_sp),
	.cpu_registers(cpu_registers)
`endif	
    );
    
`ifndef WITH_RTEST
 assign cpu_registers = 0;
 assign cpu_sp = 0;
`endif    


// New RAM exchange cycle that takes place of the old SEQ

reg ram_reply;

always @(posedge clk_cpu or posedge reset_in) begin: _ramcycle
    if (reset_in) begin
        {cpu_oe_n,cpu_we_n} <= 2'b11;
        ram_reply <= 0;
    end else begin
        if (ce_cpu) begin
            ram_reply <= 0;
            cpu_oe_n <= (~cpu_rd) | ram_reply | ~cpu_oe_n;  
            cpu_we_n <= (~cpu_wt) | ram_reply | ~cpu_we_n;
        end else begin
            {cpu_oe_n,cpu_we_n} <= 2'b11;
        end
        
        if (~cpu_oe_n) begin
            latched_ram_data <= ram_a_data;
            ram_reply <= 1;
        end else if (~cpu_we_n) begin
            ram_reply <= 1;
        end 
    end
end


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

wire        jtag_hold;
reg         jtag_hlda;
wire        jtag_oe; // active high
wire        jtag_we_n; // active low
assign      usb_oe_n = cpu_pause_n | ~jtag_oe;        // only allow jtag access when SW[7] is 0
assign      usb_we_n = cpu_pause_n | jtag_we_n;       // only allow jtag access when SW[7] is 0

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
	.iJTAG_DATA_TO_HOST(data_to_interface),
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


assign ram_addr = 
	~(usb_we_n & usb_oe_n)? usb_addr:			
    ce_shifter_load ? {5'b00001, vga_addr} :
    {1'b0, cpu_adr[15:1]};

wire [15:0] ram_out_data = ~cpu_we_n ? data_from_cpu: ~usb_we_n ? usb_a_data : 16'h ffff;


	
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
   
assign      vga_oe_n = ~video_access;

always @(posedge clk25) begin
	if(reset_in)
		usb_clk <= 0;
	else
		usb_clk <= usb_clk + 1;
end
   

wire show_char_line =  0;//((screen_y[9:4] == 6'b 100001) & ~screen_x[9]); // line after the valid screen
wire char_bit;

wire valid_full = valid && (full_screen || ~|screen_y[8:7]);

always @(posedge clk25) begin
if (valid_full) begin
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

  
endmodule
