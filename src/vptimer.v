`default_nettype none

module vptimer(
    input           clk,
    input           ce,
    input           reset_n,
    input           regwr,
    input           regrd,
    input [3:0]     addr,
    input [15:0]    data_i,
    output reg[15:0]data_o
);

reg [15:0] counter;
reg [15:0] counter_reload;
reg [15:0] counter_load;


parameter STOP = 0,
          WRAPAROUND = 1,
          EXPENABLE = 2,
          ONESHOT = 3,
          RUN = 4,
          DIV16 = 5,
          DIV4 = 6,
          EXPIRY = 7;

reg [7:0]  control;

wire sel_reload  = addr == 4'o06;
wire sel_counter = addr == 4'o10;
wire sel_control = addr == 4'o12;


always @(posedge clk or negedge reset_n)
    if (~reset_n) begin
        counter_reload <= 0;
    end
    else if (ce) begin
        if (regwr) begin
            case (1'b1) 
            sel_reload:     counter_reload <= data_i;
            endcase
        end 
        else if (regrd) begin
            case (1'b1)
            sel_reload:     data_o <= counter_reload;
            sel_counter:    data_o <= counter;
            sel_control:    data_o <= {8'hff, control};
            endcase
        end
    end

reg [10:0] dctr;    
wire tick = ~|dctr;
always @(posedge clk) 
    dctr <= dctr == 0 ? 11'd 1066 : (dctr - 1'b1);
    
reg [5:0] prescaler;
always @(posedge clk)
    if (tick) prescaler <= prescaler + 1'b1;
    
    
reg tock;
always @* 
    casex (control[6:4]) 
    3'bxx0:     tock = 0;
    3'b001:     tock = 1;
    3'b011:     tock = ~|prescaler;      // div/16
    3'b101:     tock = ~|prescaler[2:0]; // div/4
    3'b111:     tock = ~|prescaler;
    endcase
    
always @(posedge clk or negedge reset_n)
    if (~reset_n) begin
        counter <= 0;
        control <= 0;
    end
    else if (ce & sel_control & regwr) begin
        control <= data_i[7:0];
        if (data_i[RUN]) counter <= counter_reload;
    end
    else if (~control[STOP] & control[RUN]) begin
        if (tick & tock) begin
            if (counter == 0 && ~control[WRAPAROUND]) begin
                counter <= (~|counter_reload) ? 16'o177777 : counter_reload;
                control[RUN] <= ~control[ONESHOT]; // oneshot counts to 0 and clears the RUN bit
                control[EXPIRY] <= control[EXPENABLE];
            end
            else begin
                counter <= counter - 1'b1;
            end
        end
    end else begin
        counter <= counter_reload;
    end

endmodule

