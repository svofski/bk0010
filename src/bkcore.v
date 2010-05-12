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
        input       	    cpu_rdy,        // ???
        output 			    wt,             // core writes to memory
        output 			    rd,             // core reads memory
        input               reply_i,        // memory reply
        input	    [15:0]  ram_data_i,     // data from ram 
        output reg  [15:0]  ram_data_o,     // data to ram
        output 	    [15:0]  adr,            // address 
        output              byte,           // byte access
        output 			    ifetch,         // instruction fetch cycle
        
        input               kbd_available,  // i: key available 
        input        [7:0]  kbd_data,       // i: key code
        input               kbd_ar2,        // i: AR2 modifier
        output              read_kbd,       // o: key read confirmation
        input               stopkey,        // i: STOP key pressed
        input               keydown,        // i: a key is being depressed
        
        output       [7:0]  roll_out,       // o: scroll register value
        output              full_screen_o,  // o: 1 == full screen, 0 == extended RAM mode
        input               tape_in,        // i: tape in bit
        output reg          tape_out,       // o: tape out/sound bit

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
wire    [7:0]   _cpu_pswout;

wire            rom_space;
wire            ram_space;
wire            reg_space;
wire            bad_reg;
wire            kbd_state_sel;
wire            kbd_data_sel;
wire            roll_sel;
wire            initreg_sel;
wire            usr_sel;


reg             bad_addr;

  
reg             kbd_int_flag; // bit 6 - IRQ en
reg     [7:0]   init_reg_hi;
reg     [15:0]  roll;


wire 			cpu_rdy_internal;


wire 	[15:0] 	kbd_int_vector = kbd_ar2 ? 'o0274: 'o060;

wire 	[15:0] 	data_to_cpu = (_cpu_int_ack) ? kbd_int_vector : databus_in;

wire     [7:0]  test_control, test_bus;

// switch [3:2]
always @*
	case (testselect)
	2'b00:	redleds <= test_control;
	2'b01:	redleds <= test_bus;
	2'b10:	;
	2'b11:  ;
	endcase

wire [15:0] cpu_data_o;

vm1 cpu(.clk(clk), 
        .ce(ce),
        .reset_n(reset_n),
		.IFETCH(ifetch),
        .data_i(data_to_cpu),
        .data_o(data_from_cpu),
        .addr_o(_cpu_adrs),

        .error_i(_cpu_error),      
		.RPLY(reply_i | reg_reply),

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

//
// A medium quick bus cycle: CPU notices RPLY on 3rd clock/ce
//
// Clock 0+: CPU sets DATI,SYNC   commands datapath to set DBA to PC
//           SYNC is 0, was 0
// Clock 0-: DBA <= PC: Address bus becomes valid
//                      ... 10ns async RAM sets data ...
// Clock 1+: SYNC is 1, was 0 --> RPLY <= 1 
// Clock 1-: Nothing of value happens
//
// Clock 2+: CPU sees RPLY == 1, DBI_R registers data, sets new datapath instructions, advances state
// Clock 2-: Datapath sets opcode from DBI_R, etc
// 	     
// DBI has valid data from RAM on Clock 1+, but the time is wasted on formalities.
//
//   0   1   2
//   _   _   _
// _/ \_/ \_/ \
// ___ __
// ___X__valid addr
//   ___
// _/ dati/SYNC
//    ___
// __/   \___ ~syncsample & sync
//        ____  
// ______/ RPLY
//
reg     reg_reply;
wire    cpu_sync = _cpu_wt | _cpu_rd;

reg     syncsample;

always @* ram_data_o <= (_cpu_byte & _cpu_adrs[0])? {data_from_cpu[7:0], data_from_cpu[7:0]} : data_from_cpu;

always @(posedge clk) begin
    if (ce) begin
        syncsample <= cpu_sync;
        if (cpu_sync & ~syncsample) begin
            if (reg_space) reg_reply <= 1'b1;
        end
        else if (~cpu_sync & syncsample & reg_reply) begin
            reg_reply <= 1'b0;
        end
    end
end
//---------------------


assign roll_out = roll[7:0];
assign full_screen_o = roll[9];
assign cpu_rdy_internal = cpu_rdy & ~bad_addr;
assign _Arbiter_cpu_pri = _cpu_pswout[7:5];

assign adr = _cpu_adrs;
assign byte = _cpu_byte;
assign wt = _cpu_wt & ram_space;
assign rd = _cpu_rd & (ram_space | rom_space);

// anything below 0x8000 is ram 
assign ram_space = ~_cpu_adrs[15];
assign reg_space = _cpu_adrs[15:7] == 9'b111111111;
assign rom_space = _cpu_adrs[15] & ~reg_space;

assign kbd_state_sel = (_cpu_adrs[6:0] == 'o060);
assign kbd_data_sel = (_cpu_adrs[6:0] == 'o062);
assign roll_sel = (_cpu_adrs[6:0] == 'o064);
assign initreg_sel = (_cpu_adrs[6:0] == 'o116);
assign usr_sel = (_cpu_adrs[6:0] == 'o114);
assign bad_reg = ~(kbd_state_sel | kbd_data_sel |roll_sel |initreg_sel | usr_sel );

assign read_kbd = kbd_data_sel;
assign _cpu_error = bad_addr | (ifetch & stopkey);

   
reg stopkey_latch;

reg initreg_access_latch;

always @(negedge reset_n) begin
	init_reg_hi  <= 8'b10000000; // CPU start address MSB, not used by POP-11
end

assign _cpu_irq_in = kbd_available & ~kbd_int_flag &(_Arbiter_cpu_pri == 0);

always @(posedge clk or negedge reset_n) begin
	if(~reset_n) begin
	   kbd_int_flag <= 1'b0;
	   bad_addr <= 1'b0;
	   roll <= 'o01330;
	   initreg_access_latch <= 0;
	end
	else if (ce) begin
		if (stopkey) stopkey_latch <= 1'b1;
		if (reg_space) begin
			if(bad_reg)
				bad_addr <= 1;
			else begin  // good access to reg space
				bad_addr <= 0;

				if( _cpu_wt) begin // all reg writes
					if( kbd_state_sel) 
						kbd_int_flag <= data_from_cpu[6];
					if(roll_sel)
						{roll[9],roll[7:0]} <= {data_from_cpu[9],data_from_cpu[7:0]};
					if (initreg_sel) begin
						tape_out <= data_from_cpu[6];
						initreg_access_latch <= 1'b1;
				    end
				end
				
				if(_cpu_rd) begin
					if (initreg_sel) begin
						stopkey_latch <= 1'b0;
						initreg_access_latch <= 1'b0;
					end
				end // rd
			end // good access to reg space
		end	 //reg space
		else if (rom_space & _cpu_wt)
			bad_addr = 1;
		else if (_cpu_rd & ~reg_space) begin
			bad_addr = 0;
		end else begin
			bad_addr = 0; // don't hold error
		end
	end
end

always @* begin: _databus_selector
    databus_in = 16'o177777;

	case (1'b1) 
	reg_space: 
        begin
            if(kbd_data_sel) begin
                databus_in = {8'b0000000, kbd_data};
            end
            else if(kbd_state_sel) begin
                databus_in = {8'b0000000, kbd_available, kbd_int_flag,6'b000000};
            end else if(initreg_sel  ) begin
                databus_in = {init_reg_hi, 1'b1, ~keydown, tape_in, 1'b0, 1'b0, stopkey_latch|initreg_access_latch, 1'b0,1'b0};
            end else if(roll_sel ) begin
                databus_in = roll;
            end else if (usr_sel) begin
                databus_in = 16'o0;     // this could be a joystick...
            end
		end	 //reg space
		
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



endmodule
