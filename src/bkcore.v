// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

`default_nettype none

module bkcore(
        input               reset_n,        // master reset, active low
        input               clk,            // core clock 
        input               ce,             // core clock enable
        input               cpu_rdy,        // ???
        output              wt,             // core writes to memory
        output              rd,             // core reads memory
        input               reply_i,        // memory reply
        input       [15:0]  ram_data_i,     // data from ram 
        output reg  [15:0]  ram_data_o,     // data to ram
        output      [17:0]  adr,            // address 
        output              byte,           // byte access
        output              ifetch,         // instruction fetch cycle
        
        output              bootrom_sel,     // boot rom active, rom area writable
        
        output              cpumode_o,      // o: 0 = kernel, 1 = user
        
        input               kbd_available,  // i: key available 
        input        [7:0]  kbd_data,       // i: key code
        input               kbd_ar2,        // i: AR2 modifier
        output              read_kbd,       // o: key read confirmation
        input               stopkey,        // i: STOP key pressed
        input               superkey,       // i: SUPER (ScrollLock) key pressed
        input               keydown,        // i: a key is being depressed
        
        output       [7:0]  roll_out,       // o: scroll register value
        output              full_screen_o,  // o: 1 == full screen, 0 == extended RAM mode
        input               tape_in,        // i: tape in bit
        output reg          tape_out,       // o: tape out/sound bit
        
        output reg          spi_wren,
        input               spi_dsr,
        output reg    [7:0] spi_do,
        input         [7:0] spi_di,
        output reg          spi_cs_n,
        

        // scary stuff
        input        [1:0]  testselect,
        output reg   [7:0]  redleds,
        output      [15:0]  cpu_opcode
`ifdef WITH_RTEST   
        ,
        output      [15:0]  cpu_sp,
        output     [143:0]  cpu_registers
`endif        
    );

wire    [2:0]   _Arbiter_cpu_pri;
wire    [7:0]   _Arbiter_vector;

reg     [15:0]  databus_in;         // CPU data in, see data_to_cpu and :_databus_selector

wire    [15:0]  data_from_cpu;
wire    [15:0]  _cpu_adrs;
wire            _cpu_irq_in;
wire            _cpu_error;
wire            _cpu_rd;
wire            _cpu_wt;
wire            _cpu_byte;
wire            _cpu_int_ack;

wire            rom_space;
wire            ram_space;
wire            reg_space;

reg             bad_addr;

  
reg             kbdint_enable_n; // bit 6 in 177660
reg     [7:0]   init_reg_hi;
reg     [15:0]  roll;


wire            cpu_rdy_internal;


wire    [15:0]  kbd_int_vector = kbd_ar2 ? 'o0274: 'o060;

wire    [15:0]  data_to_cpu = (_cpu_int_ack) ? kbd_int_vector : databus_in;


wire     [7:0]  test_control, test_bus;

// switch [3:2]
always @*
    case (testselect)
    2'b00:  redleds <= test_control;
    2'b01:  redleds <= test_bus;
    2'b10:  redleds <= 0;
    2'b11:  redleds <= 0;
    endcase

wire [15:0] cpu_data_o;
wire [15:0] cpu_psw;

vm1 cpu(.clk(clk), 
        .ce(ce),
        .reset_n(reset_n),
        .IFETCH(ifetch),
        .data_i(data_to_cpu),
        .data_o(data_from_cpu),
        .addr_o(_cpu_adrs),

        .error_i(_cpu_error),      
        .RPLY(reply_i | reg_reply),
        
        .usermode_i(cpumode_req_acked),
        .psw(cpu_psw),

        .DIN(_cpu_rd),          // o: data in
        .DOUT(_cpu_wt),         // o: data out
        .WTBT(_cpu_byte),       // o: byteio op/odd address
           
        .VIRQ(_cpu_irq_in),     // i: vector interrupt request
        .IRQ1(1'b0),            // i: console interrupt
        .IRQ2(1'b0),            // i: trap to 0100
        .IRQ3(1'b0),            // i: trap to 0270
        .IAKO(_cpu_int_ack),    // o: interrupt ack, DIN requests vector
        
        .test_control(test_control),
        .test_bus(test_bus),
        .OPCODE(cpu_opcode),
`ifdef WITH_RTEST   
        .Rtest(cpu_registers)
`endif      
        );      
        
`ifdef WITH_RTEST   
assign cpu_sp = cpu_registers[111:96];          
`endif 


//---------------------------------------------
// RPLY generator for register space
//---------------------------------------------

reg     reg_reply;
wire    cpu_io = _cpu_wt | _cpu_rd;

always @* ram_data_o <= (_cpu_byte & _cpu_adrs[0])? {data_from_cpu[7:0], data_from_cpu[7:0]} : data_from_cpu;

always @(posedge clk) begin
    if (reg_space & cpu_io & ~reg_reply)
        reg_reply <= 1;
    else
        if (ce) reg_reply <= 0;
end
//---------------------------------------------


assign roll_out = roll[7:0];
assign full_screen_o = roll[9];
assign cpu_rdy_internal = cpu_rdy & ~bad_addr;

assign adr = physical_addr; //_cpu_adrs;

assign byte = _cpu_byte;
assign wt = _cpu_wt & (ram_space | bootrom_sel);
assign rd = _cpu_rd & (ram_space | rom_space);

assign reg_space = _cpu_adrs[15:7] == 9'b111111111;

wire   mmu_page_writable;
assign ram_space =  mmu_page_writable & ~reg_space;     // formerly:    ~_cpu_adrs[15];
assign rom_space = ~mmu_page_writable & ~reg_space;     // formerly:    _cpu_adrs[15] & ~reg_space;

assign  bootrom_sel = shadowmode & _cpu_adrs[15] & ~reg_space;


wire     cpu_mode = cpu_psw[15];   // 0 = kernel, 1 = user

assign   cpumode_o = cpu_mode;

reg      cpumode_req; // bit 2 in MMUCTRL, the mode gets set on RTI/RTT or IRQ

// Totally incompatible MMU register space: 
// KISA0-KISA7: 177600 - 177616 (0 000 000 - 0 001 110)
// UISA0-UISA7: 177620 - 177636 (0 010 000 - 0 011 110)
// Mapping control: 177700
// No descriptor regs, only plain mapping

parameter 
    KBD_STATE = 0,
    KBD_DATA = 1,
    ROLL = 2,
    INITREG = 3,
    USRREG = 4,
    MMUREGS = 5,
    MMUCTRL = 6,
    TIMERREGS = 7,
    ENIGMA700 = 8,       // 177700 in user mode
    LASTREGSEL = 8;
    
wire        [LASTREGSEL:0] regsel;

wire [6:0] evenreg = {_cpu_adrs[6:1],1'b0};

assign regsel[KBD_STATE] = (evenreg == 'o060);
assign regsel[KBD_DATA]  = (evenreg == 'o062);
assign regsel[ROLL]      = (evenreg == 'o064);
assign regsel[INITREG]   = (evenreg == 'o116);
assign regsel[USRREG]    = (evenreg == 'o114);
assign regsel[TIMERREGS] = (evenreg == 'o106 || evenreg == 'o110 || evenreg == 'o112); 

assign regsel[ENIGMA700] = (_cpu_adrs[6:0] == 'o100) & cpu_mode;    // same reg as MMUCTRL but in user mode

assign regsel[MMUREGS]   = (_cpu_adrs[6:5] == 2'b00) & ~cpu_mode;
assign regsel[MMUCTRL]   = (_cpu_adrs[6:0] == 'o100) & ~cpu_mode;

wire   bad_reg = ~|regsel;

assign read_kbd = _cpu_rd & reg_space & regsel[KBD_DATA] ;
assign _cpu_error = bad_addr | (ifetch & stopkey);

   
reg stopkey_latch;
reg initreg_access_latch;

// only the powerup value is 1, reset value is 0
reg shadowmode = 1'b1;
reg mmu_enabled = 1'b0;

always @(negedge reset_n) begin
    init_reg_hi  <= 8'b10000000; // CPU start address MSB, not used by POP-11
end

reg kbd_available_samp;
reg kbd_irq_r;

always @(posedge clk or negedge reset_n) 
    if (~reset_n) begin
        {kbd_available_samp,kbd_irq_r} <= 0;
    end
    else if (ce) begin
        kbd_available_samp <= kbd_available;
        if (kbd_irq_r & _cpu_int_ack) 
            kbd_irq_r <= 1'b0;
        else if (~kbd_available_samp & kbd_available) 
            kbd_irq_r <= 1'b1;
    end

assign _cpu_irq_in = kbd_irq_r & ~kbdint_enable_n;

wire emt36 = cpu_opcode == 16'o104036;

// superkey: resets to 0, but only when IAKO
// emt36 overrides cpumode_req to kernel mode
wire cpumode_req_acked = superkey ? ~_cpu_int_ack : cpumode_req;


always @(posedge clk or negedge reset_n) begin
    if(~reset_n) begin
        kbdint_enable_n <= 1'b0;
        bad_addr <= 1'b0;
        roll <= 'o01330;
        initreg_access_latch <= 0;
        spi_cs_n <= 1'b1;
        shadowmode <= 1'b1;
        mmu_enabled <= 1'b0;
        cpumode_req <= 1'b0;
    end
    else begin
        if (ce) begin
            spi_wren <= 1'b0;
            
            if (stopkey) stopkey_latch <= 1'b1;
            
            if ((superkey & _cpu_int_ack) | emt36) cpumode_req <= 1'b0; // latch kernel mode
            
            if (reg_space) begin
                if(bad_reg)
                    bad_addr <= 1;
                else begin  // good access to reg space
                    bad_addr <= 0;

                    if (_cpu_wt) begin // all reg writes
                        case (1)
                            regsel[KBD_STATE]:  kbdint_enable_n <= data_from_cpu[6];
                            regsel[ROLL]:       {roll[9],roll[7:0]} <= {data_from_cpu[9],data_from_cpu[7:0]};
                            regsel[INITREG]:    {tape_out,initreg_access_latch,spi_cs_n} <= {data_from_cpu[6], 1'b1,data_from_cpu[0]};
                            regsel[USRREG]:     {spi_wren,spi_do} <= {1'b1,data_from_cpu[7:0]};
                            regsel[MMUCTRL]:    {cpumode_req,mmu_enabled,shadowmode} <= data_from_cpu[2:0];
//                            regsel[ENIGMA700]:  ;// bit 2 in this reg switches CPU into WAIT mode
                        endcase
                    end
                    
                    if (_cpu_rd) begin
                        if (regsel[INITREG]) begin
                            stopkey_latch <= 1'b0;
                            initreg_access_latch <= 1'b0;
                        end
                    end // rd
                end // good access to reg space
            end  //reg space
            else if (rom_space & _cpu_wt & ~shadowmode) 
                bad_addr = 1;
            else if (_cpu_rd & ~reg_space) begin
                bad_addr = 0;
            end else begin
                bad_addr = 0; // don't hold error
            end
        end
    end
end

always @* begin: _databus_selector
    databus_in = 16'o177777;

    case (1'b1) 
    reg_space: 
        case (1)
            regsel[KBD_DATA]:   databus_in = {8'b0000000, kbd_data};
            regsel[KBD_STATE]:  databus_in = {8'b0000000, kbd_available, kbdint_enable_n, 6'b000000};
            regsel[INITREG]:    databus_in = {init_reg_hi, 1'b1, ~keydown, tape_in, 1'b0, 1'b0, stopkey_latch|initreg_access_latch, 1'b0,1'b0};
            regsel[ROLL]:       databus_in = roll;
            regsel[USRREG]:     databus_in = cpu_mode ? 16'o0 : {~spi_dsr, spi_di};      // this could be a joystick...
            regsel[TIMERREGS]:  databus_in = data_from_timer;
            regsel[ENIGMA700]:  databus_in = 16'o 177740;

            regsel[MMUREGS]:    databus_in = data_from_mmu;
            regsel[MMUCTRL]:    databus_in = {cpu_mode,cpumode_req,mmu_enabled,shadowmode};
        endcase
        
    ~reg_space:
        begin
            if( ~_cpu_byte)
                databus_in = ram_data_i;
            // byte read instructions
            else if(_cpu_adrs[0])
                databus_in = {8'b0000000, ram_data_i[15:8]} ;
            else
                databus_in = {8'b0000000, ram_data_i[7:0]} ;
        end
    endcase
    
end

wire [15:0] data_from_mmu;
wire [21:0] physical_addr;
wire        mmu_valid;

memmap mmu(
    .clk(clk),
    .ce(ce),
    .reset_n(reset_n),
    .regwr(_cpu_wt & reg_space & regsel[MMUREGS]),
    .regrd(_cpu_rd & reg_space & regsel[MMUREGS]),
    .data_i(data_from_cpu),
    .data_o(data_from_mmu),
    .valid_o(mmu_valid),
    .enable_i(mmu_enabled),
    .writable_o(mmu_page_writable),
    
    .mode(cpu_mode),      // 1 = User, 0 = Kernel
    .vaddr(_cpu_adrs),
    .phaddr(physical_addr),
);

wire [15:0] data_from_timer;
vptimer timenik(
    .clk(clk),
    .ce(ce),
    .reset_n(reset_n),
    .regwr(_cpu_wt & reg_space & regsel[TIMERREGS]),
    .regrd(_cpu_rd & reg_space & regsel[TIMERREGS]),
    .addr(_cpu_adrs[3:0]),
    .data_i(data_from_cpu),
    .data_o(data_from_timer),
);    


endmodule
