module top(
    mclk,
    mreset_n,
    data_i,
    data_o,
    addr_o,
    
    sync_o,
    rply_i,
    din_o,
    dout_o,
    wtbt_o,
    bsy_o,
    init_o,
    ifetch_o
    
    );
    
input mclk, mreset_n;

input [15:0] data_i;
output[15:0] data_o;
output[15:0] addr_o;

output       sync_o;
input        rply_i;
output       din_o;
output       dout_o;
output       wtbt_o;
output       bsy_o;
output       init_o;
output       ifetch_o;

vm1 cpu
          (.clk(mclk), 
           .ce(1),
           .reset_n(mreset_n),
           .data_i(data_i),
           .data_o(data_o),
           .addr_o(addr_o),

           //error_i,      
           //fault_i,
           
           .SYNC(sync_o),        // o: address set
           .RPLY(rply_i),        // i: reply to DIN or DOUT
           .DIN(din_o),         // o: data in flag
           .DOUT(dout_o),        // o: data out flag
           .WTBT(wtbt_o),        // o: byteio op/odd address
           
           .BSY(bsy_o),         // o: CPU usurps bus
           
           .INIT(init_o),        // o: peripheral INIT
           
		   .IFETCH(ifetch_o)		// o: indicates IF0
           );

endmodule
