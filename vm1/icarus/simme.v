`define MEDRPLY

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

  initial begin
    disp = 0;
  end

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
    $write("100000: ");
    memf = $fopen("asmtests/test1.pdp", "rb");
    error = 1;
    for (i = 0; error == 1; i = i + 1) begin
        error = $fread(tmpbyte, memf);
        ram2[i][7:0] = tmpbyte;
        error = $fread(tmpbyte, memf);
        ram2[i][15:8] = tmpbyte;
        $write("%o ", ram2[i]);
    end
    $display();
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

    $write("initialized ram 000000 with %d words\n000200: ", i);
    for (i = 'o100; i < 'o100+4; i = i + 1) $write("%o ", ram1[i]);
    $display();
  end


// make ram access for the CPU
always @*
    case (cpu_a_o[15]) 
    1'b0:
        if (!cpu_byte) begin   
            cpu_d_in <= ram1[cpu_a_o/2];
         end else begin
            cpu_d_in <= {8'h0, ~cpu_a_o[0] ? ram1[cpu_a_o/2][7:0] : ram1[cpu_a_o/2][15:8]};
            //$display("rdbt @%o = %o", cpu_a_o, {8'h0, ~cpu_a_o[0] ? ram1[cpu_a_o/2][7:0] : ram1[cpu_a_o/2][15:8]});
         end
    1'b1:   cpu_d_in <= ram2[(cpu_a_o-32768)/2];
    endcase

always @*
    if (cpu_we) begin
        if (cpu_byte) begin
            case (cpu_a_o[15])
            1'b0:   begin
                    if (cpu_a_o[0] == 0)
                        ram1[cpu_a_o/2][7:0] <= cpu_d_o[7:0];
                    else
                        ram1[cpu_a_o/2][15:8] <= cpu_d_o[7:0];
                        
                    //#1 $display("wtbt %o ram @%o=%o", cpu_d_o[7:0], cpu_a_o, ram1[cpu_a_o/2]);     
                    end
             
            1'b1:   begin
                    if (cpu_a_o == 'o177566) begin
                    if (cpu_d_o[7:0] != 'h0e) $write("%c",cpu_d_o[7:0]);
                    end
                    end
            endcase
        end else begin
            case (cpu_a_o[15])
            1'b0:   ram1[cpu_a_o/2] <= cpu_d_o;
            1'b1:   ram2[(cpu_a_o-32768)/2] <= cpu_d_o;
            endcase
        end
    end

`ifdef SLOWRPLY

reg [2:0] rplycnt;
reg syncsamp;
always @(posedge m_clock) begin: _handshake_slow
    syncsamp <= cpu_sync;
    
    if (~syncsamp & cpu_sync) begin
        rplycnt <= 5;
    end else if (rplycnt != 0) 
        rplycnt <= rplycnt - 1;
end

always @* cpu_rply <= rplycnt[1];  

`else 
`ifdef MEDRPLY

always @(posedge m_clock) begin: _handshake
    if (cpu_sync) 
        cpu_rply <= 1'b1;
    else
        cpu_rply <= 1'b0;
end

`else

always @* cpu_rply <= cpu_sync;

`endif
`endif   


    

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
  always @(negedge m_clock) 
    if (disp) begin
    //t0 = top.cpu.cpu.rs232.sender.send_buf&8'h7f;
    //if(t0 == 8'h0d) t0 = 8'h0a;
    //$display("cpu_din:%x cpu_a:%x", cpu_d_in, cpu_a_o);
    $display("pc:%o s/r:%x%x if0:%x r:%x w:%x di:%o do:%o a:%o opc:%o s:%d/%d/%d R1-6:%o,%o,%o,%o %o %o", 
                top.cpu.PC, cpu_sync, cpu_rply, cpu_ifetch,
                cpu_rd, cpu_we, 
                cpu_d_in, cpu_d_o, cpu_a_o,
                top.cpu.OPCODE, top.cpu.controlr.state, top.cpu.controlr.MODE, top.cpu.controlr.opsrcdst,
                top.cpu.dp.R[1],top.cpu.dp.R[2],top.cpu.dp.R[3],
                top.cpu.dp.R[4], top.cpu.dp.R[5],top.cpu.dp.R[6], 
                //top.cpu.dp.psw,
                //ram1[top.cpu.dp.R[6]/2]
                //top.cpu.op_decoded
                );
                    
    if(top.cpu.controlr.state == top.cpu.controlr.TRAP_SVC) begin
        $display("TRAP_SVC @#177776=%o", ram2[16383]);
        for (i = 0; i < 8; i = i + 1) begin
            $display("   %o: %o", i*2, ram1[i]);
        end
        //$finish;
    end
  end

  always @(negedge m_clock) begin
    if (cpu_ifetch && cpu_rd && cpu_a_o == 'o016742)  $display("  (pass #%d time=%d)", ram1['o406/2], $time);
  end



  initial begin
    $display("BM1 simulation begins");
    disp = 0;
    
    #(STEP*40000) begin
        $display("\nend by step limit @#177776=%o", ram2[16383]);
        $finish;
    end
  end



endmodule


