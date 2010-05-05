// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008 Viacheslav Slavinsky
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// 1801VM1 CPU Interface Module
// --------------------------------------------------------


`default_nettype none

//`define TESTBENCH

// 35ns/clk for negedge
// 15ns/clk for posedge/2
`define DATAPATH_ON_NEGEDGE

`include "opc.h"
`include "instr.h"

module vm1(clk, 
           ce,
           reset_n,
           data_i,
           data_o,
           addr_o,

           error_i,      
           
           SYNC,        // o: address set
           RPLY,        // i: reply to DIN or DOUT
           DIN,         // o: data in
           DOUT,        // o: data out
           WTBT,        // o: byteio op/odd address
           
           VIRQ,        // i: vector interrupt request
           IRQ1,        // i: console interrupt
           IRQ2,        // i: trap to 0100
           IRQ3,        // i: trap to 0270
           
           IAKO,        // o: interrupt ack, DIN requests vector
           
           DMR,         // i: DMA request
           DMGO,        // o: DMA offer
           SACK,        // i: DMA active
           
           BSY,         // o: CPU usurps bus
           
           INIT,        // o: peripheral INIT
           
           SEL1,        // o: 177716 i/o -- no REPLY needed
           SEL2,        // o: 177714 i/o -- no REPLY needed
           
		   IFETCH,		// o: indicates IF0

		   dati,
		   dato,
		   error_bus,
		   OPCODE,
		   PC,
           ALU1,
           ALUOUT, SRC, DST,
           ALUCC,
           idccat,
           psw,
           op_decoded,		
           test_control,
           test_bus,
           //dpcmd,
           Rtest,
           taken
           );

input           clk;
input           ce;
input           reset_n;
`ifdef TESTBENCH
output   [15:0]  data_i;
output           RPLY;        // i: reply to DIN or DOUT
`else
input   [15:0]  data_i;
input           RPLY;        // i: reply to DIN or DOUT
`endif
output  [15:0]  data_o;
output  [15:0]  addr_o;
input           error_i;
output          SYNC;        // o: address set
output          DIN;         // o: data in
output          DOUT;        // o: data out
output          WTBT;        // o: byteio op/odd address
           
input           VIRQ;        // i: vector interrupt request
input           IRQ1;        // i: console interrupt
input           IRQ2;        // i: trap to 0100
input           IRQ3;        // i: trap to 0270
           
output          IAKO;        // o: interrupt ack, DIN requests vector
           
input           DMR;         // i: DMA request
output          DMGO;        // o: DMA offer
input           SACK;        // i: DMA active
           
output          BSY;         // o: CPU usurps bus

output          INIT;        // o: peripheral INIT
           
output          SEL1;        // o: 177716 i/o -- no REPLY needed
output          SEL2;        // o: 177714 i/o -- no REPLY needed
output			IFETCH;
output			dati, dato;
output			error_bus;
output	[15:0]	PC;
output  [15:0]  ALU1;
output  [15:0]  ALUOUT, SRC, DST;
output	[7:0]	test_control;
output	[7:0]	test_bus;
output  [3:0]	ALUCC;
output 	[7:0]	idccat;
output	[15:0]	psw;
output			taken;
output	[15:0]	OPCODE;
//output  [127:0] dpcmd;
output	[143:0]	Rtest;

assign ALUCC = alucc;
assign idccat = {idc_unused,idc_cco,idc_bra,idc_nof,idc_rsd,idc_dop,idc_sop};
assign taken = dp_taken;
assign OPCODE = opcode;

`ifdef TESTBENCH
ram1024x16 burn(
	.address(ramadr),
	.clock(clk),
	.clken(ce),
	.data(data_o),
	.wren(DOUT),
	.q(data_i));
	
// simulate some seriouscat bus ram	

assign RPLY = ramreply;

reg [15:0] ramadr;
reg ramlatch;
reg ramreply;
reg syncsample;
always @(posedge clk) begin
	if (ctl_ce) begin
		syncsample <= SYNC;
		
		if (~syncsample & SYNC) begin
			ramadr <= (addr_o - 8'o 100000) >> 1;
			ramlatch <= 1'b1;
		end
		
		if (ramlatch) ramreply <= 1'b1;

		if (ramreply) begin
			ramlatch <= 0;
			ramreply <= 0;
		end
	end
end

`endif

wire	[127:0]			dpcmd;
wire	[15:0]			opcode;
output	[`IDC_NOPS:0] 	op_decoded;
wire 					idc_cco, idc_bra, idc_nof, idc_rsd, idc_dop, idc_sop, idc_unused;
wire	[15:0]			psw;
wire	[3:0]			alucc;
wire					dp_taken;
wire					error_bus;

wire					controlr_dati;
wire					controlr_dato;
wire					controlr_byte;

`ifdef DATAPATH_ON_NEGEDGE
wire	ctl_ce = ce,
		dp_ce = ce;
wire	dp_clk  = clk;
wire    dbi_clk = clk;
wire    cedbi = 1;
`else

reg 	ticktock;
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) 
        ticktock <= 0;
    else if (ce) 
        ticktock <= ~ticktock;
end
	
wire	ctl_ce = ce & ticktock, 
		dp_ce =  ce & ~ticktock;
		
wire	dp_clk  = clk;
wire    dbi_clk = clk;
wire    cedbi   = ctl_ce;
`endif

wire	error_to_control = error_bus | error_i;


wire    virq_masked = ~psw[7] & VIRQ;

control11 controlr(
	.clk(clk), 
	.ce(ctl_ce),
	.reset_n(reset_n), 
	.dpcmd(dpcmd),
	.ierror(error_to_control),
	.ready(RPLY),
	.dati_o(controlr_dati),
	.dato_o(controlr_dato),
	.mbyte(controlr_byte),
	.ifetch(IFETCH),
	.psw(psw),
	.irq_in(virq_masked),
	.iako(IAKO),
	.dp_taken(dp_taken),
	.dp_alucc(alucc),
	.dp_opcode(opcode),
	.idcop(op_decoded),
	.idc_cco(idc_cco), .idc_bra(idc_bra), .idc_nof(idc_nof), 
	.idc_rsd(idc_rsd), .idc_dop(idc_dop), .idc_sop(idc_sop), .idc_unused(idc_unused),
	.initq(initq),
	.test(test_control));

idc idcr(
	.idc_opc(opcode), 
	.unused(idc_unused), 
	.cco(idc_cco), 
	.bra(idc_bra), 
	.nof(idc_nof),
	.rsd(idc_rsd), 
	.dop(idc_dop), 
	.sop(idc_sop), 
	.op_decoded(op_decoded));

datapath dp(
	.clk(dp_clk),
	.ce(dp_ce),
	.clkdbi(dbi_clk),
	.cedbi(cedbi),
	.reset_n(reset_n),
	.dbi(data_i), 
	.dbo(data_o),
	.dba(addr_o),
	.opcode(opcode),
	.psw(psw),
	.ctrl(dpcmd),
	.alucc(alucc),
	.taken(dp_taken),
	.PC(PC),
	.ALU1(ALU1),
	.ALUOUT(ALUOUT),
	.SRC(SRC),
	.DST(DST)
	//.Rtest(Rtest)
	);
	
// bus thingy
wire 	dato = controlr_dato;
wire	dati = controlr_dati;
wire	mbyte = controlr_byte;

assign test_bus = {SYNC,DIN,DOUT,RPLY,error_i,error_bus,dati,dato};

busio busr (.clk(clk), 
			.ce(ce), 
			.reset_n(reset_n),
			.bsync(SYNC),
			.bdin(DIN),
			.bdout(DOUT),
			.bwtbt(WTBT),
			.bbsy(BSY),
			.breply(RPLY),
			.berror(error_bus),
			.dati(dati),
			.dato(dato),
			.b(mbyte)
			);

reg [7:0] initctr;
wire      initq;
always @(posedge clk) begin
	if (ce) begin
		if (initq) initctr <= 10;
		if (initctr != 0) initctr <= initctr - 1'b1;
	end
end

assign INIT = initctr != 0;

endmodule

module  busio(clk, ce, reset_n,
            bsync, breply, bdin, bdout, bwtbt, bbsy, berror,
            dati, dato, b,
            complete);

input       clk, ce, reset_n;

output reg  bsync;
output reg  bwtbt;
output reg  bdin;
output reg  bdout;
output      bbsy;
output      berror;
input       breply;

input       dati, dato;
input       b;

output      complete;

parameter BUS_TIMEOUT = 63;

parameter [4:0]
                S_IDLE = 0,
				S_R0 = 1,
                S_R1 = 2,
                S_W0 = 3,
                S_W1 = 4,
                S_FINISHED = 5,
                S_BUSERROR= 6;

reg [6:0] state;

assign bbsy = bsync;

assign berror = 0;

reg [5:0] timeout;

always @* bwtbt <= b;
/*
always @* begin
    bsync <= dati|dato;
    bdin <= dati;
    bdout <= dato;
end
*/


reg dati_r, dato_r;

/*
always @(posedge clk) begin
	if (breply) begin
		dati_r <= 0;
		dato_r <= 0;
	end else begin
		dati_r <= dati;
		dato_r <= dato;
	end
end

always @* begin
    bsync <= dati|dato|dati_r|dato_r;
    bdin <= dati | dati_r;
    bdout <= dato | dato_r;
end
*/

always @* begin
    bsync <= dati|dato;
    bdin <= dati;
    bdout <= dato;
end

/*
always @* begin
	if (~reset_n | ~(dati|dato)) begin
		bsync <= 1'b0;
		bdin <= 1'b0;
		bdout <= 1'b0;
	end else begin
		case (1'b1) 
		dati:	begin
				bsync <= 1'b1;
				bdin <= 1'b1;
				bdout <= 1'b0;
				end
		dato:	begin
				bsync <= 1'b1;
				bdin <= 1'b0;
				bdout <= 1'b1;
				end
		endcase
	end
end

reg syncsamp;
reg error;
always @(posedge clk or negedge reset_n) begin
	if (~reset_n) begin
		error <= 1'b0;
		timeout <= BUS_TIMEOUT;
	end else if (ce) begin
		syncsamp <= bsync;
		
		//if (~syncsamp & bsync) 	timeout <= BUS_TIMEOUT;
		if (~bsync) 	timeout <= BUS_TIMEOUT;
		if (bsync && timeout != 0) timeout <= timeout - 1'b 1;
	end
end
*/

/*
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
		timeout <= 0;
        state <= S_IDLE;
    end 
	else if (ce) begin
		
		if (timeout != 0) timeout <= timeout - 1'b 1;

		case (state)
			S_IDLE: 
				begin
					bsync <= 1'b0;
					bdin <= 1'b0;
					bdout <= 1'b0;
					timeout <= BUS_TIMEOUT;
					
					if (dati) begin
						state <= S_R1;
						bsync <= 1'b1;
						bdin  <= 1'b1;
						bdout <= 1'b0;						
					end 
					else if (dato) 	begin
						bsync <= 1'b1;
						bdin  <= 1'b0;
						bdout <= 1'b1;
						state <= S_W1;
					end 
				end

			S_R1: begin
					if (breply) begin
						state <= S_IDLE;
						bsync <= 1'b0;
						bdin <= 1'b0;
						bdout <= 1'b0;
					end
					else if (timeout == 0) 	state <= S_BUSERROR;
				end
						
			S_W1: begin
					if (breply)	begin
						state <= S_IDLE;
						bsync <= 1'b0;
						bdin <= 1'b0;
						bdout <= 1'b0;
					end
					else if (timeout == 0) 	state <= S_BUSERROR;					
				end
				
			S_BUSERROR:
				begin
					state <= S_IDLE;
				end
		endcase
    end
end
*/
endmodule

