`define NOSLOWRPLY

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

reg  [7:0]  tx_control;
reg  [7:0]  rx_control;
wire        iako;
wire        txirq = tx_control[6];

reg         buserr;

integer    disp, fp, memf, error, i;

  initial begin
    disp = 0;
    tx_control = 'o200;
    buserr = 0;
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
  
    for (i = 0; i < 16384; i = i + 1) begin
        ram1[i] = 0;
        ram2[i] = 0;
    end
  
    $write("100000: ");
    memf = $fopen("asmtests/felix6.pdp", "rb");
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
    
    
`ifdef VM1TESTS    
    memf = $fopen("bktests/791404", "rb");
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
`endif
    
  end


// make ram access for the CPU
always @*
    case (cpu_a_o[15]) 
    1'b0:
        if (!cpu_byte) begin   
            cpu_d_in <=  (txirq & iako & cpu_rd) ? 'o64 : ram1[cpu_a_o/2];
         end else begin
            cpu_d_in <= {8'h0, ~cpu_a_o[0] ? ram1[cpu_a_o/2][7:0] : ram1[cpu_a_o/2][15:8]};
            //$display("rdbt @%o = %o", cpu_a_o, {8'h0, ~cpu_a_o[0] ? ram1[cpu_a_o/2][7:0] : ram1[cpu_a_o/2][15:8]});
         end
    1'b1:   begin
                case (cpu_a_o) 
                    'o177564:   cpu_d_in <= tx_control;
                    'o177560:   cpu_d_in <= rx_control;
                    default:    cpu_d_in <= ram2[(cpu_a_o-32768)/2];
                endcase
            end
    endcase

always @* begin
    if (cpu_we) begin
        case (cpu_a_o[15])
        1'b0:   begin
                    if (cpu_byte) begin
                        if (cpu_a_o[0] == 0)
                            ram1[cpu_a_o/2][7:0] <= cpu_d_o[7:0];
                        else
                            ram1[cpu_a_o/2][15:8] <= cpu_d_o[7:0];
                    end
                    else begin
                        ram1[cpu_a_o/2] <= cpu_d_o;
                    end
                end
            
        1'b1:   begin
                    if (cpu_a_o == 'o177566) begin
                        if (cpu_d_o[7:0] != 'h0e) $write("%c",cpu_d_o[7:0]);
                    end 
                    else 
                    if (cpu_a_o == 'o177564) begin
                        tx_control <= cpu_d_o;
                        #(STEP*16) tx_control[7] <= 1'b1;
                    end else begin
                        if (cpu_byte) begin
                        end else begin
                            ram2[(cpu_a_o-32768)/2] <= cpu_d_o;
                        end
                    end
                end
        endcase
    end
    
    if (iako & cpu_rd) begin
    #(STEP*8) tx_control[6] <= 0;
    end
    if (cpu_init) begin
        tx_control <= 0;
        rx_control <= 0;
    end
end


always @(posedge m_clock) begin
    // simulate nonexistent address trap for test 791404
    if (cpu_sync && cpu_a_o == 'o172000) begin
        buserr <= 1;
        #(STEP*2)   buserr <= 0;
    end    

    if (cpu_sync && cpu.PC == 'o012000 && cpu_a_o == 'o1 && cpu.OPCODE == 'o105720 && cpu.controlr.state == 8) begin
        buserr <= 1;
        #(STEP*2)   buserr <= 0;
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


vm1 cpu
          (.clk(m_clock), 
           .ce(1),
           .reset_n(mreset_n),
           .data_i(cpu_d_in),
           .data_o(cpu_d_o),
           .addr_o(cpu_a_o),
           .SYNC(cpu_sync),        // o: address set
           .RPLY(cpu_rply),        // i: reply to DIN or DOUT
           .DIN(cpu_rd),         // o: data in flag
           .DOUT(cpu_we),        // o: data out flag
           .WTBT(cpu_byte),        // o: byteio op/odd address
           .BSY(cpu_bsy),         // o: CPU usurps bus
           .INIT(cpu_init),        // o: peripheral INIT
		   .IFETCH(cpu_ifetch),		// o: indicates IF0
		   .VIRQ(txirq),
		   .IAKO(iako),
		   .error_i(buserr)
           );



  // moo
  always @(negedge m_clock) 
    if (disp) begin
    //t0 = top.cpu.cpu.rs232.sender.send_buf&8'h7f;
    //if(t0 == 8'h0d) t0 = 8'h0a;
    //$display("cpu_din:%x cpu_a:%x", cpu_d_in, cpu_a_o);
    $display("pc:%o s/r:%x%x if0:%x %s%s di:%o do:%o a:%o opc:%o s:%d/%b/%s R1-6:%o,%o,%o,%o %o", 
                cpu.PC, cpu_sync, cpu_rply, cpu_ifetch,
                cpu_rd?"R":" ", cpu_we?"W":" ", 
                cpu_d_in, cpu_d_o, cpu_a_o,
                cpu.OPCODE, cpu.controlr.state, 
                cpu.psw[3:0],
                cpu.psw[4] ? "t":"_",
                cpu.dp.R[1], cpu.dp.R[2], cpu.dp.R[3],
                cpu.dp.R[4], cpu.dp.R[5], cpu.dp.R[6], 
                //top.cpu.dp.psw,
                //ram1[top.cpu.dp.R[6]/2]
                //top.cpu.op_decoded
                );
                    
    if(cpu.controlr.state == cpu.controlr.TRAP_SVC) begin
        $display("TRAP_SVC");
        for (i = 0; i < 32; i = i + 2) begin
            $display("   %o: %o %o", i*2, ram1[i], ram1[i+1]);
        end
        if (cpu.OPCODE == 0) begin
            $display("HALT");
            
            $display("Registers:");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%o ", cpu.dp.R[i]);
            end
            
            $display("\nMemory:");
            for (i = 'o1720; i <= 'o2000; i = i + 8) begin
                $display("%o: %o %o %o %o", i, ram1[i/2], ram1[i/2+1],ram1[i/2+2],ram1[i/2+3]);
            end
            
            $finish;
        end
    end
  end

  always @(negedge m_clock) begin
    if (cpu_ifetch && cpu_rd && cpu_a_o == 'o016742)  $display("  (pass #%d time=%d)", ram1['o406/2], $time);
  end



  initial begin
    $display("BM1 simulation begins");
    disp = 1;
    
    #(STEP*80000) begin
        $display("\nend by step limit @#177776=%o", ram2[16383]);
        $finish;
    end
  end



endmodule


