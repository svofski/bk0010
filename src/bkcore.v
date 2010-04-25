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
 p_reset, 
 m_clock,
 ce,
 cpu_rdy, 
 wt, 
 rd, 
 in,
 out, 
 adr, 
 byte,
 ifetch, _cpu_adrs, kbd_data, kbd_available, kbd_ar2, read_kbd, roll_out, stopkey, keydown, tape_in, tape_out,
 testselect,
 redleds,
 cpu_opcode, cpu_sp, cpu_registers);

input 			p_reset;
input			m_clock;
input           ce;
output 	[15:0] 	_cpu_adrs;
output 			ifetch, read_kbd;
input 			kbd_available;
input 	[7:0] 	kbd_data;
input			kbd_ar2;
output 	[7:0] 	roll_out;
input 			stopkey;
input			keydown;
input 			tape_in;
output reg		tape_out;
output 			wt;
output 			rd;
input	[15:0] 	in;
input       	cpu_rdy;
output reg[15:0] 	out;
output 	[15:0] 	adr;
output 			byte;
output reg[7:0]	redleds;
input	[1:0]	testselect;
output [15:0]	cpu_opcode, cpu_sp;
output [143:0]  cpu_registers;

wire 	[2:0] 	_Arbiter_cpu_pri;
wire 	[7:0] 	_Arbiter_vector;
reg 	[15:0] 	_cpu_dati;
wire 	[15:0] 	_cpu_dato;
wire 			_cpu_irq_in;
wire 			_cpu_error;
wire 			_cpu_rd;
reg 			_cpu_wt;
wire 			_cpu_byte;
wire 			_cpu_int_ack;
wire 	[7:0] 	_cpu_pswout;

wire 			rom_space;
wire 			ram_space;
wire 			reg_space;
wire 			bad_reg;
wire 			kbd_state_sel;
wire 			kbd_data_sel;
wire 			roll_sel;
wire 			initreg_sel;
wire 			usr_sel;


reg 			bad_addr;

  
reg 			kbd_int_flag; // bit 6 - IRQ en
reg 	[7:0] 	init_reg_hi;
reg 	[15:0] 	roll;


wire 			cpu_rdy_internal;


wire 	[15:0] 	cpu_dati;
wire 	[15:0] 	kbd_int_vector;

assign kbd_int_vector = kbd_ar2 ? 'o0274: 'o060;

assign cpu_dati = ( _cpu_int_ack)? kbd_int_vector : _cpu_dati;

/*
pop11 	cpu(.p_reset(p_reset), 
			.m_clock(m_clock), 
			.inst(ifetch), 
			.pswout(_cpu_pswout), 
			.int_ack(_cpu_int_ack), 
			.byte(_cpu_byte), 
			.wt(_cpu_wt), 
			.rd(_cpu_rd),
			.fault(_cpu_fault),
			.error(_cpu_error), 
			.rdy(cpu_rdy_internal),
			.irq_in(_cpu_irq_in),
			.adrs(_cpu_adrs), 
			.dato(_cpu_dato),
			.dati(cpu_dati)
			);
*/			

wire [7:0] test_control, test_bus;

// switch [3:2]
always @*
	case (testselect)
	2'b00:	redleds <= test_control;
	2'b01:	redleds <= test_bus;
	2'b10:	;
	2'b11:  ;
	endcase

wire mDOUT;

wire [15:0] cpu_data_o;

vm1 cpu(.clk(m_clock), 
        .ce(ce),
        .reset_n(~p_reset),
		.IFETCH(ifetch),
        .data_i(cpu_dati),
        .data_o(_cpu_dato),
        .addr_o(_cpu_adrs),

        .error_i(_cpu_error),      
		.SYNC(cpu_sync),
		.RPLY(cpu_rply),

        .DIN(_cpu_rd),          // o: data in
        .DOUT(mDOUT),           // o: data out
        .WTBT(_cpu_byte),       // o: byteio op/odd address
           
        .VIRQ(_cpu_irq_in),     // i: vector interrupt request
        .IRQ1(1'b0),            // i: console interrupt
        .IRQ2(1'b0),            // i: trap to 0100
        .IRQ3(1'b0),            // i: trap to 0270
        .IAKO(_cpu_int_ack),    // o: interrupt ack, DIN requests vector
        
		.test_control(test_control),
		.test_bus(test_bus),
		.OPCODE(cpu_opcode),
		.Rtest(cpu_registers)
        );		
        
assign cpu_sp = cpu_registers[111:96];        	

//----------------------
reg cpu_rply;
wire cpu_sync;

reg cpu_rplylatch;
reg syncsample;
always @(posedge m_clock) begin 
	if (p_reset) begin
		cpu_rplylatch <= 0;
		cpu_rply <= 0;
		out <= 0;
	end 
	else if (ce) begin
		syncsample <= cpu_sync;
		
		if (~syncsample & cpu_sync) begin
			cpu_rplylatch <= 1'b1;
			_cpu_wt <= mDOUT;
			if (mDOUT) begin
                out <= (_cpu_byte & _cpu_adrs[0])? {_cpu_dato[7:0], _cpu_dato[7:0]} :_cpu_dato;
            end
		end
		
		if (cpu_rplylatch) cpu_rply <= cpu_rdy_internal;

		if (~cpu_sync/*cpu_rply*/) begin
			cpu_rplylatch <= 1'b 0;
			cpu_rply <= 1'b 0;
			_cpu_wt <= 1'b 0;
		end
	end
end
//---------------------


assign roll_out = roll[7:0];
assign cpu_rdy_internal = cpu_rdy & ~bad_addr;
assign _Arbiter_cpu_pri = _cpu_pswout[7:5];

assign adr = _cpu_adrs;
assign byte = _cpu_byte;
assign wt = _cpu_wt & ram_space;// & ~m_clock;
assign rd = _cpu_rd & (ram_space | rom_space) ;// & ~m_clock;

//assign out = (_cpu_byte & _cpu_adrs[0])? {_cpu_dato[7:0], _cpu_dato[7:0]} :_cpu_dato;



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

always @(posedge p_reset) begin
	init_reg_hi  <= 8'b10000000; // CPU start address MSB, not used by POP-11
end

assign _cpu_irq_in = kbd_available & ~kbd_int_flag &(_Arbiter_cpu_pri == 0);

always @(posedge m_clock) begin
	if(p_reset) begin
	   kbd_int_flag <= 1'b0;
	   bad_addr <= 1'b0;
	   roll <= 'o01330;
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
						kbd_int_flag <= _cpu_dato[6];
					if(roll_sel)
						roll <= _cpu_dato;
					if (initreg_sel)
						tape_out <= _cpu_dato[6];
				end
				
				if(_cpu_rd) begin
					if(kbd_data_sel) begin
						_cpu_dati = {8'b0000000, kbd_data};
					end
					else if(kbd_state_sel)
						_cpu_dati = {8'b0000000, kbd_available, kbd_int_flag,6'b000000};
					else if(initreg_sel  ) begin
						_cpu_dati = {init_reg_hi, 1'b1, ~keydown, tape_in, 1'b1, 1'b1, stopkey_latch, 1'b0,1'b0};
						stopkey_latch <= 1'b0;
					end else if(roll_sel )
						_cpu_dati = roll;
				end // rd

			end // good access to reg space
		end	 //reg space
		else if (rom_space & _cpu_wt)
			bad_addr = 1;
		else if ( _cpu_rd & ~reg_space) begin
			bad_addr = 0;
			if( ~_cpu_byte)
				_cpu_dati = in;
			// byte read instructions
			else if(_cpu_adrs[0])
				_cpu_dati = {8'b0000000, in[15:8]} ;
			else
				_cpu_dati = {8'b0000000,in[7:0]} ;
		end else begin
			bad_addr = 0; // don't hold error
		end
	end
end


endmodule
