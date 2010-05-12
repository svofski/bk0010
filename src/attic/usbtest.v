// File translated with vhd2vl v 1.0
// VHDL to Verilog RTL translator
// Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd - http://www.ocean-logic.com
// vhd2vl comes with ABSOLUTELY NO WARRANTY
// This is free software, and you are welcome to redistribute it
// under certain conditions.
// See the license file license.txt included with the source for details.


module usbintf(
mclk,
reset_in,
pdb,
astb,
dstb,
pwr,
pwait,
led,
switch,
ram_addr,
usb_ouT_data,
in_ramdata,
ram_a_lb,
ram_a_ub,
ram_we,
ram_oe,
//kbd_data_wr,
cap_rd,
cap_rd_sel,
match_val_u,
match_mask_u
);


input mclk;
inout[7:0] pdb;
input astb;
input dstb;
input pwr;
output pwait, cap_rd;
//output kbd_data_wr; 
output[7:0] led;
output[2:0] cap_rd_sel;

output[15:0] match_val_u;
output[15:0] match_mask_u;


input[7:0] switch;
//	rgBtn	: in std_logic_vector(4 downto 0);
//	btn		: in std_logic;
output [17:0] ram_addr;
output [15:0] usb_ouT_data;
output ram_a_lb;
output ram_a_ub;
output ram_we;
output ram_oe;

input reset_in;
input [15:0] in_ramdata;

//led		: out std_logic

wire   mclk;
wire  [7:0] pdb;
wire   astb;
wire   dstb;
wire   pwr;
wire   pwait;
wire  [7:0] led;
wire  [7:0] switch;
wire   ram_selected;

wire [7:0] in_ramdata_byte;
	

parameter [7:0] stEppReady = 8'b 00000000;
parameter [7:0] stEppAwrA = 8'b 00010000;
parameter [7:0] stEppAwrB = 8'b 00100100;
parameter [7:0] stEppAwrC = 8'b 00110001;
parameter [7:0] stEppArdA = 8'b 01000010;
parameter [7:0] stEppArdB = 8'b 01010010;
parameter [7:0] stEppArdC = 8'b 01100011;
parameter [7:0] stEppDwrA = 8'b 01110000;
parameter [7:0] stEppDwrB = 8'b 10001000;
parameter [7:0] stEppDwrC = 8'b 10010001;
parameter [7:0] stEppDrdA = 8'b 10100010;
parameter [7:0] stEppDrdB = 8'b 10110010;
parameter [7:0] stEppDrdC = 8'b 11000011;
//----------------------------------------------------------------------
// Signal Declarations
//----------------------------------------------------------------------
reg [7:0] stEppCur;
reg [7:0] stEppNext;
wire  clkMain;


// Internal control signales
wire  ctlEppWait;
wire  ctlEppAstb;
wire  ctlEppDstb;
wire  ctlEppDir;
wire  ctlEppWr;
wire  ctlEppAwr;
wire  ctlEppDwr;
wire [7:0] busEppOut;
wire [7:0] busEppIn;
wire [7:0] busEppData;


// Registers
reg [3:0] regEppAdr;
reg [7:0] regData0;
reg [7:0] regData1;
reg [7:0] regData2;
reg [7:0] regData3;
reg [7:0] regData4;
reg [7:0] regData5;
reg [7:0] regData6;
reg [7:0] regData7;
reg [7:0] regCtrl;


reg RamReadCycle;

//----------------------------------------------------------------------
// Module Implementation
//----------------------------------------------------------------------

  //----------------------------------------------------------------------
  // Map basic status and control signals
  //----------------------------------------------------------------------
  
  assign clkMain = mclk;
  assign ctlEppAstb = astb;
  assign ctlEppDstb = dstb;
  assign ctlEppWr = pwr;
  assign pwait = ctlEppWait;

  assign match_val_u = {regData4, regData3};
  assign match_mask_u = {regData6, regData5};

  assign ram_selected = (regEppAdr == 4'b 0000);
  //assign kbd_data_wr = (ctlEppDwr == 1'b 1 && regEppAdr == 4'b 1010);  

  assign in_ramdata_byte = regData1[0]? in_ramdata[15:8]: in_ramdata[7:0];

  // drive WAIT from state machine output
  // Data bus direction control. The internal input data bus always
  // gets the port data bus. The port data bus drives the internal
  // output data bus onto the pins when the interface says we are doing
  // a read cycle and we are in one of the read cycles states in the
  // state machine.
  assign busEppIn = pdb;
  assign pdb = ctlEppWr == 1'b 1 && ctlEppDir == 1'b 1 ? busEppOut : 8'b ZZZZZZZZ;
  // Select either address or data onto the internal output data bus.
  assign busEppOut = ctlEppAstb == 1'b 0 ? {4'b 0000,regEppAdr} : busEppData;
  assign led = regCtrl;
  
  // Decode the address register and select the appropriate data register
  assign busEppData = regEppAdr == 4'b 0000 ? regData0 : 
  	regEppAdr == 4'b 0001 ? regData1 : 
	regEppAdr == 4'b 0010 ? regData2 : 
	regEppAdr == 4'b 0011 ? regData3 : 
	regEppAdr == 4'b 0100 ? regData4 : 
	regEppAdr == 4'b 0101 ? regData5 : 
	regEppAdr == 4'b 0110 ? regData6 : 
	regEppAdr == 4'b 0111 ? regData7 : 
	regEppAdr[3] == 1'b 1 ? switch : 8'b 00000000;
  
  assign ram_addr = {3'b000, regData2, regData1[7:1]};
  assign usb_ouT_data = {busEppIn, busEppIn};
    assign ram_a_lb = regData1[0];
  assign ram_a_ub = ~regData1[0];
  assign ram_we =  ~(ctlEppDwr & ram_selected); //~(stEppCur == stEppDwrC);
  assign ram_oe =  ~((stEppCur == stEppDrdB) & ram_selected);
  assign cap_rd =  (stEppCur == stEppDrdB) & (regEppAdr[3] == 1'b 1);
  assign cap_rd_sel = regEppAdr[2:0];

  
  //----------------------------------------------------------------------
  // EPP Interface Control State Machine
  //----------------------------------------------------------------------
  // Map control signals from the current state
  assign ctlEppWait = stEppCur[0] ;
  assign ctlEppDir = stEppCur[1] ;
  assign ctlEppAwr = stEppCur[2] ;
  assign ctlEppDwr = stEppCur[3] ;
  // This process moves the state machine to the next state
  // on each clock cycle
  always @(posedge clkMain) begin
    if(reset_in) begin 
    		stEppCur <= 0;
    end 
    else begin
    	stEppCur <= stEppNext;
	end
  end

  // This process determines the next state machine state based
  // on the current state and the state machine inputs.
  always @(stEppCur or stEppNext or ctlEppAstb or ctlEppDstb or ctlEppWr) begin
    case(stEppCur)
        // Idle state waiting for the beginning of an EPP cycle
    stEppReady : begin
      if(ctlEppAstb == 1'b 0 && ctlEppWr == 1'b 0) begin
        // Address write
        stEppNext <= stEppAwrA;
      end
      else if(ctlEppAstb == 1'b 0 && ctlEppWr == 1'b 1) begin
        // Address read
        stEppNext <= stEppArdA;
      end
      else if(ctlEppDstb == 1'b 0 && ctlEppWr == 1'b 0) begin
        // Data write
        stEppNext <= stEppDwrA;
      end
      else if(ctlEppDstb == 1'b 0 && ctlEppWr == 1'b 1) begin
        // Data read
        stEppNext <= stEppDrdA;
      end
      else begin
        // Remain in ready state
        stEppNext <= stEppReady;
      end
      // Write address register
    end
    stEppAwrA : begin
      stEppNext <= stEppAwrB;
    end
    stEppAwrB : begin
      stEppNext <= stEppAwrC;
    end
    stEppAwrC : begin
      if(ctlEppAstb == 1'b 0) begin
        stEppNext <= stEppAwrC;
      end
      else begin
        stEppNext <= stEppReady;
      end
      // Read address register
    end
    stEppArdA : begin
      stEppNext <= stEppArdB;
    end
    stEppArdB : begin
      stEppNext <= stEppArdC;
    end
    stEppArdC : begin
      if(ctlEppAstb == 1'b 0) begin
        stEppNext <= stEppArdC;
      end
      else begin
        stEppNext <= stEppReady;
      end
      // Write data register
    end
    stEppDwrA : begin
      stEppNext <= stEppDwrB;
    end
    stEppDwrB : begin
      stEppNext <= stEppDwrC;
    end
    stEppDwrC : begin
      if(ctlEppDstb == 1'b 0) begin
        stEppNext <= stEppDwrC;
      end
      else begin
        stEppNext <= stEppReady;
      end
      // Read data register
    end
    stEppDrdA : begin
      stEppNext <= stEppDrdB;
    end
    stEppDrdB : begin
      stEppNext <= stEppDrdC;
    end
    stEppDrdC : begin
      if(ctlEppDstb == 1'b 0) begin
        stEppNext <= stEppDrdC;
      end
      else begin
        stEppNext <= stEppReady;
      end
      // Some unknown state				
    end
    default : begin
      stEppNext <= stEppReady;
    end
    endcase
  end

  //----------------------------------------------------------------------
  // EPP Address register
  //----------------------------------------------------------------------
  always @(posedge clkMain) begin
    if(reset_in) begin  
    	regEppAdr <= 0;
    end
    else if(ctlEppAwr == 1'b 1) begin
      regEppAdr <= busEppIn[3:0] ;
    end
  end

  //----------------------------------------------------------------------
  // EPP Data registers
  //----------------------------------------------------------------------
  // The following processes implement the interface registers. These
  // registers just hold the value written so that it can be read back.
  // In a real design, the contents of these registers would drive additional
  // logic.
  // The ctlEppDwr signal is an output from the state machine that says
  // we are in a 'write data register' state. This is combined with the
  // address in the address register to determine which register to write.
  always @(posedge clkMain ) begin

    if(reset_in) begin  
      regData0 <= 0;
	 regData1 <= 0;
	 regData2 <= 0;
	end

   // else if(( stEppCur == stEppDrdB) && (regEppAdr == 4'b 0000)) begin
   	else if(RamReadCycle) begin
          regData0 <=  in_ramdata_byte;
	     regData1 <= regData1+1;
		if(regData1 == 'hff) begin
	 		regData2 <= regData2+1;
		end
    end

    else if(ctlEppDwr == 1'b 1) begin 
    		if(ram_selected) begin
      		regData0 <= busEppIn;
	 		regData1 <= regData1+1;
			if(regData1 == 'hff) begin
	 			regData2 <= regData2+1;
			end
	 	end
		else if (regEppAdr == 4'b 0001) begin
				regData1 <= busEppIn;
			end
		else if (regEppAdr == 4'b 0010) begin
				regData2 <= busEppIn;
			end
    end
  end


  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 0011) begin
      regData3 <= busEppIn;
    end
  end

  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 0100) begin
      regData4 <= busEppIn;
    end
  end

  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 0101) begin
      regData5 <= busEppIn;
    end
  end

  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 0110) begin
      regData6 <= busEppIn;
    end
  end

  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 0111) begin
      regData7 <= busEppIn;
    end
  end

  always @(posedge clkMain) begin
    if(ctlEppDwr == 1'b 1 && regEppAdr == 4'b 1010) begin
      regCtrl <= busEppIn;
    end
  end

  always @(posedge clkMain) begin  // avf - make it appear at the start of the cycle
     if((stEppCur == stEppDrdA) && ram_selected) begin 
		RamReadCycle <= 1;
     end else 
		RamReadCycle <= 0;
  end



    //--------------------------------------------------------------------------

endmodule
