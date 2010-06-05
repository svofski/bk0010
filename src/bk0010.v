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
    input           clk50,
    input           clk25,
    input           reset_in,
    input           hypercharge_i,
    input           PS2_Clk, 
    input           PS2_Data,
    input           button0,

    input           iTCK,
    output          oTDO,
    input           iTDI,
    input           iTCS,

    input           SD_DAT,                         //  SD Card Data
    output          SD_DAT3,                        //  SD Card Data 3
    output          SD_CMD,                         //  SD Card Command Signal
    output          SD_CLK,                         //  SD Card Clock
        
    output    [7:0] greenleds,
    input     [7:0] switch,
    output   [17:0] ram_addr,
    inout    [15:0] ram_a_data,
    output          ram_a_ce,
    output          ram_a_lb,
    output          ram_a_ub,
    output          ram_we_n,
    output          ram_oe_n,
        
    output reg      VGA_RED,
    output reg      VGA_GREEN,
    output reg      VGA_BLUE,
    output          VGA_VS,
    output          VGA_HS,
            
    output          tape_out,
    input           tape_in,
    output          cpu_rd,
    output          cpu_wt,
    output reg      cpu_oe_n,
    output          ifetch,
    output   [17:0] cpu_adr,
    output    [7:0] redleds,
    output   [15:0] cpu_opcode,
    output   [15:0] cpu_sp,
    output   [15:0] ram_out_data
    );


wire            kbd_data_wr;
wire            video_access;
wire[9:0]       screen_x;
wire[9:0]       screen_y;
wire            valid;
wire            R,G,B;
wire            color;
wire            vga_oe_n;           // 0= ram data output to shifter
reg [1:0]       vga_state;
reg [1:0]       next_vga_state;

wire[17:0]      usb_addr;
wire[15:0]      usb_a_data;
wire            usb_a_lb;
wire            usb_a_ub;
wire            usb_we_n;
wire            usb_oe_n;           // 0= ram data output to usb

wire[12:0]      vga_addr;
reg [15:0]      data_to_interface;

wire            RST_IN;
wire            AUD_CLK;

wire            kbd_available;

wire [143:0]    cpu_registers;


reg [23:0]      heartbeat_cntr;     // slow counter for heartbeat LED

wire            b0_debounced;
//wire          stop_run;

wire [7:0]      led_from_usb;

wire            cpu_lb, cpu_ub;


wire [15:0]     data_from_cpu;
wire            cpu_byte;
wire            enable_bpts;        // 1 == hw breakpoints are enabled
wire            cpu_pause_n;        // switch-controlled CPU pause (SW7)
wire            clk_cpu;            // 25 MHz clock
reg             ce_cpu;             // CPU clock enable 
wire            ce_shifter_load;    // latch data into pixel shifter
reg [4:0]       clk_cpu_count;
reg             cpu_we_n;           // 0= cpu outputs data to ram
wire            read_kbd;

wire [7:0]      roll;
wire            full_screen;

reg [15:0]      latched_ram_data;


assign      enable_bpts = switch[6];
assign      cpu_pause_n = switch[7];

`ifdef CORE_25MHZ    
assign      clk_cpu   = clk25;
wire        cediv50   = 1'b1;
`else
assign      clk_cpu   = clk50;

reg         cediv50;
always @(posedge clk_cpu or negedge ~reset_in)
    if (reset_in)
        cediv50 <= 0;
    else
        cediv50 <= ~cediv50;
`endif


reg [4:0] tru_adjuster;
always @(posedge clk_cpu) begin
    if ({hypercharge_i|~cpumode,cpu_pause_n,screen_x[3:0]} == 6'b010101) begin
        if (tru_adjuster + 1'b1 == 11)
            tru_adjuster <= 0;
        else
            tru_adjuster <= tru_adjuster + 1'b1;
    end
end

wire tru_permit = ~tru_adjuster[3]; // 8 of 11

always @*
    casex({hypercharge_i|~cpumode,cpu_pause_n,screen_x[3:0]}) 
`ifdef CORE_25MHZ    
    6'b11xxxx:  ce_cpu <= screen_x[3:0] != 4'b1111 && screen_x[3:0] != 4'b1110;
    //6'b11xxxx:  ce_cpu <= |screen_x[3:0] && screen_x[3:0] != 4'b1111 && screen_x[3:0] != 4'b1110;
    6'b010101:  ce_cpu <= tru_permit;
`else
    6'b11xxxx:  ce_cpu <= screen_x[3:0] != 4'b1111 && screen_x[3:0] != 0; 
    6'b010101:  ce_cpu <= cediv50;
`endif    
    default:    ce_cpu <= 0;
    endcase


`ifdef CORE_25MHZ
assign      ce_shifter_load = screen_x[3:0] == 4'b0000; // seems to contradict with ce_cpu @ 0001, but it doesn't
`else
assign      ce_shifter_load = screen_x[3:0] == 4'b0000; 
`endif

assign greenleds = {cpu_rdy, b0_debounced, kbd_available, usb_we_n, ram_we_n, cpu_we_n, cpu_wt, heartbeat_cntr[20]};

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

always @(posedge clk25 or posedge reset_in) begin
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

always @(negedge clk_cpu or posedge reset_in) begin
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
always @(posedge clk50 or posedge reset_in) begin
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
wire kbd_superkey;
wire kbd_keydown;
wire kbd_ar2;

wire bootrom_sel;       // 1 == memory reads from bootrom
wire cpumode;           // 0 == kernel, 1 == user

 bkcore core (
    .reset_n(~CPU_reset), 
    .clk(clk_cpu), 
    .ce(ce_cpu),
    .cpu_rdy(cpu_rdy_final), 
    .wt(cpu_wt), 
    .rd(cpu_rd), 
    .reply_i(ram_reply),
    .ram_data_i(latched_ram_data), 
    .ram_data_o(data_from_cpu), 
    .adr(cpu_adr), 
    .byte(cpu_byte),
    .ifetch(ifetch),
    .cpumode_o(cpumode),
    
    .bootrom_sel(bootrom_sel),
    
    .cpu_opcode(cpu_opcode),
    .kbd_data(kbd_data), 
    .kbd_available(kbd_available),
    .read_kbd(read_kbd),
    .roll_out(roll),
    .full_screen_o(full_screen),
    .stopkey(kbd_stopkey),
    .superkey(kbd_superkey),
    .keydown(kbd_keydown),
    .kbd_ar2(kbd_ar2),
    .tape_out(tape_out),
    .tape_in(tape_in),
    .redleds(redleds),
    .testselect(switch[3:2]),
    
    .spi_wren(spi_wren),
    .spi_dsr(spi_dsr),
    .spi_do(spi_to_spi),
    .spi_di(spi_from_spi),
    .spi_cs_n(SD_DAT3),
    
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
            latched_ram_data <= bootrom_sel ? bootrom_data_o : ram_a_data;
            ram_reply <= 1;
        end else if (~cpu_we_n) begin
            ram_reply <= 1;
        end 
    end
end


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
           .Valid(valid), .vga_h_sync(VGA_HS), .vga_v_sync(VGA_VS));

shifter shifter(.clk25(clk25),.color(color),.R(R),.G(G),.B(B),
       .valid(valid),.data(ram_a_data),.x(screen_x),.load_i(ce_shifter_load));


assign RST_IN = 1'b0;
assign vga_addr = { screen_y[8:1] - 'o0330 + roll , screen_x[8:4]};


assign ram_addr = 
    ~(usb_we_n & usb_oe_n)? usb_addr:           
    ce_shifter_load ? {5'b00001, vga_addr} :
    {1'b0, cpu_adr[17:1]};

assign ram_out_data = ~cpu_we_n ? data_from_cpu: ~usb_we_n ? usb_a_data : 16'h ffff;


    
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

wire valid_full = valid && (full_screen || ~|screen_y[8:7]);

always @(posedge clk25) begin
    VGA_RED   = valid_full ? R : 0;
    VGA_GREEN = valid_full ? G : 0;
    VGA_BLUE  = valid_full ? B : 0;
end


always @(posedge clk25) begin
    heartbeat_cntr <= heartbeat_cntr + ce_cpu;
end

kbd_intf kbd_intf (
    .mclk(clk_cpu), 
    .reset_in(reset_in), 
    .PS2_Clk(PS2_Clk), 
    .PS2_Data(PS2_Data), 
    .ascii(ascii), 
    .kbd_available(kbd_available), 
    .read_kb(read_kbd),
    .key_stop(kbd_stopkey),
    .key_super(kbd_superkey),
    .key_down(kbd_keydown),
    .ar2(kbd_ar2),
    );
    
    
// SPI interface

wire        spi_wren;
wire        spi_dsr;
wire [7:0]  spi_to_spi;
wire [7:0]  spi_from_spi;

spi spi1(
    .clk(clk_cpu),
    .ce(1),
    .spi_ce(cediv50),
    .reset_n(~reset_in),
    .mosi(SD_CMD),
    .miso(SD_DAT),
    .sck(SD_CLK),
    .di(spi_to_spi),
    .do(spi_from_spi),
    .wr(spi_wren),
    .dsr(spi_dsr));

// Boot ROM

wire [15:0] bootrom_addr = cpu_adr[14:1]; // translate 0100000 -> 000000 and use word addresses
wire [15:0] bootrom_data_o;

bootrom bootrom1(
    .clock(clk_cpu),
    .address(bootrom_addr),
    .q(bootrom_data_o));
        

  
endmodule
