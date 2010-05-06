// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008 Viacheslav Slavinsky
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 Control Chip
// --------------------------------------------------------

`default_nettype none
`include "instr.h"
`include "opc.h"

module     control11(clk, 
                ce, 
                reset_n, 
                dpcmd, 
                ierror, 
                ready_i, 
                dati_o,
                dato_o,
                mbyte, 
                dp_opcode,
                dp_taken,
                dp_alucc,
                psw,    
                ifetch,            
                irq_in,
                iako,
                idcop,
                idc_cco, 
                idc_bra, 
                idc_nof, 
                idc_rsd, 
                idc_dop, 
                idc_sop, 
                idc_unused,
                initq, 
                test);
                
input               clk;
input               ce;
input               reset_n;
output reg [127:0]  dpcmd;
input               ierror;
input               ready_i;
input               dp_taken;
input     [15:0]    dp_opcode;
input      [3:0]    dp_alucc;
input     [15:0]    psw;
output reg          ifetch;
input               irq_in;
output reg          iako;
input[`IDC_NOPS:0]  idcop;
output reg          dati_o, dato_o;
output reg          mbyte;
input               idc_cco, idc_bra, idc_nof, idc_rsd, idc_dop, idc_sop, idc_unused;
output reg          initq;

output        [7:0]    test;

assign test = state;

parameter [5:0]    BOOT_0 = 0,
                FS_IF0 = 1,
                FS_IF1 = 2,
                FS_ID0 = 3,
                FS_ID1 = 4,
                FS_OF0 = 5,
                FS_OF1 = 6,
                FS_OF2 = 7,
                FS_OF3 = 8,
                FS_OF4 = 9,
                FS_BR0 = 10,
                FS_CC0 = 11,
        
                EX_0 = 16,
                EX_1 = 17,
                EX_2 = 18,
                EX_3 = 19,
                EX_4 = 20,
                EX_5 = 21,
                EX_6 = 22,
                EX_7 = 23,
                EX_8 = 24,
                
                WB_0 = 32,

                TRAP_1 = 49,
                TRAP_2 = 50,
                TRAP_3 = 51,
                TRAP_4 = 52,
                TRAP_IRQ = 55,
                TRAP_SVC = 56;

reg [5:0] state, next;

parameter SRC_OP = 1'b0,
          DST_OP = 1'b1;

reg opsrcdst_to,    // comb
    opsrcdst_r;     // clocked reg

wire [1:0]   MODE = dp_opcode[5:4];
wire         INDR = dp_opcode[3];
wire         SPPC = dp_opcode[2] & dp_opcode[1];
wire     AUTO_INC = dp_opcode[4];
wire     AUTO_DEC = dp_opcode[5];
wire         BYTE = dp_opcode[15];
wire        TRACE = psw[4]; 

`define dp(x) dpcmd[x] = 1'b1

reg        rsub;

// stretched ready

reg         ready_r;
always @(posedge clk or negedge reset_n)
    if (!reset_n) 
        ready_r <= 0;
    else begin
        ready_r <= ready_i ? ready_i : ce ? ready_i : ready_r;
    end
reg         ready;
always @*
        ready = ready_r | ready_i;
//wire        ready = /*ready_r | */ready_i;    

reg         dati, dato;

reg        dati_r;
reg        dato_r;

reg        dati_of4_r;
reg        dati_of4;
wire       di_ready_of4 = dati_of4_r & ready;

reg        dati_of1_r;
reg        dati_of1;
wire       di_ready_of1 = dati_of1_r & ready;


wire       di_ready = dati_r & ready;
wire       do_ready = dato_r & ready;


always @* begin
    dato_o = dato;
    dati_o = dati | dati_of1 | dati_of4;
end

// async reset is necessary 
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= BOOT_0;
        {dati_r,dati_of1_r,dati_of4_r} <= 0;
        dato_r <= 0;
    end
    else if (ce) begin
        //$display("^state=%d->%d ce=%b", state, next, ce);
        state <= next;
        dati_r <= dati;
        dati_of1_r <= dati_of1;
        dati_of4_r <= dati_of4;
        dato_r <= dato;
        opsrcdst_r <= opsrcdst_to;
    end
end

// synthesis translate_off
initial begin
    //$monitor("Mce=%d", ce);
    //$monitor("Mnext=%d", next);
end

//always @(negedge clk) 
    //$display("_state=%d", state);
// synthesis translate_on 

always @* begin
    begin
        {dati,dato} = 0;
        dati_of1 = 0;
        dati_of4 = 0;
        dpcmd = 128'b0;
        initq = 1'b0;
        iako = 1'b0;
        ifetch = 1'b0;
        
        opsrcdst_to = opsrcdst_r; // don't allow opsrcdst to latch
        
        next = !reset_n ? BOOT_0 : state;
        
        case (state)
        //default:next = state;
        
        BOOT_0: begin
                    `dp(`SETPCROM);
                    next = FS_IF0;
                end
        FS_IF0: begin 
                    if (~TRACE & irq_in)    
                        next = TRAP_IRQ;
                    else                                        // breakpoint if T, but not 
                    if (TRACE & ~idcop[`drtt]) begin            // if the last instruction was RTT
                        `dp(`BPT);    
                        next = TRAP_SVC;    
                    end 
                    else begin
                        `dp(`DBAPC);
                        if (ierror) begin
                            next = TRAP_SVC;
                            `dp(`BUSERR);
                        end else if (di_ready) begin
                            // accept data (opcode)
                            next = FS_ID0;
                            //$display("IF0: ready, state=%d next=%d ce=%d", state, next, ce);
                            `dp(`PCALU1);
                            `dp(`INC2);
                            `dp(`ALUPC);
                            `dp(`SETOPC);
                        end  else begin
                            // initiate instruction fetch
                            mbyte = 0;
                            ifetch = 1'b1;
                            dati = 1'b1;
                        end
                    end
                end
                
                // Instruction Decode (3)
        FS_ID0:    begin
                    
                    if (idc_unused) begin
                        `dp(`ERR);
                        next = TRAP_SVC;
                        //$display("unu!");
                    end else if (idc_rsd) begin
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = DST_OP;
                        next = FS_OF0;
                        //$display("rsd!");
                    end else if (idc_nof) begin
                        next = EX_0;
                        //$display("nof!");
                    end else if (idc_cco) begin
                        next = FS_CC0;
                        //$display("cco!");
                    end else if (idc_bra) begin
                        `dp(`CCTAKEN); // latch condition 
                        next = FS_BR0;
                        //$display("bra!");
                    end else if (idc_sop) begin
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = SRC_OP;
                        next = FS_OF1;
                        //$display("sop!");
                    end else if (idc_dop) begin
                        //$display("dop!");
                        opsrcdst_to = DST_OP;
                        next = FS_OF1;
                    end
                    
                    if (idcop[`dadd]) begin
                        rsub = 1'b0;
                    end 
                    else if (idcop[`dsub]) begin
                        rsub = 1'b1; `dp(`RESET_BYTE);
                    end
                end
                
                // direct register read (5)
        FS_OF0:    begin
                    `dp(`REGSEL);
                    `dp(`SELSRC);
                    `dp(`CHANGE_OPR);
                    
                    next = FS_OF1;
                end
                
                // Operand Fetch #1 (6)
        FS_OF1: begin
                    //$display("FS_OF1: %b opsrcdst_r=%b to %b, ready=%b INDR=%b", MODE, opsrcdst_r, opsrcdst_to, di_ready, INDR);
                    case (MODE) 
                    2'b 00: begin
                            `dp(opsrcdst_r == SRC_OP ? `SELSRC : `SELDST);
                            `dp(`REGSEL); // load DST from selected reg on next clk
                            
                            if (INDR) next = FS_OF4;
                            else if (opsrcdst_r == DST_OP) begin 
                                next = EX_0;
                            end 
                            else if (opsrcdst_r == SRC_OP) begin
                                //$display("FS_OF1: SWITCH to DST_OP");
                                opsrcdst_to = DST_OP;
                                `dp(`CHANGE_OPR);
                                next = FS_OF1; // fetch other operand
                            end
                            end
                            
                    2'b 01: begin
                            // 01(0), 01(1): register autoincrement
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`INC);
                            if (~BYTE | (INDR|SPPC)) `dp(`INC2);
                            `dp(opsrcdst_r == SRC_OP ? `SELSRC : `SELDST);
                            next = FS_OF3;
                            end
                            
                    2'b 10: begin
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`DEC);
                            if (~BYTE | (INDR|SPPC)) `dp(`DEC2);
                            `dp(opsrcdst_r == SRC_OP ? `ALUSRC : `ALUDST);
                            next = FS_OF3;
                            end
                            
                    2'b 11: begin
                            //$display("FS_OF1:11 next=%d", next);
                            `dp(`DBAPC);
                            if (ierror) begin
                                next = TRAP_SVC;        
                                `dp(`BUSERR);
                            end else if (di_ready_of1) begin
                                `dp(`PCALU1); `dp(`INC2); `dp(`ALUPC);
                                `dp(opsrcdst_r == SRC_OP ? `DBISRC : `DBIDST);
                                //dati = 1'b1;
                                next = FS_OF2;
                            end else begin
                                //`dp(opsrcdst_r == SRC_OP ? `DBISRC : `DBIDST);
                                dati_of1 = 1'b1;
                                mbyte = 0;
                            end
                            
                            end
                    endcase
                end
                
                // Computes effective address in index mode (7)
        FS_OF2: begin 
                `dp(`REGSEL); `dp(`SELALU1); `dp(`ADD);
                if (opsrcdst_r == SRC_OP) begin 
                    `dp(`SRCALU2); `dp(`ALUSRC);
                end
                if (opsrcdst_r == DST_OP) begin
                    `dp(`DSTALU2); `dp(`ALUDST);
                end
                
                next = FS_OF3;
                end
                
                // First step memory read. Used by Auto-inc,dec,index mode. (8)
        FS_OF3: begin
                //$display("OF3 dati=%d datir=%d di_ready=%d opsrcdst=%b", dati, dati_r, di_ready, opsrcdst_r);
                `dp(opsrcdst_r == SRC_OP ? `DBASRC : `DBADST);
                if (ierror) begin
                    next = TRAP_SVC;
                    `dp(`BUSERR);
                end else if (di_ready) begin
                    if (opsrcdst_r == DST_OP) begin
                        //$display("OF3 end memory read DST");
                        `dp(`DBIDST); // load DST from DBI
                        `dp(`DSTADR); // load ADR from DST
                    end else begin
                        //$display("OF3 end memory read SRC");
                        `dp(`DBISRC); // load SRC from DBI
                        `dp(`SRCADR); // load ADR from SRC
                    end
                    
                    if (INDR) 
                        next = FS_OF4;
                    else if (opsrcdst_r == DST_OP) begin
                        next = EX_0;
                    end else begin
                        `dp(`CHANGE_OPR);
                        //$display("FS_OF3: SWITCH to DST_OP -> FS_OF1");
                        opsrcdst_to = DST_OP;
                        next = FS_OF1;
                    end
                    //dati = 1'b1;
                end else begin
                    // initiate memory read
                    mbyte = INDR ? 1'b0 : BYTE;
                    dati = 1'b1;
                    //$display("OF3 initiate memory read %b", opsrcdst_r);
                    //`dp(opsrcdst_r == SRC_OP ? `DBASRC : `DBADST);
                end
                
                end
                
                // Deferred instruction (9)
        FS_OF4: begin
                if (opsrcdst_r == DST_OP) begin
                    `dp(`DBADST);
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end 
                    else if (di_ready_of4) begin
                        `dp(`DSTADR);   // ADR <= DST @clk save loaded data into ADR
                        `dp(`DBIDST);   // DST <= DBI @ clk input data to DST
                        //dati = 1'b1;
                        next = EX_0;
                    end else begin
                        // initiate memory read
                        mbyte = BYTE;
                        dati_of4 = 1'b1;
                    end
                end else begin        // SRC
                    `dp(`DBASRC);
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end
                    else if (di_ready_of4) begin
                        `dp(`SRCADR); //`dp(`DBISRC);
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = DST_OP;
                        //dati = 1'b1;
                        //$display("FS_OF4: SWITCH to DST_OP -> FS_OF1");
                        next = FS_OF1;
                    end else begin
                        mbyte = BYTE;
                        //`dp(`DBASRC);
                        `dp(`DBISRC);
                        dati_of4 = 1'b1;
                    end
                end
                
                end
        
        FS_CC0:    begin
                    `dp(`CCSET);
                    
                    next = FS_IF0;
                    if (~TRACE & irq_in) next = TRAP_IRQ;
                    if (TRACE) begin `dp(`BPT);    next = TRAP_SVC; end
                end
                
        FS_BR0:    begin
                    //`dp(`CCTAKEN); // latch condition -- see ID0
                    if (dp_taken) begin
                        `dp(`PCALU1); `dp(`OFS8ALU2); 
                        `dp(`ADD); `dp(`ALUPC);
                    end
                    
                    next = FS_IF0;
                    if (~TRACE & irq_in) next = TRAP_IRQ;
                    if (TRACE) begin `dp(`BPT);    next = TRAP_SVC; end
                end
        // ifetch states end here
        
        // execution states
                
        EX_0,EX_1,EX_2,EX_3,EX_4,EX_5,EX_6,EX_7,EX_8:     
                begin
                    // set datapath to execute decoded instruction
                    case (1'b 1) // synopsys parallel_case
                    idcop[`dclr]: begin `dp(`DSTALU1); `dp(`CLR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dcom]: begin `dp(`DSTALU1); `dp(`COM); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dinc]: begin `dp(`DSTALU1); `dp(`INC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`ddec]: begin `dp(`DSTALU1); `dp(`DEC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dneg]: begin `dp(`DSTALU1); `dp(`NEG); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dadc]: begin `dp(`DSTALU1); `dp(`ADC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dsbc]: begin `dp(`DSTALU1); `dp(`SBC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dtst]: begin `dp(`DSTALU1); `dp(`TST); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dror]: begin `dp(`DSTALU1); `dp(`ROR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`drol]: begin `dp(`DSTALU1); `dp(`ROL); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dasr]: begin `dp(`DSTALU1); `dp(`ASR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dasl]: begin `dp(`DSTALU1); `dp(`ASL); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dsxt]: begin `dp(`DSTALU1); `dp(`SXT); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    
                    idcop[`dmov]: begin `dp(`SRCALU1); `dp(`MOV); `dp(`ALUDST);  `dp(`ALUCC); next = WB_0; end
                    
                    idcop[`dcmp]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`CMP); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dbit]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIT); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dbic]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dbis]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIS); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dadd]: 
                                if (!rsub) begin
                                    `dp(`SRCALU1); `dp(`DSTALU2); `dp(`ADD); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; 
                                end else begin
                                    `dp(`SRCALU2); `dp(`DSTALU1); `dp(`SUB); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; 
                                end
                    idcop[`dexor]:begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`EXOR);    `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dswab]:begin `dp(`DSTALU1); `dp(`SWAB);    `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end

                    idcop[`dnop]: begin next = FS_IF0; end
                    idcop[`djmp]: begin 
                                      if (MODE == 2'b00 && ~INDR) begin
                                          // can't  jump to a register
                                          next = TRAP_SVC;
                                          `dp(`BUSERR);
                                      end else begin
                                          `dp(`ADRPC); 
                                          next = FS_IF0; 
                                      end
                                  end

                    idcop[`dbpt]: begin `dp(`BPT); next = TRAP_SVC; end
                    idcop[`diot]: begin `dp(`IOT); next = TRAP_SVC; end
                    idcop[`demt]: begin `dp(`EMT); next = TRAP_SVC; end
                    idcop[`dtrap]:begin `dp(`SVC); next = TRAP_SVC; end

                    idcop[`dspl]: begin `dp(`SPL); next = FS_IF0; end
                    
                    idcop[`dreset]: begin initq = 1'b1; next = FS_IF0; end

                    idcop[`dhalt]: begin `dp(`BUSERR); next = TRAP_SVC; end // this will trap to 4 in VM1 (originally `dp(`HALT))

                    idcop[`diwait]: if (irq_in) next = FS_IF0; 
                                
                    
                    idcop[`dsob]: begin
                                    case (state) // synopsys parallel_case
                                    EX_0: begin
                                            `dp(`REGSEL2); `dp(`SELALU1); `dp(`DEC); `dp(`ALUREG); `dp(`SETREG2);
                                            `dp(`CCGET);
                                            next = EX_1;
                                          end
                                    EX_1: begin
                                            if (~dp_alucc[2]) begin
                                                `dp(`PCALU1); `dp(`OFS6ALU2); `dp(`SUB); `dp(`ALUPC);
                                            end
                                            next = FS_IF0;
                                          end
                                    endcase
                                  end
                                
                    // gruuu...
                    idcop[`djsr]: begin
                                    case (state)
                                    EX_0: begin
                                            if (MODE == 2'b00 && ~INDR) begin
                                                // can't jump to a register
                                                // trap must happen now, before return address is pushed
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end else begin
                                                `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                                                next = EX_1;
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (do_ready) begin
                                                `dp(`PCREG); `dp(`SETREG2);
                                                next = EX_2;
                                            end else begin
                                                mbyte = 1'b0;
                                                dato = 1'b1;
                                                `dp(`REGSEL2); `dp(`DBOSEL); `dp(`DBASP);
                                            end
                                          end
                                    EX_2: begin
                                              `dp(`ADRPC); 
                                              next = FS_IF0; 
                                          end
                                    endcase
                                  end
                                
                    idcop[`drts]: begin
                                    case (state)
                                    EX_0: begin
                                            `dp(`REGSEL); `dp(`SELPC);
                                            next = EX_1;
                                          end
                                    
                                    EX_1: begin
                                            `dp(`DBASP);
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (di_ready) begin
                                                `dp(`DBIREG);   // REGin = DBI (comb)
                                                `dp(`SETREG);   // R[dst] = REGin (clk)
                                                
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                mbyte = 1'b0;
                                                dati = 1'b1;
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`drtt],            
                    idcop[`drti]: begin
                                    `dp(`DBASP);
                                    case (state)
                                    EX_0: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end
                                            else if (di_ready) begin
                                                `dp(`DBIPC);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = EX_1;
                                            end else begin
                                                mbyte = 1'b0;
                                                dati = 1'b1;
                                                //`dp(`DBASP);
                                                //`dp(`DBIPC);
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end
                                            else if (di_ready) begin
                                                `dp(`DBIPS);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                mbyte = 1'b0;
                                                dati = 1'b1;
                                                //`dp(`DBASP);
                                                //`dp(`DBIPS);
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`dmark]:begin
                                    // gruuu..
                                    case (state)
                                    EX_0: begin
                                            // SP = PC + 2x(arg)
                                            `dp(`PCALU1); `dp(`OFS6ALU2); 
                                            `dp(`ADD); `dp(`ALUSP);
                                            `dp(`FPPC);
                                            next = EX_1;
                                          end
                                    EX_1: begin
                                            `dp(`DBASP);
                                            
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (di_ready) begin
                                                `dp(`DBIFP);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                mbyte = 1'b0;
                                                dati = 1'b1;
                                                //`dp(`DBASP);
                                                //`dp(`DBIFP);
                                            end
                                          end
                                    endcase
                                  end
                    idcop[`dmtps]:begin // PSW <- ss
                                  `dp(`DSTPSW);
                                  next = FS_IF0;
                                  end
                    idcop[`dmfps]:begin // dd <- PSW, set flags
                                  `dp(`PSWALU1);
                                  `dp(`ALUDST); 
                                  `dp(`MOV); 
                                  `dp(`ALUCC);
                                  next = WB_0;
                                  end
                    endcase // idcop
                end // EX_*
                
        WB_0:     begin
                    if (dp_opcode[5:3] != 0) begin
                        if (ierror) begin
                            `dp(`BUSERR);
                            next = TRAP_SVC;
                        end
                        else if (do_ready) begin
                            dato = 1'b1;
                            `dp(`DBODST); `dp(`DBAADR);

                            if (TRACE) begin
                                `dp(`BPT); 
                                next = TRAP_SVC;
                            end 
                            else if (irq_in) 
                                next = TRAP_IRQ;
                            else
                                next = FS_IF0;
                        end else begin
                            dato = 1'b1;
                            mbyte = BYTE;
                            `dp(`DBODST); `dp(`DBAADR);
                            //$display("DBODST DBAADR: ADR=%o", dp.ADR);
                        end
                    end 
                    else begin
                        `dp(`DSTREG); `dp(`SETREG);
                        if (TRACE) begin
                            `dp(`BPT); 
                            next = TRAP_SVC;
                        end 
                        else if (irq_in) 
                            next = TRAP_IRQ;
                        else
                            next = FS_IF0;                        
                    end
                    
                end
        
            // it's a trap!
        TRAP_IRQ: begin
                    iako = 1'b1; 
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (di_ready) begin
                        //`dp(`DBISRC);            // read interrupt vector from dbi
                        next = TRAP_1;
                    end else begin
                        mbyte = 1'b0;
                        dati = 1'b1;
                        iako = 1'b1;
                        `dp(`RESET_BYTE); 
                        `dp(`SAVE_STAT);
                        `dp(`DBISRC);
                    end
                  end
        
        TRAP_SVC: begin
                    `dp(`RESET_BYTE); 
                    `dp(`SAVE_STAT);
                    next = TRAP_1;
                  end
                
        TRAP_1:    begin
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                        // becoming an hero.
                        // here LSI-11 is supposed to:
                        // - if this is IRQ or any trap but bus error => trap to 4
                        // - if this is trap 4 => die to console mode
                        // not sure what VM1 is supposed to do here
                    end else if (di_ready) begin
                        //`dp(`DBIPC);
                        `dp(`SRCALU1); `dp(`INC2); `dp(`ALUSRC);
                        next = TRAP_2;
                    end else begin
                        mbyte = 1'b0;
                        dati = 1'b1;
                        `dp(`DBASRC);    // trap vector
                        `dp(`DBIPC);
                    end
                end
                
        TRAP_2: begin
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (di_ready) begin
                        //`dp(`VECTORPS);
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                        next = TRAP_3;
                    end else begin
                        mbyte = 1'b0;
                        dati = 1'b1;
                        `dp(`DBASRC);     // vector+2/priority
                        `dp(`VECTORPS);
                    end
                end
                
        TRAP_3:    begin
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (do_ready) begin
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                        next = TRAP_4;
                    end else begin
                        `dp(`DBODST); `dp(`DBASP);
                        mbyte = 1'b0;// Mr.Iida has BYTE here
                        dato = 1'b1;
                    end
                end
        TRAP_4: begin
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (do_ready) begin
                        next = FS_IF0;
                    end else begin
                        `dp(`DBOADR); `dp(`DBASP);
                        dato = 1'b1;
                    end
                end
        endcase // state
    end
end


endmodule

