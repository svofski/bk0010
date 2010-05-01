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
                dpcmd2,
                ierror, 
                ready, 
                dati,
                dato,
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
output  reg[127:0]  dpcmd;
output     [127:0]  dpcmd2;
input               ierror, ready;
input               dp_taken;
input     [15:0]    dp_opcode;
input      [3:0]    dp_alucc;
input     [15:0]    psw;
output              ifetch;
input               irq_in;
output reg          iako;
input[`IDC_NOPS:0]  idcop;
output reg          dati, dato;
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

reg [5:0] state;

parameter SRC_OP = 1'b0,
          DST_OP = 1'b1;
reg opsrcdst;

wire [1:0]   MODE = dp_opcode[5:4];
wire         INDR = dp_opcode[3];
wire         SPPC = dp_opcode[2] & dp_opcode[1];
wire     AUTO_INC = dp_opcode[4];
wire     AUTO_DEC = dp_opcode[5];
wire         BYTE = dp_opcode[15];
wire        TRACE = psw[4]; 

`define dp(x) dpcmd[x] = 1'b1

`define dp1(a)      dpcmd = 1<<a
`define dp2(a,b)    dpcmd = (1<<a)|(1<<b)
`define dp3(a,b,c)  dpcmd = (1<<a)|(1<<b)|(1<<c)
`define dp4(a,b,c,d)dpcmd = `dp3(a,b,c)|(1<<d)
`define dp5(a,b,c,d,e) dpcmd = `dp4(a,b,c,d)|(1<<e)

reg        rsub;

assign ifetch = state == FS_IF0;

//------------------------------------------------------------------------------------------

// fetch task
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= BOOT_0;
        opsrcdst <= SRC_OP;
    end
    else if (ce) begin
        $display("state=%d %b", state, dpcmd);
        case (state)
        BOOT_0: begin
                    state <= FS_IF0;
                    $display("state set to IF0");
                end
        FS_IF0: begin 
                    if (~TRACE & irq_in)    
                        state <= TRAP_IRQ;
                    else                                        // breakpoint if T, but not 
                    if (TRACE & ~idcop[`drtt]) begin            // if the last instruction was RTT
                        state <= TRAP_SVC;    
                    end 
                    else begin
                        $display("SWSTATE dati=%d ready=%d", dati, ready);

                        if (ierror) begin
                            state <= TRAP_SVC;
                        end else if (dati & ready) begin
                            // accept data (opcode)
                            state <= FS_ID0;
                        end  
                    end
            		
                end
        FS_IF1: begin
                    state <= FS_ID0;
                end
                
                // Instruction Decode #0
        FS_ID0:    begin
                    if (idc_unused) begin
                        state <= TRAP_SVC;
                    end else if (idc_rsd) begin
                        opsrcdst <= DST_OP;
                        state <= FS_OF0;
                    end else if (idc_nof) begin
                        state <= EX_0;
                    end else if (idc_cco) begin
                        state <= FS_CC0;
                    end else if (idc_bra) begin
                        state <= FS_BR0;
                    end else if (idc_sop) begin
                        opsrcdst <= SRC_OP;
                        state <= FS_OF1;
                    end else if (idc_dop) begin
                        opsrcdst <= DST_OP;
                        state <= FS_OF1;
                    end
                end
                
                // direct register read (5)
        FS_OF0: begin
                    state <= FS_OF1;
                end
                
                // Operand Fetch #1 (6)
        FS_OF1: begin
                    case (MODE) 
                    2'b 00: begin
                            if (INDR) state <= FS_OF4;
                            else if (opsrcdst == DST_OP) begin 
                                state <= EX_0;
                            end 
                            else if (opsrcdst == SRC_OP) begin
                                state <= FS_OF1; // fetch other operand
                            end
                            end
                            
                    2'b 01: begin
                            state <= FS_OF3;
                            end
                            
                    2'b 10: begin
                            state <= FS_OF3;
                            end
                            
                    2'b 11: begin
                            if (ierror) begin
                                state <= TRAP_SVC;        
                            end else if (dati & ready) begin
                                state <= FS_OF2;
                            end
                            end
                    endcase
                end
                
                // Computes effective address in index mode (7)
        FS_OF2: begin 
                state <= FS_OF3;
                end
                
                // First step memory read. Used by Auto-inc,dec,index mode. (8)
        FS_OF3: begin
                if (ierror) begin
                    state <= TRAP_SVC;
                end else if (dati & ready) begin
                    if (INDR) 
                        state <= FS_OF4;
                    else if (opsrcdst == DST_OP) begin
                        state <= EX_0;
                    end else begin
                        opsrcdst <= DST_OP;
                        state <= FS_OF1;
                    end
                end
                end
                
                // Deferred instruction
        FS_OF4: begin
                if (opsrcdst == DST_OP) begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end 
                    else if (dati & ready) begin
                        state <= EX_0;
                    end
                end else begin        // SRC
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end
                    else if (dati & ready) begin
                        opsrcdst <= DST_OP;
                        state <= FS_OF1;
                    end 
                end
                
                end
        
        FS_CC0: begin
                    state <= FS_IF0;
                    if (~TRACE & irq_in) 
                        state <= TRAP_IRQ;
                    if (TRACE)  
                        state <= TRAP_SVC;
                end
                
        FS_BR0:    begin
                    state <= FS_IF0;
                    if (~TRACE & irq_in) 
                        state <= TRAP_IRQ;
                    if (TRACE) 
                        state <= TRAP_SVC; 
                end
        // ifetch states end here
        
        // execution states
                
        EX_0,EX_1,EX_2,EX_3,EX_4,EX_5,EX_6,EX_7,EX_8:     
                begin
                    // set datapath to execute decoded instruction
                    case (1'b 1) // synopsys parallel_case
                    idcop[`dclr]: begin state <= WB_0; end
                    idcop[`dcom]: begin state <= WB_0; end
                    idcop[`dinc]: begin state <= WB_0; end
                    idcop[`ddec]: begin state <= WB_0; end
                    idcop[`dneg]: begin state <= WB_0; end
                    idcop[`dadc]: begin state <= WB_0; end
                    idcop[`dsbc]: begin state <= WB_0; end
                    idcop[`dtst]: begin state <= FS_IF0; end
                    idcop[`dror]: begin state <= WB_0; end
                    idcop[`drol]: begin state <= WB_0; end
                    idcop[`dasr]: begin state <= WB_0; end
                    idcop[`dasl]: begin state <= WB_0; end
                    idcop[`dsxt]: begin state <= WB_0; end
                    
                    idcop[`dmov]: begin state <= WB_0; end
                    
                    idcop[`dcmp]: begin state <= FS_IF0; end
                    idcop[`dbit]: begin state <= FS_IF0; end
                    idcop[`dbic]: begin state <= WB_0; end
                    idcop[`dbis]: begin state <= WB_0; end
                    idcop[`dadd]: begin state <= WB_0; end
                    idcop[`dexor]:begin state <= WB_0; end
                    idcop[`dswab]:begin state <= WB_0; end

                    idcop[`dnop]: begin state <= FS_IF0; end
                    idcop[`djmp]: begin 
                                      if (MODE == 2'b00 && ~INDR) begin
                                          // can't  jump to a register
                                          state <= TRAP_SVC;
                                      end else begin
                                          state <= FS_IF0; 
                                      end
                                  end

                    idcop[`dbpt]: begin state <= TRAP_SVC; end
                    idcop[`diot]: begin state <= TRAP_SVC; end
                    idcop[`demt]: begin state <= TRAP_SVC; end
                    idcop[`dtrap]:begin state <= TRAP_SVC; end

                    idcop[`dspl]: begin state <= FS_IF0; end
                    
                    idcop[`dreset]: begin state <= FS_IF0; end

                    idcop[`dhalt]: begin state <= TRAP_SVC; end // this will trap to 4 in VM1 (originally `dp(`HALT))

                    idcop[`diwait]: if (irq_in) state <= FS_IF0; 
                                
                    
                    idcop[`dsob]: begin
                                    case (state) // synopsys parallel_case
                                    EX_0: begin
                                            state <= EX_1;
                                          end
                                    EX_1: begin
                                            state <= FS_IF0;
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
                                                state <= TRAP_SVC;
                                            end else begin
                                                state <= EX_1;
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                state <= TRAP_SVC;
                                            end 
                                            else if (ready & dato) begin
                                                state <= EX_2;
                                            end
                                          end
                                    EX_2: begin
                                              state <= FS_IF0; 
                                          end
                                    endcase
                                  end
                                
                    idcop[`drts]: begin
                                    case (state)
                                    EX_0: begin
                                            state <= EX_1;
                                          end
                                    
                                    EX_1: begin
                                            if (ierror) begin
                                                state <= TRAP_SVC;
                                            end 
                                            else if (dati & ready) begin
                                                state <= FS_IF0;
                                            end 
                                          end
                                    endcase
                                  end
                                
                    idcop[`drtt],            
                    idcop[`drti]: begin
                                    case (state)
                                    EX_0: begin
                                            if (ierror) begin
                                                state <= TRAP_SVC;
                                            end
                                            else if (dati & ready) begin
                                                state <= EX_1;
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                state <= TRAP_SVC;
                                            end
                                            else if (dati & ready) begin
                                                state <= FS_IF0;
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`dmark]:begin
                                    // gruuu..
                                    case (state)
                                    EX_0: begin
                                            state <= EX_1;
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                state <= TRAP_SVC;
                                            end 
                                            else if (dati & ready) begin
                                                state <= FS_IF0;
                                            end
                                          end
                                    endcase
                                  end
                    idcop[`dmtps]:begin // PSW <- ss
                                  state <= FS_IF0;
                                  end
                    idcop[`dmfps]:begin // dd <- PSW, set flags
                                  state <= WB_0;
                                  end

                    //default:      begin
                    //              `dp(`ERR);
                    //              state <= TRAP_SVC;
                    //              end
                    endcase // idcop
                end // EX_*
                
        WB_0:     begin
                    //state <= FS_IF0;
                    
                    if (dp_opcode[5:3] != 0) begin
                        if (ierror) begin
                            state <= TRAP_SVC;
                        end
                        else if (ready & dato) begin
                            if (TRACE) begin
                                state <= TRAP_SVC;
                            end 
                            else if (irq_in) 
                                state <= TRAP_IRQ;
                            else
                                state <= FS_IF0;
                        end 
                    end 
                    else begin
                        if (TRACE) begin
                            state <= TRAP_SVC;
                        end 
                        else if (irq_in) 
                            state <= TRAP_IRQ;
                        else
                            state <= FS_IF0;                        
                    end
                    
                end
        
            // it's a trap!
        TRAP_IRQ: begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end else if (dati & ready) begin
                        state <= TRAP_1;
                    end
                  end
        
        TRAP_SVC: begin
                    state <= TRAP_1;
                  end
                
        TRAP_1:    begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                        // becoming an hero.
                        // here LSI-11 is supposed to:
                        // - if this is IRQ or any trap but bus error => trap to 4
                        // - if this is trap 4 => die to console mode
                        // not sure what VM1 is supposed to do here
                    end else if (dati & ready) begin
                        state <= TRAP_2;
                    end
                end
                
        TRAP_2: begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end else if (dati & ready) begin
                        state <= TRAP_3;
                    end
                end
                
        TRAP_3:    begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end else if (ready & dato) begin
                        state <= TRAP_4;
                    end 
                end
        TRAP_4: begin
                    if (ierror) begin
                        state <= TRAP_SVC;
                    end else if (ready & dato) begin
                        state <= FS_IF0;
                    end 
                end
        endcase // state
    end 
end

always @(reset_n or state) begin
    if (!reset_n) begin
        {dati,dato,iako,initq,mbyte} <= 0;
        dpcmd = 128'b0;
        //`dp(`SETPCROM);
    end
    else begin
        {dati,dato} <= 0; //-- this makes dati, dato a latch..
        dpcmd = 128'b0; 
        initq <= 1'b0;
        iako <= 1'b0;
        mbyte <= 0;

        case (state) 
        BOOT_0:     begin
                        //`dp(`SETPCROM);
                        `dp(`SETPCROM);
                        $display("SETPCROM");
                    end 
        FS_IF0:    begin 
                    //$display("IF0 dati=%d ready=%d ce=%d clk=%d", dati, ready, ce, clk);
                    if (TRACE & ~idcop[`drtt]) begin            // if the last instruction was RTT
                        `dp(`BPT);        
                    end 
                    else begin
                        if (ierror) begin
                            `dp(`BUSERR);
                        end else if (dati & ready) begin
                            // accept data (opcode)
                            
                            //`dp4(`PCALU1,`INC2,`ALUPC,`SETOPC);
                           
                            `dp(`PCALU1);
                            `dp(`INC2);
                            `dp(`ALUPC);
                            `dp(`SETOPC);
                            
                            dati <= 1'b1;
                        end  else begin
                            // initiate instruction fetch
                            mbyte <= 0;
                            dati <= 1'b1;
                            `dp(`DBAPC);
                        end
                    end
                end
                
                // Instruction Decode #0
        FS_ID0:    begin
                    if (idc_unused) begin
                        `dp(`ERR);
                    end else if (idc_rsd) begin
                        `dp(`CHANGE_OPR);
                    end else if (idc_nof) begin
                    end else if (idc_cco) begin
                    end else if (idc_bra) begin
                        `dp(`CCTAKEN); // latch condition 
                    end else if (idc_sop) begin
                        `dp(`CHANGE_OPR);
                    end else if (idc_dop) begin
                    end
                    
                    if (idcop[`dadd]) begin
                        rsub <= 1'b0;
                    end 
                    else if (idcop[`dsub]) begin
                        rsub <= 1'b1; `dp(`RESET_BYTE);
                    end
                end
                
                // direct register read (5)
        FS_OF0:    begin
                    `dp(`REGSEL);
                    `dp(`SELSRC);
                    `dp(`CHANGE_OPR);
                end
                
                // Operand Fetch #1 (6)
        FS_OF1: begin
                    case (MODE) 
                    2'b 00: begin
                            `dp(opsrcdst == SRC_OP ? `SELSRC : `SELDST);
                            `dp(`REGSEL);
                            
                            if (opsrcdst == SRC_OP) begin
                                `dp(`CHANGE_OPR);
                            end
                            end
                            
                    2'b 01:    begin
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`INC);
                            if (~BYTE | (INDR|SPPC)) `dp(`INC2);
                            `dp(opsrcdst == SRC_OP ? `SELSRC : `SELDST);
                            end
                            
                    2'b 10: begin
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`DEC);
                            if (~BYTE | (INDR|SPPC)) `dp(`DEC2);
                            `dp(opsrcdst == SRC_OP ? `ALUSRC : `ALUDST);
                            end
                            
                    2'b 11: begin
                            if (ierror) begin
                                `dp(`BUSERR);
                            end else if (dati & ready) begin
                                `dp(`PCALU1);    `dp(`INC2); `dp(`ALUPC);
                                `dp(opsrcdst == SRC_OP ? `DBISRC : `DBIDST);
                            end else begin
                                //`dp(`DBAPC);
                                dati <= 1'b1;
                                mbyte <= 0;
                            end
                            
                            end
                    endcase
                end
                
                // Computes effective address in index mode (7)
        FS_OF2: begin 
                `dp(`REGSEL); `dp(`SELALU1); `dp(`ADD);
                if (opsrcdst == SRC_OP) begin 
                    `dp(`SRCALU2); `dp(`ALUSRC);
                end
                if (opsrcdst == DST_OP) begin
                    `dp(`DSTALU2); `dp(`ALUDST);
                end
                end
                
                // First step memory read. Used by Auto-inc,dec,index mode. (8)
        FS_OF3: begin
                if (ierror) begin
                    `dp(`BUSERR);
                end else if (dati & ready) begin
                    if (opsrcdst == DST_OP) begin
                        `dp(`DBIDST); `dp(`DSTADR);
                    end else begin
                        `dp(`DBISRC); `dp(`SRCADR);
                    end
                    
                    if (INDR) begin
                    end    
                    else if (opsrcdst == DST_OP) begin
                    end else begin
                        `dp(`CHANGE_OPR);
                    end
                end else begin
                    // initiate memory read
                    mbyte <= INDR ? 1'b0 : BYTE;
                    dati <= 1'b1;
                    `dp(opsrcdst == SRC_OP ? `DBASRC : `DBADST);
                end
                
                end
                
                // Deferred instruction
        FS_OF4: begin
                if (opsrcdst == DST_OP) begin
                    if (ierror) begin
                        `dp(`BUSERR);
                    end 
                    else if (dati & ready) begin
                        `dp(`DSTADR); `dp(`DBIDST);
                    end else begin
                        // initiate memory read
                        mbyte <= BYTE;
                        dati <= 1'b1;
                        `dp(`DBADST); 
                    end
                end else begin        // SRC
                    if (ierror) begin
                        `dp(`BUSERR);
                    end
                    else if (dati & ready) begin
                        `dp(`SRCADR); `dp(`DBISRC);
                        `dp(`CHANGE_OPR);
                    end else begin
                        mbyte <= BYTE;
                        `dp(`DBASRC);
                        dati <= 1'b1;
                    end
                end
                
                end
        
        FS_CC0: begin
                    `dp(`CCSET);
                end
                
        FS_BR0:    begin
                    //`dp(`CCTAKEN); // latch condition -- see ID0
                    if (dp_taken) begin
                        `dp(`PCALU1); `dp(`OFS8ALU2); 
                        `dp(`ADD); `dp(`ALUPC);
                    end
                end
        // ifetch states end here
        
        // execution states
                
        EX_0,EX_1,EX_2,EX_3,EX_4,EX_5,EX_6,EX_7,EX_8:     
                begin
                    // set datapath to execute decoded instruction
                    case (1'b 1) // synopsys parallel_case
                    idcop[`dclr]: begin `dp(`DSTALU1); `dp(`CLR); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dcom]: begin `dp(`DSTALU1); `dp(`COM); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dinc]: begin `dp(`DSTALU1); `dp(`INC); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`ddec]: begin `dp(`DSTALU1); `dp(`DEC); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dneg]: begin `dp(`DSTALU1); `dp(`NEG); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dadc]: begin `dp(`DSTALU1); `dp(`ADC); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dsbc]: begin `dp(`DSTALU1); `dp(`SBC); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dtst]: begin `dp(`DSTALU1); `dp(`TST); `dp(`ALUCC);  end
                    idcop[`dror]: begin `dp(`DSTALU1); `dp(`ROR); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`drol]: begin `dp(`DSTALU1); `dp(`ROL); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dasr]: begin `dp(`DSTALU1); `dp(`ASR); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dasl]: begin `dp(`DSTALU1); `dp(`ASL); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dsxt]: begin `dp(`DSTALU1); `dp(`SXT); `dp(`ALUDSTB); `dp(`ALUCC); end
                    
                    idcop[`dmov]: begin `dp(`SRCALU1); `dp(`MOV);     `dp(`ALUDST); `dp(`ALUCC); end
                    
                    idcop[`dcmp]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`CMP);    `dp(`ALUCC); end
                    idcop[`dbit]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIT);    `dp(`ALUCC); end
                    idcop[`dbic]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIC);    `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dbis]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIS);    `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dadd]: 
                                if (!rsub) begin
                                    `dp(`SRCALU1); `dp(`DSTALU2); `dp(`ADD); `dp(`ALUDSTB); `dp(`ALUCC);  
                                end else begin
                                    `dp(`SRCALU2); `dp(`DSTALU1); `dp(`SUB); `dp(`ALUDSTB); `dp(`ALUCC);  
                                end
                    idcop[`dexor]:begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`EXOR); `dp(`ALUDSTB); `dp(`ALUCC); end
                    idcop[`dswab]:begin `dp(`DSTALU1); `dp(`SWAB); `dp(`ALUDSTB); `dp(`ALUCC);  end

                    idcop[`dnop]: begin  end
                    idcop[`djmp]: begin 
                                      if (MODE == 2'b00 && ~INDR) begin
                                          // can't  jump to a register
                                          `dp(`BUSERR);
                                      end else begin
                                          `dp(`ADRPC); 
                                      end
                                  end

                    idcop[`dbpt]: begin `dp(`BPT); end
                    idcop[`diot]: begin `dp(`IOT); end
                    idcop[`demt]: begin `dp(`EMT); end
                    idcop[`dtrap]:begin `dp(`SVC); end

                    idcop[`dspl]: begin `dp(`SPL); end
                    
                    idcop[`dreset]: begin initq <= 1'b1; end

                    idcop[`dhalt]: begin `dp(`BUSERR); end // this will trap to 4 in VM1 (originally `dp(`HALT))

                    idcop[`diwait]: if (irq_in) begin end 
                                
                    
                    idcop[`dsob]: begin
                                    case (state) // synopsys parallel_case
                                    EX_0: begin
                                            `dp(`REGSEL2); `dp(`SELALU1); `dp(`DEC); `dp(`ALUREG); `dp(`SETREG2);
                                            `dp(`CCGET);
                                          end
                                    EX_1: begin
                                            if (~dp_alucc[2]) begin
                                                `dp(`PCALU1); `dp(`OFS6ALU2); `dp(`SUB); `dp(`ALUPC);
                                            end
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
                                            end else begin
                                                `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                            end 
                                            else if (ready & dato) begin
                                                `dp(`PCREG); `dp(`SETREG2);
                                            end else begin
                                                mbyte <= 1'b0;
                                                dato <= 1'b1;
                                                `dp(`REGSEL2); `dp(`DBOSEL); `dp(`DBASP);
                                            end
                                          end
                                    EX_2: begin
                                              `dp(`ADRPC); 
                                          end
                                    endcase
                                  end
                                
                    idcop[`drts]: begin
                                    case (state)
                                    EX_0: begin
                                            `dp(`REGSEL); `dp(`SELPC);
                                          end
                                    
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                            end 
                                            else if (dati & ready) begin
                                                `dp(`DBIREG); `dp(`SETREG);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                            end else begin
                                                mbyte <= 1'b0;
                                                dati <= 1'b1;
                                                `dp(`DBASP);
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`drtt],            
                    idcop[`drti]: begin
                                    case (state)
                                    EX_0: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                            end
                                            else if (dati & ready) begin
                                                `dp(`DBIPC);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                            end else begin
                                                mbyte <= 1'b0;
                                                dati <= 1'b1;
                                                `dp(`DBASP);
                                            end
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                            end
                                            else if (dati & ready) begin
                                                `dp(`DBIPS);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                            end else begin
                                                mbyte <= 1'b0;
                                                dati <= 1'b1;
                                                `dp(`DBASP);
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`dmark]:begin
                                    // gruuu..
                                    case (state)
                                    EX_0: begin
                                            // SP <= PC + 2x(arg)
                                            `dp(`PCALU1); `dp(`OFS6ALU2); 
                                            `dp(`ADD); `dp(`ALUSP);
                                            `dp(`FPPC);
                                          end
                                    EX_1: begin
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                            end 
                                            else if (dati & ready) begin
                                                `dp(`DBIFP);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                            end else begin
                                                mbyte <= 1'b0;
                                                dati <= 1'b1;
                                                `dp(`DBASP);
                                            end
                                          end
                                    endcase
                                  end
                    idcop[`dmtps]:begin // PSW <- ss
                                  `dp(`DSTPSW);
                                  end
                    idcop[`dmfps]:begin // dd <- PSW, set flags
                                  `dp(`PSWALU1);
                                  `dp(`ALUDST); 
                                  `dp(`MOV); 
                                  `dp(`ALUCC);
                                  end

                    //default:      begin
                    //              `dp(`ERR);
                    //              state <= TRAP_SVC;
                    //              end
                    endcase // idcop
                end // EX_*
                
        WB_0:     begin
                    //state <= FS_IF0;
                    if (dp_opcode[5:3] != 0) begin
                        if (ierror) begin
                            `dp(`BUSERR);
                        end
                        else if (ready & dato) begin
                            if (TRACE) begin
                                `dp(`BPT);
                            end 
                        end else begin
                            dato <= 1'b1;
                            mbyte <= BYTE;
                            `dp(`DBODST); `dp(`DBAADR);
                        end
                    end 
                    else begin
                        `dp(`DSTREG); `dp(`SETREG);
                        if (TRACE) begin
                            `dp(`BPT); 
                        end 
                    end
                    
                end
        
            // it's a trap!
        TRAP_IRQ: begin
                    iako <= 1'b1; 
                    if (ierror) begin
                        `dp(`BUSERR);
                    end else if (dati & ready) begin
                        `dp(`DBISRC);            // read interrupt vector from dbi
                    end else begin
                        mbyte <= 1'b0;
                        dati <= 1'b1;
                        iako <= 1'b1;
                        `dp(`RESET_BYTE); 
                        `dp(`SAVE_STAT);
                    end
                  end
        
        TRAP_SVC: begin
                    `dp(`RESET_BYTE); 
                    `dp(`SAVE_STAT);
                  end
                
        TRAP_1:    begin
                    if (ierror) begin
                        `dp(`BUSERR);
                        // becoming an hero.
                        // here LSI-11 is supposed to:
                        // - if this is IRQ or any trap but bus error => trap to 4
                        // - if this is trap 4 => die to console mode
                        // not sure what VM1 is supposed to do here
                    end else if (dati & ready) begin
                        `dp(`DBIPC);
                        `dp(`SRCALU1); `dp(`INC2); `dp(`ALUSRC);
                    end else begin
                        mbyte <= 1'b0;
                        dati <= 1'b1;
                        `dp(`DBASRC);    // trap vector
                    end
                end
                
        TRAP_2: begin
                    if (ierror) begin
                        `dp(`BUSERR);
                    end else if (dati & ready) begin
                        `dp(`VECTORPS);
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                    end else begin
                        mbyte <= 1'b0;
                        dati <= 1'b1;
                        `dp(`DBASRC);     // vector+2/priority
                    end
                end
                
        TRAP_3:    begin
                    if (ierror) begin
                        `dp(`BUSERR);
                    end else if (ready & dato) begin
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                    end else begin
                        `dp(`DBODST); `dp(`DBASP);
                        mbyte <= 1'b0;// Mr.Iida has BYTE here
                        dato <= 1'b1;
                    end
                end
        TRAP_4: begin
                    if (ierror) begin
                        `dp(`BUSERR);
                    end else if (ready & dato) begin
                    end else begin
                        `dp(`DBOADR); `dp(`DBASP);
                        dato <= 1'b1;
                    end
                end
        endcase // state
    end
end







endmodule

