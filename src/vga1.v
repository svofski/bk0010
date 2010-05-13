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

// This implementation supports a 25MHz clock
// 
// 
// CounterX[10:0] - current pixel's Xposition. [0...1287]
// CounterY[9:0]  - current pixel's Yposition. [0...479 ]
// Valid        - asserted when visible rectangle is being drawn.
module sync_gen25 (clk, res, CounterX, CounterY, Valid, vga_h_sync, vga_v_sync);
    input clk;
    input res;
    output Valid, vga_h_sync, vga_v_sync;
    output [9:0] CounterY;
    output [9:0] CounterX;
        
    reg [9:0] CounterY;
    reg [9:0] CounterX;
   //reg          ResetCntX;
   
        reg       EnableCntY, ResetCntY;
    reg Valid, vga_h_sync, vga_v_sync;
        wire     ResetCntX;


   //assign   ResetCntX  = (CounterX[9:0] == 699); // this is fine but isn't a multiply of 16
   assign   ResetCntX  = (CounterX[9:0] == 703);   // 704 is 
   
//Counters
always @ (posedge clk) begin
   if (ResetCntX | res) CounterX[9:0] <= 10'b0;
   else CounterX[9:0] <= CounterX[9:0] + 1;
   
   if (ResetCntY | res) CounterY[9:0] <= 10'b0;
   else if (EnableCntY) CounterY[9:0] <= CounterY + 1;
   else CounterY[9:0] <= CounterY[9:0]; 
end

//Synchronizer controller    
always @(posedge clk )
  begin 
   //  ResetCntX    <= (CounterX[9:0] == 799); 
     EnableCntY <= (CounterX[9:0] == 698); 
     ResetCntY  <= (CounterY[9:0] == 625);
  end

//signal synchronizer
always @(posedge clk)
  begin
     vga_h_sync <= ~((CounterX > 565) && (CounterX < 590));
     vga_v_sync <= ~(CounterY == 554);
    // Valid    <=  (CounterX  < 512) && (CounterX  != 0) && (CounterY < 511 );
     Valid  <=  ~CounterY[9];
  end
endmodule // sync_gen25


module shifter(clk25,color,R,G,B,valid,data,x,load_i);
   input clk25,color,valid;

   input [15:0] data;
   input  [9:0] x;
   
   
   output   R,G,B;
   input    load_i;   
   
   reg      R,G,B;

   reg [15:0]   shiftreg;

   reg [1:0] colorbits;
   /*
   reg active_pixel;
  
   always @(negedge clk25) begin   
    if(load_i == 1) begin
        if(x == 0)
            active_pixel <= 1;
        else if(x[9])
             active_pixel <= 0;
    end
   end
   */
   wire active_pixel = ~x[9];

    always @(posedge clk25) begin
        if(load_i == 1) begin
            if(active_pixel)
                shiftreg <= data;
            else
                shiftreg <= 0;
        end 
        else 
            shiftreg <= {1'b0, shiftreg[15:1]};

        if(color) begin
            case (colorbits)
            2'b01: begin 
                     R <= 0;
                     B <= 1;
                     G <= 0;
                    end

            2'b10: begin
                     R <= 0;
                     B <= 0;
                     G <= 1;
                    end

            2'b11: begin
                     R <= 1;
                     B <= 0;
                     G <= 0;
                    end

            default: begin // 00
                      R <= 0;
                      B <= 0;
                      G <= 0;
                    end
            endcase // case(colorbits)
        end // if (color)
        else begin
            R <= shiftreg[0];
            G <= shiftreg[0];
            B <= shiftreg[0];
        end // else: !if(color)
    end

    always @(posedge clk25) begin
        if(color & x[0])  begin
            colorbits <= shiftreg[1:0];
        end
    end
endmodule   


