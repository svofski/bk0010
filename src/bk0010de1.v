// ==================================================================================
//                                      BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. Top level module for Altera DE1 board.
//
// Original POP-11 code and sfl2vl conversion Copyright(C) 2003 Prof.Naohiko Shimizu
// Original BK code, 1801VM1 ALU, 1801VM1 Instruction Decoder Copyright(C) 2005 Alex Freed	
// BK code, DE1 adaptation Copyright(C) 2008 Viacheslav Slavinsky
//
// For POP-11 licensing terms see README
// (In short form it makes this project only valid for academic purposes)
//
// For BK-0010 licensing terms see README
// ==================================================================================

// this is a user-side cloning test

`default_nettype none

`define WITH_DE1_JTAG
`define JTAG_AUTOHOLD
//`define DATAPATH_ON_NEGEDGE

module bk0010de1(
		CLOCK_27, 
		clk50mhz, 
		KEY[3:0], 
		LEDr[9:0], 
		LEDg[7:0], 
		SW[9:0], 
		HEX0, HEX1, HEX2, HEX3, 
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		 
		VGA_HS,
		VGA_VS,
		VGA_R,
		VGA_G,
		VGA_B, 
		
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		
		AUD_BCLK, 
		AUD_DACDAT, 
		AUD_DACLRCK,
		AUD_XCK,
		AUD_ADCLRCK,
		AUD_ADCDAT,

		PS2_CLK,
		PS2_DAT,

		////////////////////	USB JTAG link	////////////////////
		TDI,  							// CPLD -> FPGA (data in)
		TCK,  							// CPLD -> FPGA (clk)
		TCS,  							// CPLD -> FPGA (CS)
	    TDO,  							// FPGA -> CPLD (data out)

		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		
		///////////////////// USRAT //////////////////////
		UART_TXD,
		UART_RXD,

		// TEST PIN
		GPIO_0
);
input [1:0]		CLOCK_27;
input			clk50mhz;
input [3:0] 	KEY;
output [9:0] 	LEDr;
output [7:0] 	LEDg;
input [9:0] 	SW; 

output [6:0] 	HEX0;
output [6:0] 	HEX1;
output [6:0] 	HEX2;
output [6:0] 	HEX3;

////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable

/////// VGA
output 			VGA_HS;
output 			VGA_VS;
output	[3:0] 	VGA_R;
output	[3:0] 	VGA_G;
output	[3:0] 	VGA_B;

////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock

inout			AUD_BCLK;
output			AUD_DACDAT;
output			AUD_DACLRCK;
output			AUD_XCK;

output			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data


input			PS2_CLK;
input			PS2_DAT;

////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)

////////////////////	SD Card Interface	////////////////////////
input			SD_DAT;					//	SD Card Data 			(MISO)
output			SD_DAT3;				//	SD Card Data 3 			(CSn)
output			SD_CMD;					//	SD Card Command Signal	(MOSI)
output			SD_CLK;					//	SD Card Clock			(SCK)

output			UART_TXD;
input			UART_RXD;

output [12:0] 	GPIO_0;


wire			RST_IN = ~KEY[0];

// CLOCKS

wire			clk50;
wire			clk25;
wire			aud_clk;

altplla cloxor(.areset(RST_IN), 
		.inclk0(clk50mhz), 
		.c0(clk50), 
		.c1(clk25), 
		.c2(aud_clk));

assign 			AUD_XCK = aud_clk;
wire [7:0]		ay_sound;
wire 			tape_out;
wire			tape_in;

I2C_AV_Config 		u7(clk25,~RST_IN,I2C_SCLK,I2C_SDAT);

/*
soundcodec soundnik(
					.clk18(aud_clk), 
					.pulses({tape_out, 3'b0}), 
					.pcm(ay_sound),
					.tapein(tape_in), 
					.reset_n(~RST_IN),
					.oAUD_XCK(AUD_XCK),
					.oAUD_BCK(AUD_BCLK), 
					.oAUD_DATA(AUD_DACDAT),
					.oAUD_LRCK(AUD_DACLRCK),
					.iAUD_ADCDAT(AUD_ADCDAT), 
					.oAUD_ADCLRCK(AUD_ADCLRCK)
				   );
*/
assign GPIO_0[4] = tape_in;
assign GPIO_0[0] = clkcpu;

wire clkcpu;
wire [15:0] cpu_addr;

wire ifetch;

reg     hypercharge;

bk0010 elektronika(
		.clk50(clk50),
		.clk25(clk25),
		.reset_in(RST_IN),
		.PS2_Clk(PS2_CLK), .PS2_Data(PS2_DAT),
		.button0(~KEY[2]),
		.greenleds(LEDg),
		.switch(SW[7:0]),

		.iTCK(TCK),
		.oTDO(TDO),
		.iTDI(TDI),
		.iTCS(TCS),

		.ram_addr(SRAM_ADDR),
		.ram_a_data(SRAM_DQ),
		.ram_a_ce(SRAM_CE_N),
		.ram_a_lb(SRAM_LB_N),
		.ram_a_ub(SRAM_UB_N),
		.ram_we_n(SRAM_WE_N),
		.ram_oe_n(SRAM_OE_N),

		.RED(VGA_R[3]),
		.GREEN(VGA_G[3]),
		.BLUE(VGA_B[3]),
		.vs(VGA_VS),
		.hs(VGA_HS),
		
		.tape_out(tape_out),
		.tape_in(tape_in),
		
		.cpu_rd(GPIO_0[1]),
		.cpu_wt(GPIO_0[2]),
		.cpu_oe_n(GPIO_0[3]),
		.ifetch(ifetch),
		.cpu_adr(cpu_addr),
		.cpu_opcode(cpu_opcode),
		.cpu_sp(cpu_sp),
		.redleds(LEDr[7:0]),
		.ram_out_data(ram_out_data),
		.hypercharge_i(hypercharge),
		);
		
reg  [15:0] cpu_addr_reg;
wire [15:0] cpu_opcode, cpu_sp, ram_out_data;

reg [15:0] hexdisplay;
always 	case (SW[5:4])
		'b00:	hexdisplay = cpu_addr_reg;
		'b01:	hexdisplay = cpu_sp;
		'b10:	hexdisplay = cpu_opcode;
		'b11:	hexdisplay = ~SRAM_WE_N ? ram_out_data : SRAM_DQ;
		endcase

SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3,  hexdisplay);

always @(posedge clk25) begin
	if (ifetch) cpu_addr_reg <= cpu_addr;
end

reg [15:0] debctr;
reg        debsamp;
always @(posedge clk25) begin
    if (RST_IN) begin
        hypercharge <= 0;
        debsamp <= 0;
    end else begin
        if (~KEY[3])    
            debctr <= 16'hffff;
        else
            if (|debctr)    debctr <= debctr - 1;
        
        debsamp <= |debctr;
        
        if (~debsamp && |debctr)    hypercharge <= ~hypercharge;
    end
end

assign LEDr[9] = hypercharge;

endmodule
