
`define SIM

module simme;

parameter STEP = 2;
reg mreset_n, m_clock;
reg rts, txd, cts, rxd;
wire clk;
wire we_enable;

wire [15:0] cpu_d_o;
wire [15:0] cpu_a_o;
reg  [15:0] cpu_d_in;
reg  [15:0] OUT;

reg  [15:0] ram1[0:16383];
reg  [15:0] ram2[0:16383];
reg  [7:0]  tmpbyte;

integer    disp, fp, memf, error, i;

  // Generate reset
  initial begin
    mreset_n = 1'b0;
    #(STEP*4) mreset_n = 1'b1;
  end

  // Generate master clock
  initial begin
    m_clock = 1'b1;
    forever #(STEP/2) m_clock = ~m_clock;
  end
  
  initial begin 
    memf = $fopen("asmtests/test1.pdp", "rb");
    error = 1;
    for (i = 0; error == 1; i = i + 1) begin
        error = $fread(tmpbyte, memf);
        ram2[i][7:0] = tmpbyte;
        error = $fread(tmpbyte, memf);
        ram2[i][15:8] = tmpbyte;
        $display("ram[i]=%o", ram2[i]);
    end
    $fclose(memf);
    
    memf = $fopen("bktests/791401", "rb");
    error = 1;
    for (i = 0; error == 1; i = i + 1) begin
        error = $fread(tmpbyte, memf);
        ram1[i][7:0] = tmpbyte;
        error = $fread(tmpbyte, memf);
        ram1[i][15:8] = tmpbyte;
    end
    $fclose(memf);


    
    $display("initialized ram 000000 with %d bytes", error);
    for (i = 'o100; i < 'o100+16; i = i + 1) $display("%o", ram1[i]);
  end


// make ram access for the CPU
always @*
    case (cpu_a_o[15]) 
    1'b0:   cpu_d_in <= ram1[cpu_a_o/2];
    1'b1:   cpu_d_in <= ram2[(cpu_a_o-32768)/2];
    endcase

always @*
    if (cpu_we) 
        case (cpu_a_o[15])
        1'b0:   ram1[cpu_a_o/2] <= cpu_d_o;
        1'b1:   ram2[(cpu_a_o-32768)/2] <= cpu_d_o;
        endcase
    
always @(posedge m_clock) begin: _handshake
    if (cpu_sync) 
        cpu_rply <= 1'b1;
    else
        cpu_rply <= 1'b0;
end
    

wire cpu_sync, cpu_rd, cpu_we, cpu_byte, cpu_bsy, cpu_init, cpu_ifetch;
reg  cpu_rply;

top top(
    .mclk(m_clock),
    .mreset_n(mreset_n),
    .data_i(cpu_d_in),
    .data_o(cpu_d_o),
    .addr_o(cpu_a_o),
    
    .sync_o(cpu_sync),
    .rply_i(cpu_rply),
    .din_o(cpu_rd),
    .dout_o(cpu_we),
    .wtbt_o(cpu_byte),
    .bsy_o(cpu_bsy),
    .init_o(cpu_init),
    .ifetch_o(cpu_ifetch)
    );


  // moo
  always @(posedge m_clock & disp) begin
    //t0 = top.cpu.cpu.rs232.sender.send_buf&8'h7f;
    //if(t0 == 8'h0d) t0 = 8'h0a;
    //$display("cpu_din:%x cpu_a:%x", cpu_d_in, cpu_a_o);
    $display("pc:%o s/r:%x%x if0:%x rd:%x we:%x di:%o do:%o a:%o opc:%o s:%d R1-6:%o,%o,%o,%o %o %o", 
                top.cpu.PC, cpu_sync, cpu_rply, cpu_ifetch,
                cpu_rd, cpu_we, 
                cpu_d_in, cpu_d_o, cpu_a_o,
                top.cpu.OPCODE, top.cpu.controlr.state, 
                top.cpu.dp.R[1],top.cpu.dp.R[2],top.cpu.dp.R[3],
                top.cpu.dp.R[4], top.cpu.dp.R[5],top.cpu.dp.R[6], 
                //ram1[top.cpu.dp.R[6]/2]
                //top.cpu.op_decoded
                );
                    
    if(top.cpu.controlr.state == top.cpu.controlr.TRAP_SVC) begin
        $display("TRAP_SVC @#177776=%o", ram2[16383]);
        for (i = 0; i < 8; i = i + 1) begin
            $display("   %o: %o", i*2, ram1[i]);
        end
        $finish;
    end
  end




  initial begin
    $display("BM1 simulation begins");
    disp = 1;
    
    #(STEP*10000) begin
        $display("end by stepcount @#177776=%o", ram2[16383]);
        $finish;
    end
  end



endmodule


