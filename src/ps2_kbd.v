// File translated with vhd2vl v 1.0
// VHDL to Verilog RTL translator
// Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd - http://www.ocean-logic.com
// vhd2vl comes with ABSOLUTELY NO WARRANTY
// This is free software, and you are welcome to redistribute it
// under certain conditions.
// See the license file license.txt included with the source for details.

// PS2_Ctrl.vhd
// ------------------------------------------------
//   Simplified PS/2 Controller  (kbd, mouse...)
// ------------------------------------------------
// Only the Receive function is implemented !
// (c) ALSE. http://www.alse-fr.com

module PS2_Ctrl(
                Clk,
                Reset,
                PS2_Clk,
                PS2_Data,
                DoRead,
                Scan_Err,
                Scan_DAV,
                Scan_Code
                );

input Clk;
// System Clock
input Reset;
// System Reset
input PS2_Clk;
// Keyboard Clock Line
input PS2_Data;
// Keyboard Data Line
input DoRead;
// From outside when reading the scan code
output Scan_Err;
// To outside : Parity or Overflow error
output Scan_DAV;
// To outside when a scan code has arrived
output[7:0] Scan_Code;
// Eight bits Data Out

wire   Clk;
wire   Reset;
wire   PS2_Clk;
wire   PS2_Data;
wire   DoRead;
reg   Scan_Err;
wire   Scan_DAV;
reg  [7:0] Scan_Code;


reg  PS2_Datr;
//  subtype Filter_t is std_logic_vector(7 downto 0);
reg [7:0] Filter;
reg  Fall_Clk;
reg [3:0] Bit_Cnt;
reg  Parity;
reg  Scan_DAVi;
reg [8:0] S_Reg;
reg  PS2_Clk_f;
parameter [0:0]
  Idle = 0,
  Shifting = 1;
reg [1:0] State;

  wire kbd_state = State[0]; //avf
  //assign filter = Fall_Clk;


  assign Scan_DAV = Scan_DAVi;
  // This filters digitally the raw clock signal coming from the keyboard :
  //  * Eight consecutive PS2_Clk=1 makes the filtered_clock go high
  //  * Eight consecutive PS2_Clk=0 makes the filtered_clock go low
  // Implies a (FilterSize+1) x Tsys_clock delay on Fall_Clk wrt Data
  // Also in charge of the re-synchronization of PS2_Data
  always @(posedge Clk or posedge Reset) begin
    if(Reset == 1'b 1) begin
      PS2_Datr <= 1'b 0;
      PS2_Clk_f <= 1'b 0;
      Filter <= {8{1'b0}};
      Fall_Clk <= 1'b 0;
    end else begin
      PS2_Datr <= PS2_Data & PS2_Data;
      // also turns 'H' into '1'
      Fall_Clk <= 1'b 0;
      Filter <= {PS2_Clk ,Filter[7:1] };
      if(Filter == {1{1'b1}}) begin
        PS2_Clk_f <= 1'b 1;
      end
      else if(Filter == {1{1'b0}}) begin
        PS2_Clk_f <= 1'b 0;
        if(PS2_Clk_f == 1'b 1) begin
          Fall_Clk <= 1'b 1;
        end
      end
    end
  end

  // This simple State Machine reads in the Serial Data
  // coming from the PS/2 peripheral.
  always @(posedge Clk or posedge Reset) begin
    if(Reset == 1'b 1) begin
      State <= Idle;
      Bit_Cnt <= {4{1'b0}};
      S_Reg <= {9{1'b0}};
      Scan_Code <= {8{1'b0}};
      Parity <= 1'b 0;
      Scan_DAVi <= 1'b 0;
      Scan_Err <= 1'b 0;
    end else begin
      if(DoRead == 1'b 1) begin
        Scan_DAVi <= 1'b 0;
        // note: this assgnmnt can be overriden
      end
      case(State)
      Idle : begin
        Parity <= 1'b 0;
        Bit_Cnt <= {4{1'b0}};
        // note that we dont need to clear the Shift Register
        if(Fall_Clk == 1'b 1 && PS2_Datr == 1'b 0) begin
          // Start bit
          Scan_Err <= 1'b 0;
          State <= Shifting;
        end
      end
      Shifting : begin
        if(Bit_Cnt >= 4'b 1001) begin
          if(Fall_Clk == 1'b 1) begin
            // Stop Bit
            // Error is (wrong Parity) or (Stop='0') or Overflow
            Scan_Err <=  ~Parity |  ~PS2_Datr | Scan_DAVi;
            Scan_DAVi <= 1'b 1;
            Scan_Code <= S_Reg[7:0] ;
            State <= Idle;
          end
        end
        else if(Fall_Clk == 1'b 1) begin
          Bit_Cnt <= Bit_Cnt + 1'b 1;
          S_Reg <= {PS2_Datr,S_Reg[8:1] };
          // Shift right
          Parity <= Parity ^ PS2_Datr;
        end
      end
      default : begin
        // never reached
        State <= Idle;
      end
      endcase
      //Scan_Err <= '0'; -- to create an on-purpose error on Scan_Err !
    end
  end


endmodule
