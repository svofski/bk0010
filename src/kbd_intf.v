// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. Keyboard interface.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

`default_nettype none

module kbd_intf(mclk, reset_in, PS2_Clk, PS2_Data, shift, ar2, ascii, available, read_kb, key_stop, key_super, key_down, joy, ul);

input               mclk, reset_in, read_kb;
input               PS2_Clk,PS2_Data;

output              shift, ar2;
output              available = kbd_available & ((decoded != 0) | key_super);
   
output              key_stop;
output              key_super;
output              key_down = key_down_r & (decoded != 0);       // any key is down
output [15:0]       joy;
output [1:0]        ul = {uppercase,lowercase};

reg    [2:0]        kbd_state;  
reg    [2:0]        kbd_state_next;
reg                 shift;
reg                 ctrl;
reg                 alt;
reg                 kbd_available;
reg                 key_down_r;

reg    [7:0]        decoded_r;

reg                 rus;            // 1 = RUS, 0 = LAT
reg                 e0;

wire    [15:0]      joy;
wire                joy_used = |joy;

wire                autoar2;        // AR2 forced by special keys (e.g. POVT)
output [6:0]        ascii;
wire   [6:0]        decoded;
wire   [7:0]        Scan_Code;
wire                DoRead;
wire                Scan_Err;
wire                Scan_DAV;

assign ar2 = alt | autoar2;

PS2_Ctrl PS2_Ctrl (
    .Clk(mclk), 
    .Reset(reset_in), 
    .PS2_Clk(PS2_Clk), 
    .PS2_Data(PS2_Data), 
    .DoRead(DoRead), 
    .Scan_Err(Scan_Err), 
    .Scan_DAV(Scan_DAV), 
    .Scan_Code(Scan_Code)
    );

assign  DoRead = Scan_DAV;

kbd_transl kbd_transl( .shift(shift), .e0(e0), .incode(Scan_Code), .outcode(decoded), .autoar2(autoar2)); 

joystick joy0(.clk(mclk), .reset_n(~reset_in), .e0(e0), .mk(kbd_state == 7), .brk(kbd_state == 6), .incode(Scan_Code), .joybits(joy));

wire lowercase = (decoded > 7'h60) & (decoded <= 7'h7a); 
wire uppercase = (decoded > 7'h40) & (decoded <= 7'h5a);

assign ascii = ctrl? {2'b0, decoded_r[4:0]} : 
               rus ? decoded_r : 
               lowercase ? decoded_r - 7'h20 : 
               uppercase ? decoded_r + 7'h20 : decoded_r; 


wire scan_shift = Scan_Code == 8'h12;
wire scan_ctrl  = Scan_Code == 8'h14;
wire scan_alt   = Scan_Code == 8'h11;
wire scan_stop  = Scan_Code == 8'h07;   // F12 = STOP
wire scan_super = Scan_Code == 8'h7e;   // ScrollLock = SUPER/ Loader mode

always @(posedge mclk or posedge reset_in) begin 
    if(reset_in) begin
        shift <= 0;
        ctrl <= 0;
        alt <= 0;
        stop_ctr <= 0;
    end
    else begin
        if( kbd_state == 1) begin
            if (scan_shift)
                shift <= 1;
            else if (scan_ctrl)
                ctrl <= 1;
            else if (scan_alt)
                alt <= 1;
            else if (scan_stop) begin
                stop_ctr <= 1;
            end else if (scan_super) begin
                super_ctr <= 1;
            end
        end 
        else if( kbd_state == 6) begin
            if(scan_shift)
                shift <= 0;
            else if (scan_ctrl)
                ctrl <= 0;
            else if (scan_alt)
                alt <= 0;
        end
        
        if (stop_ctr != 0) stop_ctr <= stop_ctr + 1'b1;
        if (super_ctr != 0) super_ctr <= super_ctr + 1'b1;
    end
end //always


reg [15:0] stop_ctr;
assign key_stop = stop_ctr[7:0] != 0 && stop_ctr[15:8] == 0;

reg [15:0] super_ctr;
assign key_super = super_ctr[7:0] != 0 && super_ctr[15:8] == 0;
 
always @(posedge mclk or posedge reset_in) begin
    if(reset_in) begin
        kbd_state <= 0;
        //code_latched <= 0;
        kbd_available <= 0;
        rus <= 0;
        e0 <= 0;
    end
    else begin
        kbd_state <= kbd_state_next;
        if(read_kb)
            kbd_available <= 0;
        if( kbd_state == 7) begin
            if (!key_down_r) begin
                if (|decoded | key_super) begin
                    decoded_r <= decoded;
                    kbd_available <= 1;
                    key_down_r <= 1;
                    
                    case (decoded)
                    7'o016: rus <= 1;
                    7'o017: rus <= 0;
                    default:;
                    endcase
                    
                end
            end
        end 
        else 
        if (kbd_state == 6) begin   // release
            key_down_r <= 0;
            e0 <= 0;
        end 
        else 
        if (kbd_state == 2) begin
            if (Scan_Code == 8'he0) e0 <= 1'b1;
        end
    end
end

always @ (kbd_state or Scan_Code or Scan_DAV) begin
    case (kbd_state)
    0:  if( Scan_DAV)
            kbd_state_next <= 1;
        else
            kbd_state_next <= 0;

    1:   // have something, get it
        kbd_state_next <= 2;

    2:  if(Scan_Code == 8'hf0)
            kbd_state_next <= 3;
        else if(Scan_Code == 8'hE0)
            kbd_state_next <= 0;
        else if(scan_shift | scan_ctrl | scan_alt | scan_stop) begin
            kbd_state_next <= 0;
        end
        else
            kbd_state_next <= 7;

    3:  // was F0    wait a couple of states for    Scan_DAV to go down
        kbd_state_next <= 4;

    4:
        kbd_state_next <= 5;

    5:  if( Scan_DAV)   // wait for more
            kbd_state_next <= 6;
        else
            kbd_state_next <= 5;

    6:  kbd_state_next <= 0;

    7:  kbd_state_next <= 0;
    
    default: 
        kbd_state_next <= 0;
    endcase
end

endmodule

module joystick(
            input           clk, 
            input           reset_n, 
            input           e0, 
            input           mk,
            input           brk,
            input [7:0]     incode, 
            output reg[15:0] joybits);
            
always @(posedge clk or negedge reset_n) begin: _happy
    if (~reset_n) 
        joybits <= 0;
    else begin
        if (mk) begin
            case ({e0, incode})
            9'h075: joybits[10] <= 1;    // UP
            9'h072: joybits[5]  <= 1;    // DOWN
            9'h06b: joybits[9]  <= 1;    // LEFT
            9'h074: joybits[4]  <= 1;    // RIGHT
            9'h14a: joybits[0]  <= 1;    // FIRE 1: (KP /)
            9'h070: joybits[1]  <= 1;    // FIRE 2: (KP 0)
            9'h073: joybits[2]  <= 1;    // FIRE 3: (KP 5)
            endcase
        end 
        else if (brk) begin
            case ({e0, incode})
            9'h075: joybits[10] <= 0;    // UP
            9'h072: joybits[5]  <= 0;    // DOWN
            9'h06b: joybits[9]  <= 0;    // LEFT
            9'h074: joybits[4]  <= 0;    // RIGHT
            9'h14a: joybits[0]  <= 0;    // FIRE 1: (KP /)
            9'h070: joybits[1]  <= 0;    // FIRE 2: (KP 0)
            9'h073: joybits[2]  <= 0;    // FIRE 3: (KP 5)
            endcase
        end
    end

end            
            
endmodule            
            
