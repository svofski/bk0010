`default_nettype none

module memmap(
    input           clk,
    input           ce,
    input           reset_n,
    input           regwr,
    input           regrd,
    input  [15:0]   data_i,
    output reg[15:0]data_o,
    output reg      valid_o,
    input           enable_i,
    
    input           mode,      // 1 = User, 0 = Kernel
    input   [15:0]  vaddr,
    output reg[21:0]phaddr,
    output reg      writable_o,
    output  [15:0]  K0
);

reg     [15:0] KISA[0:7];       // Kernel mode PAR 
reg     [15:0] UISA[0:7];       // User mode PAR   

wire  [2:0]         par = vaddr[15:13];
wire  [2:0]         regidx = (regwr|regrd) ? vaddr[3:1] : par;

reg valid;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        valid_o <= 1'b0;
    end 
    else if (ce) begin
        valid_o <= 1'b1;
        
        if (regwr) begin
            case (vaddr[4])
            'b0: KISA[regidx] <= data_i;
            'b1: UISA[regidx] <= data_i;
            endcase
        end else if (regrd) begin
            casex (vaddr[4])
            'b0: data_o <= KISA[regidx];
            'b1: data_o <= UISA[regidx];
            endcase
        end else 
            data_o <= regidx;
    end
end

wire [6:0] BN  = vaddr[12:6];
wire [5:0] BOFS = vaddr[5:0];

always @*
    casex ({enable_i,mode})   
    2'b0x:  phaddr = vaddr;
    2'b10:  phaddr = {KISA[regidx][14:0] + BN, BOFS};
    2'b11:  phaddr = {UISA[regidx][14:0] + BN, BOFS};
    endcase


//assign ram_space = ~_cpu_adrs[15];
//assign rom_space = _cpu_adrs[15] & ~reg_space;

always @*
    casex ({enable_i,mode})
    2'b0x: writable_o = ~vaddr[15];
    2'b10: writable_o = KISA[regidx][15];
    2'b11: writable_o = UISA[regidx][15];
    endcase

assign K0 = KISA[regidx];

endmodule

